import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:parking_management_system/adminPBHistory.dart';
import 'adminEditPackagesBought.dart';
import 'adminEditParkingSelection.dart';
import 'adminPSHistory.dart';
import 'adminProfile.dart';
import 'login.dart';



class AdminMainPage extends StatefulWidget {
  final String adminId;

  AdminMainPage({required this.adminId});

  @override
  State<AdminMainPage> createState() => _AdminMainPageState();
}

class _AdminMainPageState extends State<AdminMainPage> {
  String adminUsername = '';

  @override
  void initState() {
    super.initState();
    _fetchUsername();
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

  void _logout(BuildContext context) async {
    try {
      // Sign out from firebase authentication
      await FirebaseAuth.instance.signOut();

      // Navigate to LoginPage and replace current page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } catch (e) {
      // Handle any errors that occur during sign-out
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
                    adminUsername,
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Parking Selection Card
            CustomCard(
              title: 'Parking Selection',
              options: [
                OptionItem(
                  icon: Icons.edit,
                  text: 'Edit Parking Selection',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditParkingSelectionPage(adminId: widget.adminId),
                      ),
                    );
                  },
                ),
                OptionItem(
                  icon: Icons.history,
                  text: 'Parking Selection History',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ParkingSelectionHistoryPage(adminId: widget.adminId),
                      ),
                    );
                  },
                ),
                OptionItem(
                  icon: Icons.payment,
                  text: 'Payment History',
                  onTap: () {
                    // Handle Payment History tap
                  },
                ),
              ],
            ),
            SizedBox(height: 20),

            // Packages Bought Card
            CustomCard(
              title: 'Packages Bought',
              options: [
                OptionItem(
                  icon: Icons.edit,
                  text: 'Edit Packages Bought',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditPackagesBoughtPage(adminId: widget.adminId),
                      ),
                    );
                  },
                ),
                OptionItem(
                  icon: Icons.history,
                  text: 'Packages Bought History',
                  onTap: () {
                    // Handle Packages Bought History tap
                    Navigator.push(
                      context, 
                      MaterialPageRoute(
                        builder: (context) => PackagesBoughtHistoryPage(adminId: widget.adminId),
                      ),
                    );
                  },
                ),
                OptionItem(
                  icon: Icons.payment,
                  text: 'Payment History',
                  onTap: () {
                    // Handle Payment History tap
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class CustomCard extends StatelessWidget {
  final String title;
  final List<OptionItem> options;

  CustomCard({required this.title, required this.options});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Column(
              children: options,
            ),
          ],
        ),
      ),
    );
  }
}

class OptionItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  OptionItem({required this.icon, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ListTile(
        leading: Icon(icon),
        title: Text(text),
      ),
    );
  }
}
