import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'adminProfile.dart';
import 'login.dart';

class PackagesBoughtHistoryPage extends StatefulWidget{
  final String adminId;

  PackagesBoughtHistoryPage({required this.adminId});

  @override
  _PackagesBoughtHistoryPage createState() => _PackagesBoughtHistoryPage();
}

class _PackagesBoughtHistoryPage extends State<PackagesBoughtHistoryPage>{
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

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.black),
          onPressed: () {
            //Handle Menu Press
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
              underline: Container(),
              icon: Row(
                children: [
                  Text(adminUsername, style: TextStyle(color: Colors.black)),
                  Icon(Icons.arrow_drop_down, color: Colors.black),
                ],
              ),
              items: ['Profile', 'Logout'].map((String value){
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? value){
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
                Text("Packages Bought History", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Start Date Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 10.0),
                      child: 
                        Text("Start Date", style: TextStyle(fontSize: 13)),
                    ),

                    GestureDetector(
                      onTap: () => _selectDate(context, true),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(
                              Icons.calendar_month,
                              color: Colors.grey,
                              size: 20, 
                            ),
                            SizedBox(width: 10),
                            Text(
                              "${startDate.day} ${_monthName(startDate.month)} ${startDate.year}",
                              style: TextStyle(color: Colors.black, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // End Date Section
               Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 10.0),
                      child: 
                        Text("End Date", style: TextStyle(fontSize: 13)),
                    ),

                    GestureDetector(
                      onTap: () => _selectDate(context, false),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(
                              Icons.calendar_month,
                              color: Colors.grey,
                              size: 20, 
                            ),
                            SizedBox(width: 10),
                            Text(
                              "${endDate.day} ${_monthName(endDate.month)} ${endDate.year}",
                              style: TextStyle(color: Colors.black, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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





}