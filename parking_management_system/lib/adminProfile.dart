import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminProfilePage extends StatefulWidget {
  final String adminId;

  AdminProfilePage({required this.adminId});

  @override
  _AdminProfilePageState createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  String vehicleRegistration = '';
  bool isDefault = false;
  String selectedVehicleType = 'Car';
  List<Map<String, dynamic>> vehicles = [];
  String? defaultVehicle;
  Map<String, dynamic>? adminData;

  @override
  void initState() {
    super.initState();
    _fetchAdminData();
  }

  Future<void> _fetchAdminData() async {
    try {
      DocumentSnapshot adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(widget.adminId)
          .get();
      Map<String, dynamic>? data = adminDoc.data() as Map<String, dynamic>?;

      if (data != null) {
        setState(() {
          adminData = data;
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
                  if (field == 'phone_number' && await _isPhoneNumberDuplicate(newValue)) {
                    _showSnackBar("This phone number is already in use.");
                    return;
                  }
                  try {
                    await FirebaseFirestore.instance
                        .collection('admins')
                        .doc(widget.adminId)
                        .update({field: newValue});
                    setState(() {
                      adminData?[field] = newValue;
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
          .collection('admins')
          .where('phone_number', isEqualTo: phoneNumber)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print("Error checking for duplicate phone number: $e");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Admin Profile'),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Text(adminData?['admin_username'] ?? '', style: TextStyle(color: Colors.black)),
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
                Tab(text: "Profile"),
                Tab(text: "Vehicles"),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Profile Tab
                  _buildProfileTab(),
                  // Vehicles Tab
                  _buildVehiclesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          CircleAvatar(radius: 50, backgroundColor: Colors.red),
          const SizedBox(height: 10),
          Text(adminData?['username'] ?? "User's Name", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildEditableTextField('First Name', adminData?['first_name'], () => _edit('first_name', adminData?['first_name'] ?? '')),
          const SizedBox(height: 10),
          _buildEditableTextField('Last Name', adminData?['last_name'], () => _edit('last_name', adminData?['last_name'] ?? '')),
          const SizedBox(height: 10),
          _buildReadOnlyTextField('Username', adminData?['username']),
          const SizedBox(height: 10),
          _buildReadOnlyTextField('Email', adminData?['email']),
          const SizedBox(height: 10),
          _buildEditableTextField('Phone Number', adminData?['phone_number'], () => _edit('phone_number', adminData?['phone_number'] ?? '')),
        ],
      ),
    );
  }

  Widget _buildVehiclesTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text("Select your default vehicle registration plate", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: vehicles.map((vehicle) {
              String registrationNumber = vehicle['registrationNumber'];
              bool isSelected = registrationNumber == defaultVehicle;
              return ChoiceChip(
                label: Text(registrationNumber),
                selected: isSelected,
                onSelected: (_) => _setDefaultVehicle(registrationNumber),
                selectedColor: Colors.red,
                backgroundColor: Colors.grey[200],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableTextField(String label, String? value, VoidCallback onTap) {
    return ListTile(
      title: Text(label),
      subtitle: Text(value ?? ''),
      trailing: Icon(Icons.edit),
      onTap: onTap,
    );
  }

  Widget _buildReadOnlyTextField(String label, String? value) {
    return ListTile(
      title: Text(label),
      subtitle: Text(value ?? ''),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  Future<void> _setDefaultVehicle(String registrationNumber) async {
    try {
      await FirebaseFirestore.instance.collection('admins').doc(widget.adminId).update({'default_vehicle': registrationNumber});
      setState(() {
        defaultVehicle = registrationNumber;
      });
    } catch (e) {
      print("Error setting default vehicle: $e");
    }
  }
}
