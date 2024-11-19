import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:parking_management_system/adminEditPackagesBought.dart';
import 'package:parking_management_system/adminMainPage.dart';
import 'package:parking_management_system/adminProfile.dart';
import 'package:parking_management_system/login.dart'; 

class ParkingSelectionHistoryPage extends StatefulWidget {
  final String adminId;

  ParkingSelectionHistoryPage({required this.adminId});

  @override
  _ParkingSelectionHistoryPageState createState() => _ParkingSelectionHistoryPageState();
}

class _ParkingSelectionHistoryPageState extends State<ParkingSelectionHistoryPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String username = ''; 
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();
  String adminUsername = '';

  Timestamp? startTimestamp;
  Timestamp? endTimestamp;

  @override
  void initState(){
    super.initState();
    _fetchUsername();
    startTimestamp = Timestamp.fromDate(startDate);
    endTimestamp = Timestamp.fromDate(endDate);
  }

  Future<void> _fetchUsername() async {
    try {
      final adminDoc = await FirebaseFirestore.instance
        .collection('admins')
        .doc(widget.adminId)
        .get();

      setState(() {
        adminUsername = adminDoc.data()?['admin_username'] ?? 'Admin Username';
      });
    } catch (e) {
      print("Error fetching admin username: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading admin data. Please try again.')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? startDate : endDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2025),
    );
    
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          startDate = picked;
          startTimestamp = Timestamp.fromDate(startDate);
        } else {
          endDate = picked;
          endTimestamp = Timestamp.fromDate(endDate);
        }
      });
    }
  }

  Stream<QuerySnapshot> getFilteredData() {
    return _firestore
      .collection('history parking')
      .where('date', isGreaterThanOrEqualTo: startTimestamp)
      .where('date', isLessThanOrEqualTo: endTimestamp)
      .snapshots();
  }

  void _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } catch (e) {
      print("Error sign out: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sign out. Please try again')),
      );
    }
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
            //Handle Menu press
          },
        ),

        title: Image.asset(
          'assets/logomelaka.jpg', 
          height: 60
        ),
        
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButton<String>(
              underline: Container(),
              icon: Row(
                children: [
                  Text(adminUsername, style: TextStyle(color: Colors.black)),
                  Icon(Icons.arrow_drop_down, color: Colors.black),
                ],
              ),
              items: ['Profile', 'Logout'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? value) {
                if (value == 'Profile') {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminProfilePage(adminId: widget.adminId),
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
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios, color: Colors.black),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                Text("Parking Selection History", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 30),
            
            Row(
              children: [
                // Start Date Section
                GestureDetector(
                  onTap: () => _selectDate(context, true),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("${startDate.day} ${_monthName(startDate.month)} ${startDate.year}",
                            style: TextStyle(color: Colors.black, fontSize: 13)),
                        Icon(Icons.calendar_today, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 8),
                // End Date Section
                GestureDetector(
                  onTap: () => _selectDate(context, false),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("${endDate.day} ${_monthName(endDate.month)} ${endDate.year}",
                            style: TextStyle(color: Colors.black, fontSize: 13)),
                        Icon(Icons.calendar_today, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                
                // Search Icon
                IconButton(
                  icon: Icon(Icons.search_sharp, color: Colors.grey),
                  onPressed: () {
                    setState(() {}); // Refresh to apply date filtering
                  },
                ),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: getFilteredData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Error loading data."));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text("No data found!"));
                  }
                  return ListView(
                    children: snapshot.data!.docs.map((doc) {
                      return _buildParkingCard(doc);
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int month) {
    List<String> monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return monthNames[month - 1];
  }

  Widget _buildParkingCard(QueryDocumentSnapshot doc) {
    return Card(
      color: Colors.red,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.black),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doc['username'], style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text("Packages: ${doc['packagesType']} RM ${doc['amount']}", style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            Icon(Icons.more_horiz, color: Colors.white),
          ],
        ),
      ),
    );
  }
}