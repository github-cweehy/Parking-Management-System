import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'adminCustomerList.dart';
import 'adminEditPackagesBought.dart';
import 'adminEditParkingSelection.dart';
import 'adminHelp.dart';
import 'adminMainPage.dart';
import 'adminPBHistory.dart';
import 'adminPBTransactionHistory.dart';
import 'adminPSHistory.dart';
import 'adminPSTransactionHistory.dart';
import 'adminProfile.dart';
import 'adminReward.dart';
import 'login.dart';
import 'sa.manageaccount.dart';

class CreateAdminAccountPage extends StatefulWidget {
  final String superadminId;
  final String adminId;

  CreateAdminAccountPage({required this.superadminId, required this.adminId});

  @override
  _CreateAdminAccount createState() => _CreateAdminAccount();
}

class _CreateAdminAccount extends State<CreateAdminAccountPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String admin_username = '';

  final _formKey = GlobalKey<FormState>();
  String? firstName;
  String? lastName;
  String? email;
  String? adminusername;
  String? password;
  String? phoneNumber;
  bool isNotARobot = false;
  bool _isPasswordVisible = false;

  final TextEditingController _adminUsernameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchSuperAdminUsername();
    _fetchAdminUsername();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchSuperAdminUsername();
    _fetchAdminUsername();
  }


  // Fetch superadmin username from Firebase
  void _fetchSuperAdminUsername() async {
    try {
      DocumentSnapshot snapshot = await _firestore
        .collection('superadmin')
        .doc(widget.superadminId)
        .get();

      if (snapshot.exists && snapshot.data() != null) {
        setState(() {
          admin_username = snapshot['superadmin_username'];
        });
      }
    } catch (e) {
      print("Error fetching superadmin username: $e");
    }
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

  Future<void> createAdmin() async {
    if (_formKey.currentState!.validate() && isNotARobot) {
      try {
        final QuerySnapshot userduplicateEmail = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

        final QuerySnapshot adminduplicateEmail = await _firestore
          .collection('admins')
          .where('email', isEqualTo: email)
          .get();

        final QuerySnapshot superadminduplicateEmail = await _firestore
          .collection('superadmin')
          .where('email', isEqualTo: email)
          .get();

        if (userduplicateEmail.docs.isNotEmpty || adminduplicateEmail.docs.isNotEmpty || superadminduplicateEmail.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email already exists. Please use another email.'),
            ),
          );
          return;
        }

        final QuerySnapshot userduplicatePhoneNumber = await _firestore
          .collection('users')
          .where('phone_number', isEqualTo: phoneNumber)
          .get();

        final QuerySnapshot adminduplicatePhoneNumber = await _firestore
          .collection('admins')
          .where('phone_number', isEqualTo: phoneNumber)
          .get();

        final QuerySnapshot superadminduplicatePhoneNumber = await _firestore
          .collection('superadmin')
          .where('phone_number', isEqualTo: phoneNumber)
          .get();

        if (userduplicatePhoneNumber.docs.isNotEmpty || adminduplicatePhoneNumber.docs.isNotEmpty || superadminduplicatePhoneNumber.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Phone number alaready exists. Please use another phone number.'),
            ),
          );
          return;
        }

        //Add admin account to firebase
        await _firestore.collection('admins').add({
          'admin_username': adminusername,
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'phone_number': phoneNumber,
          'password': password,
          'profile_picture': null,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Admin account created successfully!'),
          ),
        );

        //Clear data after create account
        _adminUsernameController.clear();
        _firstNameController.clear();
        _lastNameController.clear();
        _emailController.clear();
        _phoneNumberController.clear();
        _passwordController.clear();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
          ),
        );
      }
    } else if (!isNotARobot) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please verify you are not a robot.'),
        ),
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
          if (widget.superadminId.isNotEmpty)
            ListTile(
              leading: Icon(Icons.groups, color: Colors.black),
              title: Text('Manage Admin Account', style: TextStyle(color: Colors.black)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ManageAccountPage(
                      superadminId: widget.superadminId,
                      adminId: widget.adminId,
                    ),
                  ),
                );
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
          ListTile(
            leading: Icon(Icons.help_outline_sharp, color: Colors.black, size: 23),
            title: Text('Create', style: TextStyle(color: Colors.black, fontSize: 16)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateAdminAccountPage(
                    superadminId: widget.superadminId,
                    adminId: widget.adminId,
                  ),
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
                  Text(
                    "Create Admin Account",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),
              Expanded(
                child: ListView(children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextFormField(
                          onChanged: (value) => adminusername = value,
                          controller: _adminUsernameController,
                          decoration: InputDecoration(
                            labelText: 'Admin Username',
                            filled: true,
                            fillColor: Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter admin username';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          onChanged: (value) => firstName = value,
                          controller: _firstNameController,
                          decoration: InputDecoration(
                            labelText: 'First Name',
                            filled: true,
                            fillColor: Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) => value == null || value.isEmpty ? 'Please enter first name' : null,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          onChanged: (value) => lastName = value,
                          controller: _lastNameController,
                          decoration: InputDecoration(
                            labelText: 'Last Name',
                            filled: true,
                            fillColor: Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) => value == null || value.isEmpty ? 'Please enter last name' : null,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          onChanged: (value) => email = value,
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            filled: true,
                            fillColor: Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter email';
                            }
                            if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                              return 'Invalid email format';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          onChanged: (value) => phoneNumber = value,
                          controller: _phoneNumberController,
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            filled: true,
                            fillColor: Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          obscureText: !_isPasswordVisible,
                          controller: _passwordController,
                          onChanged: (value) => password = value,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            filled: true,
                            fillColor: Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                              ),
                              onPressed: () => setState(
                                () => _isPasswordVisible = !_isPasswordVisible,
                              ),
                            ),
                          ),
                          validator: (value) => value == null || value.length < 10 ? 'Password must be at least 10 characters' : null,
                        ),
                        SizedBox(height: 60),
                        CheckboxListTile(
                          value: isNotARobot,
                          onChanged: (value) => setState(() => isNotARobot = value!),
                          title: const Text('I am not a robot'),
                        ),
                        SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: createAdmin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                            child: Text(
                              'Create Account',
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ],
          )),
    );
  }
}
