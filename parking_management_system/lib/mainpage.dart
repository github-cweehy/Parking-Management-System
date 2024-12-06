import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'packages.dart';
import 'favourite.dart';
import 'history.dart';
import 'packageshistory.dart';
import 'userprofile.dart';
import 'login.dart';
import 'location.dart';
import 'rewards.dart';

class MainPage extends StatefulWidget {
  final String userId;

  MainPage({required this.userId});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? currentUser = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> userPackages = [];
  bool isFavourite = false;

  String username = '';
  List<Map<String, dynamic>> parkingHistory = [];
  Map<String, String> parkingPrice = {};

  @override
  void initState() {
    super.initState();
    fetchUsername();
    fetchParkingHistory();
    fetchParkingPrices();
    fetchPackages();
  }

  Future<void> fetchUsername() async {
    try {
      final userDoc = await _firestore.collection('users').doc(widget.userId).get();
      setState(() {
        username = userDoc.data()?['username'] ?? 'Username';
      });
    } catch (e) {
      print("Error fetching username: $e");
    }
  }

  Future<void> fetchParkingHistory() async {
    try {
      final querySnapshot = await _firestore
          .collection('history parking')
          .where('userID', isEqualTo: widget.userId)
          .get();

      final List<Map<String, dynamic>> fetchedHistory = [];

      for (var doc in querySnapshot.docs) {
        final parkingData = doc.data() as Map<String, dynamic>;

        // Parse and validate endTime
        dynamic endTime = parkingData['endTime'];
        if (endTime is String) {
          // Parse string to DateTime
          try {
            endTime = Timestamp.fromDate(DateTime.parse(endTime));
          } catch (e) {
            print("Error parsing endTime for document ${doc.id}: $e");
            continue; // Skip this document
          }
        }

        Timestamp? endTimestamp = endTime is Timestamp ? endTime : null;

        // Filter out expired entries
        if (endTimestamp == null || endTimestamp.toDate().isBefore(DateTime.now())) {
          print("Skipping expired parking ID: ${doc.id}");
          continue; // Skip expired parking
        }

        final favDoc = await _firestore.collection('favourite').doc(doc.id).get();

        fetchedHistory.add({
          'id': doc.id,
          ...parkingData,
          'isFavourite': favDoc.exists, // Check if the parking is in favourites
        });
      }

      setState(() {
        parkingHistory = fetchedHistory;
      });
    } catch (e) {
      print("Error fetching parking history: $e");
    }
  }

  Future<void> fetchParkingPrices() async {
    try {
      final pricingDoc = await _firestore.collection('parkingselection').doc('pricing').get();
      if (pricingDoc.exists) {
        setState(() {
          parkingPrice = {
            'Hourly': pricingDoc.data()?['Hourly'],
            'Daily': pricingDoc.data()?['Daily'],
            'Weekly': pricingDoc.data()?['Weekly'],
          };
        });
      }
    } catch (e) {
      print("Error fetching parking prices: $e");
    }
  }

