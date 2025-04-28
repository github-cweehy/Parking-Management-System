import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'login.dart';

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

  final TextEditingController _adminUsernameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchSuperAdminUsername();
    _fetchAdminUsername();
  }

  // Fetch superadmin username from Firebase
  void _fetchSuperAdminUsername() async {
    try {
      final superadminDoc = await FirebaseFirestore.instance
          .collection('superadmin')
          .doc(widget.superadminId)
          .get();
      if (superadminDoc.exists) {
        final role = superadminDoc.data()?['role'] ?? 'superadmin';
        if (role == 'superadmin') {
          setState(() {
            admin_username = superadminDoc.data()?['superadmin_username'] ?? 'Superadmin Username';
          });
        }
      }
    } catch (e) {
      _showErrorSnackbar('Error fetching superadmin data: $e');
    }

    print('Fetching superadmin data for ID: ${widget.superadminId}');
  }

  // Fetch admin username from Firebase
  void _fetchAdminUsername() async {
    if (widget.adminId == null || widget.adminId!.isEmpty) {
      print('Admin ID is empty');
      return;
    }
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

  void _showErrorSnackbar(String message) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    });
  }

  Future<void> createAdmin() async {
    if (_formKey.currentState!.validate() && isNotARobot) {
      try {
        final QuerySnapshot userduplicateUsername = await _firestore
          .collection('users')
          .where('username', isEqualTo: adminusername)
          .get();

        final QuerySnapshot adminduplicateUsername = await _firestore
          .collection('admins')
          .where('admin_username', isEqualTo: adminusername)
          .get();

        final QuerySnapshot superadminduplicateUsername = await _firestore
          .collection('superadmin')
          .where('superadmin_username', isEqualTo: adminusername)
          .get();

        if (userduplicateUsername.docs.isNotEmpty || adminduplicateUsername.docs.isNotEmpty || superadminduplicateUsername.docs.isNotEmpty) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Username already exists. Please use another username.'),
              ),
            );
          });
          return;
        }

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
          SchedulerBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Email already exists. Please use another email.'),
                ),
              );
            });
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
          SchedulerBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Phone number already exists. Please use another phone number.'),
              ),
            );
          });
          return;
        }

        //Add admin account to firebase
        await _firestore.collection('admins').add({
          'admin_username': adminusername,
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'phone_number': phoneNumber,
          'password': 'PMSadmin!789',
          'profile_picture': null,
          'role': 'admins',
        });

        SchedulerBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Admin account created successfully!'),
            ),
          );
        });

        //Clear data after create account
        _adminUsernameController.clear();
        _firstNameController.clear();
        _lastNameController.clear();
        _emailController.clear();
        _phoneNumberController.clear();

        Navigator.pop(context, true);
      } catch (e) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
            ),
          );
        });
      }
    } else if (!isNotARobot) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please verify you are not a robot.'),
          ),
        );
      });
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
        //Disable the default return arrow
        automaticallyImplyLeading: false,
        title: Image.asset(
          'assets/logomelaka.jpg',
          height: 60,
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              admin_username,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ),
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
                  Text(
                    "Create Admin Account",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 25),
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
                            if (value.length < 3) {
                              return 'Username must be at least 3 characters';
                            }
                            if (value.length > 10) {
                              return 'Username must not exceed 10 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 25),
                        
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
                          validator: (value) => 
                            value == null || value.isEmpty ? 'Please enter first name' : null,
                        ),
                        const SizedBox(height: 25),

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
                          validator: (value) => 
                            value == null || value.isEmpty ? 'Please enter last name' : null,
                        ),
                        const SizedBox(height: 25),

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
                             if (value.length > 30) {
                              return 'Email must not exceed 30 characters';
                            }
                            if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                              return 'Invalid email format';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 25),

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
                            if (value.length != 10 && value.length != 11) {
                              return 'Phone number must be 10 or 11 digits';
                            }
                            if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                              return 'Phone number can only contain numbers';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 65),
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
