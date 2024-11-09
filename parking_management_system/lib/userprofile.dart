import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchUserData();
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
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  Future<void> _edit(String field, String currentValue) async {
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
                  if (await _isPhoneNumberDuplicate(newValue)) {
                    _showSnackBar("This phone number is already in use.");
                    return;
                  }
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

void _showSnackBar(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
              child: Row(
                children: [
                  Text(
                    userData?['username'] ?? '',
                    style: TextStyle(color: Colors.black),
                  ),
                  Icon(Icons.arrow_drop_down, color: Colors.black),
                ],
              ),
            ),
          ],
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
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.red,
                          child: Icon(Icons.person, color: Colors.black, size: 50),
                        ),
                        const SizedBox(height: 10),

                        Text(
                          userData?['username'] ?? "User's Name",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),

                        // First Name
                        _buildEditableTextField('First Name', userData?['first_name'],(){
                          _edit('first_name', userData?['first_name'] ?? '');
                        }),
                        const SizedBox(height: 10),

                        // Last Name
                        _buildEditableTextField('Last Name', userData?['last_name'], () {
                          _edit('last_name', userData?['last_name'] ?? '');
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
                          _edit('phone_number', userData?['phone_numebr'] ?? '');
                        }),                        
                        const SizedBox(height: 20),

                        // Return Button
                        _buildActionButton('Return', () {
                          Navigator.pop(context);
                        }),

                        const SizedBox(height: 20),

                        // Change Password Button
                        _buildActionButton('Change Password', () {
                          // Handle password change
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
                      
