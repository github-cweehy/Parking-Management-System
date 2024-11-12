import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
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
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      setState(() {
        username = userDoc.data()?['username'] ?? 'Username';
      });
    } catch (e) {
      print("Error fetching username: $e");
    }
  }

  Future<void> _fetchParkingHistory() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('history parking')
          .where('userID', isEqualTo: widget.userId)
          .get();

      setState(() {
        parkingHistory = querySnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
      });
    } catch (e) {
      print("Error fetching parking history: $e");
    }
  }

  void _logout(BuildContext context) async{
  try {
    // Sign out from Firebase Authentication
    await FirebaseAuth.instance.signOut();
    
    // Navigate to LoginPage and replace the current page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  } catch (e) {
    // Handle any errors that occur during sign-out
    print("Error signing out: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error signing out. Please try again.')),
    );
  }
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
        // Save the pricing option to Firebase and get the document reference
        DocumentReference docRef = await FirebaseFirestore.instance.collection('history parking').add({
          'username': username,
          'userID' : widget.userId,
          'pricingOption': title, //selections
          'price': price, //default
          'location': null,
          'vehiclePlateNum': null,
          'timestamp': Timestamp.now(),
        });

        // Fetch the document ID of the added document
        String userparkingselectionID = docRef.id;

        // Navigate to LocationPage with the document ID
        Navigator.pop(context); // Close the dialog
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LocationPage(
              userId: widget.userId,
              pricingOption: title,
              userparkingselectionID: userparkingselectionID, // Pass the document ID
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

  // Retrieve start and end dates as Timestamps from the Firestore document
  Timestamp? startDateTimestamp = parkingData['startDate'];
  Timestamp? endDateTimestamp = parkingData['endDate'];

  // Format the Timestamps into readable date strings
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
              padding:  EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              '$startDate ' + parkingData['startTime'] + '\n' + '$endDate ' + parkingData['endTime'], // Placeholder timing
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
          onPressed: () {
            // Add your logic for adding to favorites
          },
          icon: Icon(Icons.star_border, color: Colors.black),
          label: Text('Add to Favorites'),
          style: OutlinedButton.styleFrom(
            minimumSize: Size(double.infinity, 40),
            side: BorderSide(color: Colors.black),
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
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.black),
          onPressed: () {
            // Handle menu press
          },
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
                if (value == 'Profile') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfilePage(userId: widget.userId),
                    ),
                  );
                } else if (value == 'Logout') {
                  _logout(context);
                }
              },
            ),
          ),
        ],
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
