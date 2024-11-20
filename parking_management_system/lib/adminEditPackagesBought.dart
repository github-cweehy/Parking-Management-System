import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:parking_management_system/adminMainPage.dart';
import 'package:parking_management_system/adminProfile.dart';
import 'login.dart';


class EditPackagesBoughtPage extends StatefulWidget {
  final String adminId;

  EditPackagesBoughtPage({required this.adminId});

  @override
  _EditPackagesBoughtPageState createState() => _EditPackagesBoughtPageState();
}

class _EditPackagesBoughtPageState extends State<EditPackagesBoughtPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String admin_username = '';

  List<Map<String, dynamic>> monthly = [];

  @override
  void initState() {
    super.initState();
    _fetchRatesFromFirebase();
    _fetchAdminUsername();
  }

  // Fetch admin username from Firebase
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
    try {
      List<Map<String, dynamic>> rates = [];
      QuerySnapshot querySnapshot = await _firestore.collection('packagesprice').get();

      for (String duration in ['1-month', '3-month', '6-month']) {
        DocumentSnapshot snapshot = await _firestore.collection('packagesprice').doc(duration).get();
        if (snapshot.exists) {
          rates.add({
            'duration': duration.replaceAll('-', ' ').split(' ').map((word) => word[0].toUpperCase() + word.substring(1)).join(' '),
            'price': snapshot['price'].toDouble(),
            'docId': duration, 
          });
        }
      }
      setState(() {
        monthly = rates;
      });
    } catch (e) {
      print("Error fetching rates: $e");
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


  // Save changes to Firebase
  void saveChanges() async {
    try {
      for (var rate in monthly) {
        await _firestore.collection('packagesprice').doc(rate['docId']).update({
          'price': rate['price'],
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Prices saved successfully!')));
    } catch (e) {
      print("Error saving changes: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error saving changes. Please try again!")));
    }
  }

  // Show dialog to edit price
  void _showEditDialog(BuildContext context, int index) {
    TextEditingController priceController = TextEditingController(
      text: monthly[index]['price'].toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Edit Price for ${monthly[index]['duration']}"),
          content: TextField(
            controller: priceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Enter new price",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  // Validate the price input is valid
                  double ? newPrice = double.tryParse(priceController.text);

                  if(newPrice != null){
                    monthly[index]['price'] = newPrice;
                  }
                });
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text("Save"),
            ),
          ],
        );
      },
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
            // Handle Menu press
            Scaffold.of(context).openDrawer();
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
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios, color: Colors.black),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                SizedBox(width: 10),
                Text(
                  "Edit Packages Bought",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 8),
            
            Expanded(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: Colors.grey.shade400, 
                        width: 1.0,       
                      ),
                      borderRadius: BorderRadius.circular(10), 
                    ),
                    child: ListView.builder(
                      itemCount: monthly.length,
                      padding: const EdgeInsets.all(8.0),
                      itemBuilder: (context, index) {
                        final rate = monthly[index];
                        return Card(
                          color: Colors.red,
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: Icon(Icons.access_time, color: Colors.white),
                            title: Text(
                              "${rate['duration']}",
                              style: TextStyle(color: Colors.white),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "RM ",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(width: 2),
                                SizedBox(
                                  width: 60,
                                  child: Text(
                                    monthly[index]['price'].toStringAsFixed(2),
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.white),
                                  onPressed: () async{
                                    _showEditDialog(context, index);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                fixedSize: Size(100, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ) // Background color
              ),
              child: Text(
                "Save",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
