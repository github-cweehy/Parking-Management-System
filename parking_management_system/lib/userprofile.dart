import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:parking_management_system/favourite.dart';
import 'package:path/path.dart' as path;
import 'help.dart';
import 'history.dart';
import 'mainpage.dart';
import 'packages.dart';
import 'packageshistory.dart';
import 'rewards.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;

  UserProfilePage({required this.userId});

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  String vehicleRegistration = '';
  bool isDefault = false;
  String selectedVehicleType = 'Car';
  List<Map<String, dynamic>> vehicles = [];
  String? defaultVehicle;
  Map<String, dynamic>? userData;
  String? profileImageUrl;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // Function to pick image from gallery
  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      _uploadProfilePicture(image);
    }
  }

  // Function to upload image to Firebase Storage
  Future<void> _uploadProfilePicture(XFile image) async {
    try {
      String fileName = path.basename(image.path);
      FirebaseStorage storage = FirebaseStorage.instance;

      // Create a reference to Firebase Storage location
      Reference storageRef = storage.ref().child('profile_pictures/$fileName');

      // Upload the image to Firebase Storage
      UploadTask uploadTask = storageRef.putFile(File(image.path));

      // Get the download URL of the uploaded image
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // Now, store this URL in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({'profile_picture': downloadUrl});

      setState(() {
        profileImageUrl = downloadUrl;  // Update the UI with the new image URL
      });

      _showSnackBar("Profile picture updated successfully.");
    } catch (e) {
      print("Error uploading profile picture: $e");
      _showSnackBar("Failed to upload profile picture.");
    }
  }

  Future<void> _fetchUserData() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;

      if (data != null) {
        setState(() {
          userData = data;
          vehicles = List<Map<String, dynamic>>.from(data['vehicles'] ?? []);
          defaultVehicle = data['default_vehicle'];
          profileImageUrl = data['profile_picture'];
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  Future<void> edit(String field, String currentValue) async {
    TextEditingController controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit $field'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: 'Enter new $field'),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () async {
                String newValue = controller.text.trim();
                if (newValue.isNotEmpty) {
                  if (field == 'phone_number') {                    
                    if (!RegExp(r'^01\d{8,9}$').hasMatch(newValue)) {
                      _showSnackBar('Invalid phone number. It must start with 01 and be 10-11 digits long.');
                      return;
                    }
                    if (await _isPhoneNumberDuplicate(newValue)) {
                      _showSnackBar("This phone number is already in use.");
                      return;
                    }
                  }
                  
                  if ((field == 'first_name' || field == 'last_name') && !RegExp(r'^[a-zA-Z\s]+$').hasMatch(newValue)) {
                      _showSnackBar('$field must contain only letters.');
                      return;
                  }
                  try {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(widget.userId)
                        .update({field: newValue});
                    setState(() {
                      if (field == 'first_name') {
                        userData?['first_name'] = newValue;
                      } else if (field == 'last_name') {
                        userData?['last_name'] = newValue;
                      } else if (field == 'phone_number'){
                        userData?['phone_number'] = newValue;
                      }
                    });
                    Navigator.of(context).pop();
                  } catch (e) {
                    print("Error updating $field: $e");
                    _showSnackBar("Failed to update $field.");
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

Future<bool> _isPhoneNumberDuplicate(String phoneNumber) async {
  try {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('phone_number', isEqualTo: phoneNumber)
        .get();
    return querySnapshot.docs.isNotEmpty;
  } catch (e) {
    print("Error checking for duplicate phone number: $e");
    return false; // Assume no duplicates on error
  }
}

Future<void> _addVehicle(String registrationNumber, bool isDefault) async {
  final RegExp platePattern = RegExp(r'^[A-Za-z]{3}\s\d{1,4}$');

  if (!platePattern.hasMatch(registrationNumber)) {
    _showSnackBar('Please enter a valid registration plate (e.g., ABC 123).');
    return;
  }

  bool isDuplicate = vehicles.any((vehicle) => vehicle['registrationNumber'] == registrationNumber);
  if (isDuplicate) {
    _showSnackBar('This registration number already exists.');
    return;
  }

  try {
    DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(widget.userId);
    Map<String, dynamic> newVehicle = {
      'registrationNumber': registrationNumber,
      'type': selectedVehicleType
    };
    vehicles.add(newVehicle);

    await userDoc.update({
      'vehicles': vehicles,
      'default_vehicle': isDefault ? registrationNumber : defaultVehicle,
    });

    setState(() {
      if (isDefault) {
        defaultVehicle = registrationNumber;
      }
      vehicleRegistration = '';
      this.isDefault = false;
    });
  } catch (e) {
    print("Error adding vehicle: $e");
  }
}

Future<void> _deleteVehicle(String registrationNumber) async {
  try {
    DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(widget.userId);
    setState(() {
      vehicles.removeWhere((vehicle) => vehicle['registrationNumber'] == registrationNumber);
      if (defaultVehicle == registrationNumber) {
        defaultVehicle = vehicles.isNotEmpty ? vehicles[0]['registrationNumber'] : null;
      }
    });

    await userDoc.update({
      'vehicles': vehicles,
      'default_vehicle': defaultVehicle,
    });
  } catch (e) {
    print("Error deleting vehicle: $e");
  }
}

void _setDefaultVehicle(String registrationNumber) async {
  try {
    DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(widget.userId);
    await userDoc.update({'default_vehicle': registrationNumber});

    setState(() {
      defaultVehicle = registrationNumber;
    });
  } catch (e) {
    print("Error setting default vehicle: $e");
  }
}

  // Function to show snack bar with messages
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void showPasswordChangeDialog(){
    TextEditingController currentPasswordController = TextEditingController();
    TextEditingController newPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isNewPasswordVisible = false;

    showDialog(
      context: context, 
      builder: (context){
        return AlertDialog(
          title: Text('Change Password'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentPasswordController,
                  obscureText: false,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your current password';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 15),

                TextFormField(
                  controller: newPasswordController,
                  obscureText: !isNewPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 12 || value.length > 15) {
                      return 'at least 12-15 characters';
                    }
                    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$&*~]).{12,15}$').hasMatch(value)) {
                      return 'at least 1 uppercase & lowercase,\n'
                             '1 number, and 1 special character';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (){
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    await changePassword(
                      currentPasswordController.text.trim(),
                      newPasswordController.text.trim(),
                    );
                  }
                }, 
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Change',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      // Fetch the current password from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        if (data['password'] == currentPassword) {
          // Update the password in Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .update({'password': newPassword});

          _showSnackBar("Password updated successfully.");
          Navigator.pop(context); // Close the dialog
        } else {
          _showSnackBar("Current password is incorrect.");
        }
      }
    } catch (e) {
      print("Error changing password: $e");
      _showSnackBar("Failed to update password.");
    }
  }

  @override
  Widget build(BuildContext context) {
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
              },
            ),
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
                  mainAxisAlignment: MainAxisAlignment.center,
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
                leading: Icon(Icons.home, color: Colors.red),
                title: Text('Home Page', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MainPage(
                        userId: widget.userId,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.history, color: Colors.red,),
                title: Text('Parking History', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HistoryPage(userId: widget.userId),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.favorite, color: Colors.red),
                title: Text('Favorite', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FavouritePage(userId: widget.userId),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.local_grocery_store_outlined, color: Colors.red),
                title: Text('Packages', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PackagesPage(userId: widget.userId),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.work_history_outlined, color: Colors.red),
                title: Text('Packages History', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PackagesHistoryPage(userId: widget.userId),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.celebration_rounded, color: Colors.red),
                title: Text('Your Rewards', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FreeParkingRewardsPage(userId: widget.userId),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.help_outline_sharp, color: Colors.red),
                title: Text('Help Center', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HelpPage(userId: widget.userId),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            TabBar(
              indicatorColor: Colors.red,
              tabs: [
                Tab(child: Text("Profile", style: TextStyle(color: Colors.black))),
                Tab(child: Text("Vehicles", style: TextStyle(color: Colors.black))),
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
                        GestureDetector(
                          onTap: _pickImage,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.red,
                            backgroundImage: profileImageUrl != null
                                ? NetworkImage(profileImageUrl!)
                                : null,
                            child: profileImageUrl == null
                                ? Icon(Icons.person, color: Colors.black, size: 50)
                                : null,
                          ),
                        ),
                        SizedBox(height: 10),

                        Text(
                          userData?['username'] ?? "User's Name",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),

                        // First Name
                        _buildEditableTextField('First Name', userData?['first_name'],(){
                          edit('first_name', userData?['first_name'] ?? '');
                        }),
                        const SizedBox(height: 10),

                        // Last Name
                        _buildEditableTextField('Last Name', userData?['last_name'], () {
                          edit('last_name', userData?['last_name'] ?? '');
                        }),
                        const SizedBox(height: 10),

                        // Username
                        _buildReadOnlyTextField('Username', userData?['username']),
                        const SizedBox(height: 10),

                        // Email
                        _buildReadOnlyTextField('Email', userData?['email']),
                        const SizedBox(height: 10),

                        // Phone Number
                        _buildEditableTextField('Phone Number', userData?['phone_number'], () {
                          edit('phone_number', userData?['phone_number'] ?? '');
                        }),                        
                        const SizedBox(height: 20),

                        // Return Button
                        _buildActionButton('Return', () {
                          Navigator.pop(context);
                        }),

                        const SizedBox(height: 20),

                        // Change Password Button
                        _buildActionButton('Change Password', () {
                          showPasswordChangeDialog();
                        }),
                      ],
                    ),
                  ),

                  // Vehicles Tab
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Select your default vehicle registration plate",
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 15),

                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: vehicles.map((vehicle) {
                            String registrationNumber = vehicle['registrationNumber'];
                            bool isSelected = registrationNumber == defaultVehicle;
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ChoiceChip(
                                  label: Column(
                                    children: [
                                      Text(
                                        registrationNumber,
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        vehicle['type'],
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : Colors.black54,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  selected: isSelected,
                                  onSelected: (_) => _setDefaultVehicle(registrationNumber),
                                  selectedColor: Colors.red,
                                  backgroundColor: Colors.grey[200],
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  color: Colors.red,
                                  onPressed: () {
                                    _deleteVehicle(registrationNumber);
                                  },
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 25),

                        Text(
                          "Choose vehicle type",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),

                        DropdownButtonFormField<String>(
                          value: selectedVehicleType,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: ['Car', 'Motorcycle', 'Van', 'Bus', 'Truck'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              selectedVehicleType = newValue!;
                            });
                          },
                        ),
                        const SizedBox(height: 20),

                        Text(
                          "Add your vehicle registration plate",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Enter registration plate',
                            hintStyle: TextStyle(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              vehicleRegistration = value;
                            });
                          },
                        ),
                        const SizedBox(height: 10),

                        // Default Vehicle Checkbox
                        Row(
                          children: [
                            Text("Set as default vehicle"),
                            Checkbox(
                              value: isDefault,
                              onChanged: (bool? value) {
                                setState(() {
                                  isDefault = value!;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Add Vehicle Button
                        Center(
                          child: ElevatedButton(
                            onPressed: () {
                              _addVehicle(vehicleRegistration.trim(), isDefault);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            ),
                            child: Text(
                              'Add Vehicle',
                              style: TextStyle(fontSize: 17, color: Colors.white),
                            ),
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

Widget _buildEditableTextField(String label, String? value, VoidCallback onEdit) {
  return TextField(
    readOnly: true,
    decoration: InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey[200],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      suffixIcon: IconButton(
        icon: Icon(Icons.edit, color: Colors.red),
        onPressed: onEdit,
      ),
    ),
    controller: TextEditingController(text: value ?? ''),
  );
}

  Widget _buildReadOnlyTextField(String label, String? value) {
    return TextField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      controller: TextEditingController(text: value ?? ''),
    );
  }

  Widget _buildActionButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
      ),
      child: Text(
        label,
        style: 
          TextStyle(
            color: Colors.white,), 
        ),
    );
  }
}
                      
