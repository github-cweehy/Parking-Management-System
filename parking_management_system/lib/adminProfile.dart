import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'adminCustomerList.dart';
import 'adminEditPackagesBought.dart';
import 'adminEditParkingSelection.dart';
import 'adminHelp.dart';
import 'adminMainPage.dart';
import 'adminPBHistory.dart';
import 'adminPBTransactionHistory.dart';
import 'adminPSHistory.dart';
import 'adminPSTransactionHistory.dart';
import 'adminReward.dart';
import 'login.dart';
import 'dart:io';
import 'sa.manageaccount.dart';

class AdminProfilePage extends StatefulWidget {
  final String? superadminId;
  final String? adminId;

  AdminProfilePage({required this.superadminId, required this.adminId});

  @override
  _AdminProfilePageState createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  Map<String, dynamic>? adminData;
  String adminUsername = '';
  String adminEmail = '';
  String adminPhoneNumber = '';
  String adminFirstName = '';
  String adminLastName = '';
  String adminProfilePicture = '';
  String? profileImageUrl;

  TextEditingController phoneController = TextEditingController();
  TextEditingController newPasswordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchSuperadminData();
    _fetchAdminData();
  }

  void _fetchSuperadminData() async {
    try {
      DocumentSnapshot superadminDoc = await FirebaseFirestore.instance.collection('superadmin').doc(widget.superadminId).get();
      Map<String, dynamic>? data = superadminDoc.data() as Map<String, dynamic>?;

      if (data != null) {
        setState(() {
          adminData = data;
          adminUsername = data['superadmin_username'] ?? '';
          adminEmail = data['email'] ?? '';
          adminPhoneNumber = data['phone_number'] ?? '';
          adminFirstName = data['first_name'] ?? '';
          adminLastName = data['last_name'] ?? '';
          adminProfilePicture = data['profile_picture'] ?? ''; // Use empty string if null
        });
      }
    } catch (e) {
      print("Error fetching admin data: $e");
    }
  }

  Future<void> _fetchAdminData() async {
    try {
      DocumentSnapshot adminDoc = await FirebaseFirestore.instance.collection('admins').doc(widget.adminId).get();
      Map<String, dynamic>? data = adminDoc.data() as Map<String, dynamic>?;

      if (data != null) {
        setState(() {
          adminData = data;
          adminUsername = data['admin_username'] ?? '';
          adminEmail = data['email'] ?? '';
          adminPhoneNumber = data['phone_number'] ?? '';
          adminFirstName = data['first_name'] ?? '';
          adminLastName = data['last_name'] ?? '';
          adminProfilePicture = data['admin_profilePicture'] ?? ''; // Use empty string if null
        });
      }
    } catch (e) {
      print("Error fetching admin data: $e");
    }
  }

  //Function to pick image from gallery
  void _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      _uploadProfilePicture(image);
    }
  }

  //Function to upload image to Firebase Storage
  Future<void> _uploadProfilePicture(XFile image) async {
    try {
      String fileName = path.basename(image.path);

      final String pathPrefix = (widget.superadminId != null && widget.superadminId!.isNotEmpty) 
        ? 'superadmin_profilePicture' 
        : 'admin_profilePicture';

      final String userId = (widget.superadminId != null && widget.superadminId!.isNotEmpty) 
        ? widget.superadminId! 
        : widget.adminId!;

      final Reference storageRef = FirebaseStorage.instance
        .ref()
        .child('$pathPrefix/$userId/$fileName');

      //upload picture
      UploadTask uploadTask = storageRef.putFile(File(image.path));

      //to get picture url
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      //Update profile_picture path in Firestore
      if (widget.superadminId != null && widget.superadminId!.isNotEmpty) {
        await FirebaseFirestore.instance.collection('superadmin').doc(widget.superadminId).update({
          'profile_picture': downloadUrl,
        });
      } else {
        await FirebaseFirestore.instance.collection('admins').doc(widget.adminId).update({
          'admin_profilePicture': downloadUrl,
        });
      }

      setState(() {
        adminProfilePicture = downloadUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile picture updated successfully!')),
      );
    } catch (e) {
      print("Error uploading profile picture: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload profile picture. Please try again.')),
      );
    }
  }

  //change password
  void _changePassword() async {
    String newPassword = newPasswordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    if (newPassword.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password must be at least 8 characters long.')),
      );
      return;
    }

    RegExp passwordRegExp = RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]+$');
    if (!passwordRegExp.hasMatch(newPassword)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password must include upper, lower, number, and special character.')),
      );
      return;
    }
    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }

    try {
      if (widget.superadminId != null && widget.superadminId!.isNotEmpty) {
        await FirebaseFirestore.instance.collection('superadmin').doc(widget.superadminId).update({
          'password': newPassword
        });
      } 
      else {
        await FirebaseFirestore.instance.collection('admins').doc(widget.adminId).update({
          'password': newPassword
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password updated successfully!')),
      );

      //clear the text after successful update password
      newPasswordController.clear();
      confirmPasswordController.clear();
    } catch (e) {
      print("Failed to update password: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update password. Please try again.')),
      );
    }
  }

  //avoid duplicate phone number
  void _isPhoneNumberDuplicate(String phone_number) async {
    try {
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance.collection('users').where('phone_number', isEqualTo: phone_number).get();
      QuerySnapshot superadminSnapshot = await FirebaseFirestore.instance.collection('superadmin').where('phone_number', isEqualTo: phone_number).get();
      QuerySnapshot adminSnapshot = await FirebaseFirestore.instance.collection('admins').where('phone_number', isEqualTo: phone_number).get();

      if (userSnapshot.docs.isNotEmpty || adminSnapshot.docs.isNotEmpty || superadminSnapshot.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('This phone number is already exist.')),
        );
      } else {
        _savePhoneNumber(phone_number);
      }
    } catch (e) {
      print("Error checking duplicate phone number: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to check phone number. Please try again.')));
    }
  }

  //save the new phone number after duplicate check
  void _savePhoneNumber(String phone_number) async {
    try {
      if (widget.superadminId != null && widget.superadminId!.isNotEmpty) {
        await FirebaseFirestore.instance.collection('superadmin').doc(widget.superadminId).update({
          'phone_number': phone_number
        });
      } else {
        await FirebaseFirestore.instance.collection('admins').doc(widget.adminId).update({
          'phone_number': phone_number
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Phone number updated successfully!')),
      );
    } catch (e) {
      print("Error saving phone number: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update phone number. Please try again.')),
      );
    }
  }

  void _logout(BuildContext context) async {
    try {
      //Sign out from Firebase Authentication
      await FirebaseAuth.instance.signOut();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } catch (e) {
      //Handle error when during sign out
      print("Erro sign out: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sign out. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // If the data is not loaded, show a loading indicator
    if (adminData == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Loading...'),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
                  items: <String>[
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
                          builder: (context) => AdminProfilePage(superadminId: widget.superadminId, adminId: widget.adminId),
                        ),
                      );
                    } else if (value == 'Logout') {
                      _logout(context);
                    }
                  },
                )),
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
        body: Column(
          children: [
            TabBar(
              indicatorColor: Colors.red,
              tabs: [
                Tab(child: Text("Profile", style: TextStyle(color: Colors.black))),
                Tab(child: Text("Edit Profile", style: TextStyle(color: Colors.black))),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Profile Tab
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.red,
                          backgroundImage: adminProfilePicture.isNotEmpty ? NetworkImage(adminProfilePicture) : null,
                          child: adminProfilePicture.isEmpty ? Icon(Icons.person, color: Colors.black, size: 50) : null,
                        ),
                        const SizedBox(height: 15),

                        Text(
                          adminUsername.isEmpty ? 'Admin Name' : adminUsername,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),

                        _buildReadOnlyTextField('First Name', adminFirstName),
                        const SizedBox(height: 20),

                        _buildReadOnlyTextField('Last Name', adminLastName),
                        const SizedBox(height: 20),

                        _buildReadOnlyTextField('Email', adminEmail),
                        const SizedBox(height: 20),

                        _buildReadOnlyTextField('Phone Number', adminPhoneNumber),
                        const SizedBox(height: 20),

                        //Return Button
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AdminMainPage(superadminId: widget.superadminId, adminId: widget.adminId),
                                ));
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              fixedSize: Size(100, 45),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              )),
                          child: Text(
                            'Return',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Edit Profile Tab
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ListView(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 55,
                              backgroundColor: Colors.red,
                              backgroundImage: adminProfilePicture.isNotEmpty ? NetworkImage(adminProfilePicture) : null,
                              child: adminProfilePicture.isEmpty ? Icon(Icons.person, color: Colors.black, size: 50) : null,
                            ),
                            const SizedBox(width: 50),
                            ElevatedButton.icon(
                              onPressed: _pickImage,
                              icon: Icon(Icons.upload, color: Colors.white),
                              label: Text(
                                'Upload',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 25),
                        _buildReadOnlyTextField('Username', adminUsername),
                        const SizedBox(height: 15),
                        _buildReadOnlyTextField('Email', adminEmail),
                        const SizedBox(height: 15),
                        _buildEditableTextField('Phone Number', adminPhoneNumber, () {
                          _edit('phone_number', adminPhoneNumber);
                        }),
                        const SizedBox(height: 15),
                        ElevatedButton(
                          onPressed: () {
                            String newPhoneNumber = phoneController.text.trim();
                            if (newPhoneNumber != adminPhoneNumber) {
                              _isPhoneNumberDuplicate(newPhoneNumber);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            minimumSize: Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 15)),
                        ),
                        SizedBox(height: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Change your password',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 5),
                            TextField(
                              controller: newPasswordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: 'New Password',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            SizedBox(height: 15),
                          ],
                        ),
                        TextField(
                          controller: confirmPasswordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 15),
                        ElevatedButton(
                          onPressed: _changePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            minimumSize: Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text('Change Password', style: TextStyle(color: Colors.white, fontSize: 15)),
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              minimumSize: Size(100, 45),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              )),
                          child: Text(
                            'Return',
                            style: TextStyle(color: Colors.white, fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyTextField(String label, String value) {
    return TextFormField(
      initialValue: value,
      enabled: false,
      decoration: InputDecoration(
        labelText: label,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildEditableTextField(String label, String value, Function onTap) {
    return TextFormField(
      controller: phoneController..text = value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(Icons.edit),
          onPressed: () => onTap(),
        ),
      ),
    );
  }

  Future<void> _edit(String field, String currentValue) async {
    TextEditingController controller = TextEditingController(text: currentValue);
  }
}
