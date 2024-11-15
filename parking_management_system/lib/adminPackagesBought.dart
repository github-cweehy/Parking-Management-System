import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:parking_management_system/adminProfile.dart';

class EditPackagesBoughtPage extends StatefulWidget {
  final String adminId;

  EditPackagesBoughtPage({required this.adminId});

  @override
  _EditPackagesBoughtPageState createState() => _EditPackagesBoughtPageState();
}

class _EditPackagesBoughtPageState extends State<EditPackagesBoughtPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> monthlyRates = [];
  String admin_username = ''; 

  @override
  void initState() { 
    super.initState();
    _fetchRatesFromFirebase();
    _fetchAdminUsername();
  }

  //Fetch admin username from firebase
  void _fetchAdminUsername() async {
  try {
    DocumentSnapshot snapshot = await _firestore.collection('admins').doc(widget.adminId).get();
    if (snapshot.exists && snapshot.data() != null) {
      setState(() {
        admin_username = snapshot['admin_username'];  
      });
    }
  } catch (e) {
    print("Error fetching admin username: $e");
  }
}

  // Fetch rates data from Firebase
  void _fetchRatesFromFirebase() async {
  DocumentSnapshot snapshot = await _firestore.collection('packagesRates').doc('monthlyRates').get();
  
  if (snapshot.exists) {
    setState(() {
      monthlyRates = [
        {'duration': '1 Month', 'price': snapshot['1 Month']},
        {'duration': '3 Months', 'price': snapshot['3 Months']},
        {'duration': '6 Months', 'price': snapshot['6 Months']},
      ];
    });
  } else {
    print("Document not found!");
  }
}

  //logout
  void _logout(BuildContext context) async{
    try{
      //Sign out from firebase authentication
      await FirebaseAuth.instance.signOut();

      //Navigate to LoginPage and replace current page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }catch(e){
      //Handle any errors that occur during sign-out
      print("Error sign out: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sign out. Please try again')),
      );
    }
  }

  // Save changes to Firebase
  void saveChanges() async {
    await _firestore.collection('packagesRates').doc('monthlyRates').update({
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
                    admin_username,
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
                if (value == 'Profile') {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (context) => AdminProfilePage(adminId: widget.adminId),
                    ),
                  );
                } else if (value == 'Logout') {
                  // Navigate to profile
                  _logout(context);
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
             IconButton(
              icon: Icon(Icons.arrow_back_ios, color: Colors.black), // 返回按钮
              onPressed: () {
                Navigator.pop(context); 
              },
            ),
            SizedBox(width: 10),

            Text(
              "Edit Packages Boughth",
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

// Placeholder for LoginPage widget
class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login Page')),
      body: Center(child: Text('Login Page Content')),
    );
  }
}
