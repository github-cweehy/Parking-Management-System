import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditPackagesBoughtPage extends StatefulWidget {
  final String adminId;

  EditPackagesBoughtPage({required this.adminId});

  @override
  _EditPackagesBoughtPageState createState() => _EditPackagesBoughtPageState();
}

class _EditPackagesBoughtPageState extends State<EditPackagesBoughtPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> monthlyRates = [];
  String username = "Username"; // Placeholder for the username

  @override
  void initState() {
    super.initState();
    _fetchRatesFromFirebase();
  }

  // Fetch data from Firebase
  void _fetchRatesFromFirebase() async {
    DocumentSnapshot snapshot = await _firestore.collection('packagesRates').doc('rates').get();
    setState(() {
      monthlyRates = List<Map<String, dynamic>>.from(snapshot['monthlyRates']);
    });
  }

  // Save changes to Firebase
  void saveChanges() async {
    await _firestore.collection('packagesRates').doc('rates').set({
      'monthlyRates': monthlyRates,
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Price saved successfully!')));
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
            // Handle Menu press
          },
        ),
        
        title: Image.asset(
          'assets/logomelaka.jpg', // Replace with your logo path
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
                // Handle dropdown selection
                if (value == 'Logout') {
                  // Implement logout
                } else if (value == 'Profile') {
                  // Navigate to profile
                }
              },
            ),
          )
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Edit Packages",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            
            Expanded(
              child: ListView.builder(
                itemCount: monthlyRates.length,
                itemBuilder: (context, index) {
                  final rate = monthlyRates[index];
                  return Card(
                    color: Colors.red,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: Icon(Icons.access_time, color: Colors.white),
                      title: Text(
                        "${rate['duration']}",
                        style: TextStyle(color: Colors.white),
                      ),
                      trailing: Text(
                        "RM ${rate['price']}",
                        style: TextStyle(color: Colors.white),
                      ),
                      onTap: () async {
                        // Optional: Implement an edit dialog for individual rates
                      },
                    ),
                  );
                },
              ),
            ),
            Center(
              child: ElevatedButton(
                onPressed: saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                ),
                child: Text("Save"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
