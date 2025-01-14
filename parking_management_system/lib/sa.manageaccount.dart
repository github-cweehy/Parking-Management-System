import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:parking_management_system/adminMainPage.dart';
import 'package:parking_management_system/sa.createaccount.dart';
import 'adminCustomerList.dart';
import 'adminEditPackagesBought.dart';
import 'adminEditParkingSelection.dart';
import 'adminHelp.dart';
import 'adminPBHistory.dart';
import 'adminPBTransactionHistory.dart';
import 'adminPSHistory.dart';
import 'adminPSTransactionHistory.dart';
import 'adminProfile.dart';
import 'adminReward.dart';
import 'login.dart';

class ManageAccountPage extends StatefulWidget {
  final String? superadminId;
  final String? adminId;

  ManageAccountPage({required this.superadminId, required this.adminId});

  @override
  _ManageAccountPage createState() => _ManageAccountPage();
}

class _ManageAccountPage extends State<ManageAccountPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String admin_username = '';

  List<Map<String, dynamic>> adminAccounts = [];

  @override
  void initState() {
    super.initState();
    _fetchAdminAccounts();
    _fetchAdminUsername();
    _fetchSuperAdminUsername();
  }

  // Perform initialization operations that depend on InheritedWidget here.
   @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchSuperAdminUsername();
    _fetchAdminUsername();
  }

 // Fetch superadmin username from Firebase
  void _fetchSuperAdminUsername() async {
    try {
      final superadminDoc = await FirebaseFirestore.instance.collection('superadmin').doc(widget.superadminId).get();
      if (superadminDoc.exists) {
        final role = superadminDoc.data()?['role']??'superadmin';

        if(role == 'superadmin') {
          setState(() {
            admin_username = superadminDoc.data()?['superadmin_username'] ?? 'Superadmin Username';
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching superadmin data: $e')),
      );
    }
  }

  // Fetch admin username from Firebase
  void _fetchAdminUsername() async {
    try {
      final adminDoc = await FirebaseFirestore.instance.collection('admins').doc(widget.adminId).get();

      if(adminDoc.exists) {
        final role = adminDoc.data()?['role'] ?? 'admins';

        if(role == 'admins') {
          setState(() {
            admin_username = adminDoc.data()?['admin_username'] ?? 'Admin Username';
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $e')),
      );
    }
  }

  //Fetch all admin accounts from firebase
  void _fetchAdminAccounts() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('admins').get();
      List<Map<String, dynamic>> updatedAccounts = snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['docId'] = doc.id;
        return data;
      }).toList();

      //Sort by admin_username
      updatedAccounts.sort((a, b) {
        return (a['admin_username'] ?? '').compareTo(b['admin_username'] ?? '');
      });

      setState(() {
        adminAccounts = updatedAccounts;
      });
    } catch (e) {
      print("Error fetching admin accounts: $e");
    }
  }

  //Show Dialog to confirm Delete Account
  void _showDeleteAccountDialog(BuildContext context, int index) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Delete Admin Account"),
            content: Text("Are you sure want to delete this account?"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  _deleteAccount(adminAccounts[index]['docId'], index);

                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Account deleted successfuly!")),
                  );
                },
                child: Text("Delete", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        });
  }

  //Delete Account
  void _deleteAccount(String docId, int index) async {
    try {
      await _firestore.collection('admins').doc(docId).delete();

      setState(() {
        adminAccounts.removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Account deleted successfully.")),
      );
    } catch (e) {
      print("Error deleting account: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete account. Please try again!")),
      );
    }
  }

  void _logout(BuildContext context) async {
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
              }),
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
                  Text(admin_username, style: TextStyle(color: Colors.black)),
                  Icon(Icons.arrow_drop_down, color: Colors.black),
                ],
              ),
              items: <String>[
                'Profile',
                'Logout'
              ].map((String value) {
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
                      builder: (context) => AdminProfilePage(superadminId: widget.superadminId ?? '', adminId: widget.adminId ?? ''),
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
      drawer: Drawer(
          child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.red,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
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
            leading: Icon(Icons.home, color: Colors.black, size: 23),
            title: Text('Home Page', style: TextStyle(color: Colors.black, fontSize: 16)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminMainPage(superadminId: widget.superadminId, adminId: widget.adminId),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.groups, color: Colors.black),
            title: Text('Manage Admin Account', style: TextStyle(color: Colors.black)),
            onTap: () {
              if (widget.superadminId != null && widget.superadminId!.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ManageAccountPage(superadminId: widget.superadminId, adminId: widget.adminId),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Access Denied: Superadmin Only!')),
                );
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.edit, color: Colors.black, size: 23),
            title: Text('Edit Parking Selection', style: TextStyle(color: Colors.black, fontSize: 16)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditParkingSelectionPage(superadminId: widget.superadminId, adminId: widget.adminId),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.history, color: Colors.black, size: 23),
            title: Text('Parking Selection History', style: TextStyle(color: Colors.black, fontSize: 16)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ParkingSelectionHistoryPage(superadminId: widget.superadminId, adminId: widget.adminId),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.payment, color: Colors.black, size: 23),
            title: Text('Parking Selection Transaction History', style: TextStyle(color: Colors.black, fontSize: 16)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ParkingSelectionTransactionHistoryPage(superadminId: widget.superadminId, adminId: widget.adminId),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.edit, color: Colors.black, size: 23),
            title: Text('Edit Packages Bought', style: TextStyle(color: Colors.black, fontSize: 16)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditPackagesBoughtPage(superadminId: widget.superadminId, adminId: widget.adminId),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.history, color: Colors.black, size: 23),
            title: Text('Packages Bought History', style: TextStyle(color: Colors.black, fontSize: 16)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PackagesBoughtHistoryPage(superadminId: widget.superadminId, adminId: widget.adminId),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.payment, color: Colors.black, size: 23),
            title: Text('Packages Bought Transaction History', style: TextStyle(color: Colors.black, fontSize: 16)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PackagesBoughtTransactionHistoryPage(superadminId: widget.superadminId, adminId: widget.adminId),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.menu_open, color: Colors.black, size: 23),
            title: Text('User Data List', style: TextStyle(color: Colors.black, fontSize: 16)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CustomerListPage(superadminId: widget.superadminId, adminId: widget.adminId),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.celebration_rounded, color: Colors.black, size: 23),
            title: Text('Reward History', style: TextStyle(color: Colors.black, fontSize: 16)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RewardHistoryPage(superadminId: widget.superadminId, adminId: widget.adminId),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.help_outline_sharp, color: Colors.black, size: 23),
            title: Text('Help Center', style: TextStyle(color: Colors.black, fontSize: 16)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserHelpPage(superadminId: widget.superadminId, adminId: widget.adminId),
                ),
              );
            },
          ),
        ],
      )),
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
                Text("Manage Admin Account", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
              ],
            ),
            SizedBox(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: adminAccounts.length,
                itemBuilder: (context, index) {
                  final admin = adminAccounts[index];

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red, width: 1.0),
                    ),
                    margin: EdgeInsets.symmetric(vertical: 10),
                    child: Padding(
                      padding: EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.person, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                admin['admin_username'] ?? 'No Username',
                                style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              Spacer(),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.white, size: 20),
                                onPressed: () async {
                                  _showDeleteAccountDialog(context, index);
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.email, color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text(
                                admin['email'] ?? 'No Email',
                                style: TextStyle(fontSize: 14, color: Colors.white),
                              ),
                            ],
                          ),
                          SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(Icons.phone_rounded, color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text(
                                admin['phone_number'] ?? 'No Phone Number',
                                style: TextStyle(fontSize: 14, color: Colors.white),
                              ),
                            ],
                          ),
                          SizedBox(height: 2),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                      onPressed: () async {
                        final refreshPage = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => CreateAdminAccountPage(superadminId: widget.superadminId ?? '', adminId: widget.adminId ?? '')),
                        );
                        //Returns is true then refreshes the data
                        if(refreshPage == true) {
                          _fetchAdminAccounts();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 35, vertical: 12),
                      ),
                      child: Text(
                        "Create Account",
                        style: TextStyle(fontSize: 15, color: Colors.white),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
