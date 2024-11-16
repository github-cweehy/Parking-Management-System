import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:parking_management_system/packages.dart';
import 'favourite.dart';
import 'history.dart';
import 'userprofile.dart';
import 'login.dart';
import 'location.dart';

class MainPage extends StatefulWidget {
  final String userId;

  MainPage({required this.userId});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? currentUser = FirebaseAuth.instance.currentUser;
  bool isFavourite = false;

  String username = '';
  List<Map<String, dynamic>> parkingHistory = [];

  @override
  void initState() {
    super.initState();
    _fetchUsername();
    _fetchParkingHistory();
  }

  Future<void> _fetchUsername() async {
    try {
      final userDoc = await _firestore.collection('users').doc(widget.userId).get();
      setState(() {
        username = userDoc.data()?['username'] ?? 'Username';
      });
    } catch (e) {
      print("Error fetching username: $e");
    }
  }

  Future<void> _fetchParkingHistory() async {
    try {
      final querySnapshot = await _firestore
          .collection('history parking')
          .where('userID', isEqualTo: widget.userId)
          .get();

      final List<Map<String, dynamic>> fetchedHistory = [];

      for (var doc in querySnapshot.docs) {
        final parkingData = doc.data() as Map<String, dynamic>;
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
              _buildPricingOption("Hourly", "RM 0.60"),
              _buildPricingOption("Daily", "RM 5.00"),
              _buildPricingOption("Weekly", "RM 23.00"),
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

  Widget _buildParkingHistoryCard(Map<String, dynamic> parkingData) {
    bool isFavourite = parkingData['isFavourite'] ?? false;
    String parkingId = parkingData['id'];

    //Retrieve start and end dates as Timestamps from the Firestore document
    Timestamp? startDateTimestamp = parkingData['startDate'];
    Timestamp? endDateTimestamp = parkingData['endDate'];

    //Format the Timestamps into readable data strings
    String startDate = startDateTimestamp != null
        ? DateFormat('yyyy-MM-dd').format(startDateTimestamp.toDate())
        : 'Unknown Start Date';
    String endDate = endDateTimestamp != null
        ? DateFormat('yyyy-MM-dd').format(endDateTimestamp.toDate())
        : 'Unknown End Date';

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
                '${parkingData['startTime'] ?? ''}\n${parkingData['endTime'] ?? ''}',
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
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
            SizedBox(height: 20),
            parkingHistory.isEmpty
                ? Center(child: Text(''))
                : ListView.builder(
                    shrinkWrap: true,  // Ensures the ListView only takes as much space as it needs
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
          ],
        ),
      ),
    );
  }
}