  void _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } catch (e) {
      print("Error signing out: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out. Please try again.')),
      );
    }
  }

  Future<void> toggleFavourite(String parkingId, Map<String, dynamic> parkingData) async {
    if (parkingId == null) {
      print("Error: parkingId is null.");
      return; 
    }
    
    DocumentReference favRef = _firestore.collection('favourite').doc(parkingId);
    DocumentSnapshot docSnapshot = await favRef.get();

    if (docSnapshot.exists) {
      await favRef.delete();
      setState(() {
        parkingData['isFavourite'] = false;
      });
    } else {
      final favouriteData = {
        'price': parkingData['price'],
        'pricingOption': parkingData['pricingOption'],
        'username': parkingData['username'],
        'vehiclePlateNum': parkingData['vehiclePlateNum'],
        'location': parkingData['location'],
        'userId': widget.userId,
      };

      await favRef.set(favouriteData);
      setState(() {
        parkingData['isFavourite'] = true;
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(parkingData['isFavourite'] ? 'Added to Favourites' : 'Removed from Favourites')),
    );
  }
  

  void _showPricingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPricingOption("Hourly", parkingPrice['Hourly'] ?? 'RM 0.60'),
              _buildPricingOption("Daily", parkingPrice['Daily'] ?? 'RM 5.00'),
              _buildPricingOption("Weekly", parkingPrice['Weekly'] ?? 'RM 23.00'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPricingOption(String title, String price) {
    return GestureDetector(
      onTap: () async {
        try {
          DocumentReference docRef = await _firestore.collection('history parking').add({
            'username': username,
            'userID': widget.userId,
            'pricingOption': title,
            'price': price,
            'location': null,
            'vehiclePlateNum': null,
            'timestamp': Timestamp.now(),
          });

          String userparkingselectionID = docRef.id;

          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LocationPage(
                userId: widget.userId,
                pricingOption: title,
                userparkingselectionID: userparkingselectionID,
              ),
            ),
          );
        } catch (e) {
          print("Error saving pricing option: $e");
        }
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 15),
        margin: EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              price,
              style: TextStyle(
                fontSize: 16,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> fetchPackages() async {
    try {
      final querySnapshot = await _firestore
        .collection('packages_bought')
        .where('userId', isEqualTo: widget.userId)
        .get();
      
      final List<Map<String, dynamic>> fetchedPackages = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'duration': data['duration'] ?? 'Unknown Package',
          'endDate': (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'vehiclePlate': data['vehiclePlate'] ?? 'Unknown Vehicle',
        };
      }).toList();

      setState(() {
        userPackages = fetchedPackages;
      });
    } catch (e) {
      print("Error fetching user packages: $e");
    }
  }

  Widget _buildPackageCard(Map<String, dynamic> packageData) {
    String duration = packageData['duration'] ?? 'Unknown Package';
    String vehicle = packageData['vehiclePlate'] ?? 'Unknown VehiclePlate';
    String endDate = packageData['endDate'] != null
        ? DateFormat('yyyy-MM-dd').format(packageData['endDate'])
        : 'Unknown Date';
        
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 5,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Package: $duration",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_month, color: Colors.white),
              SizedBox(width: 10),
              Text(
                "End Date: $endDate",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.time_to_leave, color: Colors.white),
              SizedBox(width: 10),
              Text(
                "Vehicle: $vehicle",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParkingHistoryCard(Map<String, dynamic> parkingData) {
    bool isFavourite = parkingData['isFavourite'] ?? false;
    String parkingId = parkingData['id'];

    //Retrieve start and end dates as Timestamps from the Firestore document
    dynamic startTimeData = parkingData['startTime'];
    dynamic endTimeData = parkingData['endTime'];

    //Format the start and end times
    String startDate = '';
    String endDate = '';

    if (startTimeData is Timestamp) {
      startDate = DateFormat('yyyy-MM-dd HH:mm').format(startTimeData.toDate());
    } else if (startTimeData is String) {
      try {
        startDate = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(startTimeData));
      } catch (e) {
        startDate = 'Invalid Start Date';
      }
    } else {
      startDate = 'Unknown Start Date';
    }

    if (endTimeData is Timestamp) {
      endDate = DateFormat('yyyy-MM-dd HH:mm').format(endTimeData.toDate());
    } else if (endTimeData is String) {
      try {
        endDate = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(endTimeData));
      } catch (e) {
        endDate = 'Invalid End Date';
      }
    } else {
      endDate = 'Unknown End Date';
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 5,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.red),
                  SizedBox(width: 10),
                  Text(
                    parkingData['location'] ?? 'Unknown Location',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  parkingData['pricingOption'] ?? 'N/A',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.access_time, color: Colors.red),
              SizedBox(width: 10),
              Text(
                "Start : $startDate\nEnd   : $endDate", 
                style: TextStyle(fontSize: 16),
              ),
              Spacer(),
              Text(
                parkingData['vehiclePlateNum'] ?? 'Car',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
          SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => toggleFavourite(parkingId, parkingData),
            icon: Icon(
              isFavourite ? Icons.favorite : Icons.favorite_border,
              color: Colors.black,
            ),
            label: Text(isFavourite ? 'Remove from Favorites' : 'Add to Favorites'),
            style: OutlinedButton.styleFrom(
              minimumSize: Size(double.infinity, 40),
              side: BorderSide(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Colors.black),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: Image.asset(
          'assets/logomelaka.jpg',
          height: 60,
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButton<String>(
              underline: SizedBox(),
              icon: Row(
                children: [
                  Text(
                    username,
                    style: TextStyle(color: Colors.black),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: Colors.black,
                  ),
                ],
              ),
              items: <String>['Profile', 'Logout'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? value) {
                if (value == 'Logout') {
                  _logout(context);
                } else if (value == 'Profile') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfilePage(userId: widget.userId),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.red,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/logomelaka.jpg',
                    height: 60,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Melaka Parking',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.home, color: Colors.red),
              title: Text('Home Page', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MainPage(
                      userId: widget.userId,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.history, color: Colors.red,),
              title: Text('Parking History', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HistoryPage(userId: widget.userId),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.favorite, color: Colors.red),
              title: Text('Favorite', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FavouritePage(userId: widget.userId),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.local_grocery_store_outlined, color: Colors.red),
              title: Text('Packages', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PackagesPage(userId: widget.userId),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.work_history_outlined, color: Colors.red),
              title: Text('Packages History', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PackagesHistoryPage(userId: widget.userId),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.celebration_rounded, color: Colors.red),
              title: Text('Your Rewards', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FreeParkingRewardsPage(userId: widget.userId),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Parking',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              parkingHistory.isEmpty
                  ? Center(child: Text(''))
                  : ListView.builder(
                      shrinkWrap: true,  
                      itemCount: parkingHistory.length,
                      itemBuilder: (context, index) {
                        return _buildParkingHistoryCard(parkingHistory[index]);
                      },
                    ),
              GestureDetector(
                onTap: () => _showPricingDialog(context),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_car, color: Colors.white, size: 50),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: Colors.white, size: 20),
                          SizedBox(width: 10),
                          Text(
                            'Add New Parking',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 60),

              Text(
                'Your Active Packages',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              userPackages.isEmpty
                ? Center(child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    margin: EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.not_interested_rounded, color: Colors.white),
                          SizedBox(width: 10),
                          Text(
                            'No packages bought.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              ),
                            ),
                        ],
                      ),
                    )))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: userPackages.length,
                    itemBuilder: (context, index) {
                      return _buildPackageCard(userPackages[index]);
                    },
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
