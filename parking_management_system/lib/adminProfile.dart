import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:parking_management_system/adminEditPackagesBought.dart';
import 'package:parking_management_system/login.dart';

class AdminProfilePage extends StatefulWidget {
  final String adminId;

  AdminProfilePage({required this.adminId});

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

  TextEditingController phoneController = TextEditingController();

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
          adminUsername = data['admin_username'] ?? '';
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

  void _logout(BuildContext context) async{
    try{
      //Sign out from Firebase Authentication
      await FirebaseAuth.instance.signOut();

      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }catch(e){
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
          leading: IconButton(
            icon: Icon(Icons.menu, color: Colors.black),
            onPressed: () {
              //Handle menu press
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
                items: <String>['Logout'].map((String value){
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? value){
                  if(value == 'Profile'){
                    Navigator.push(
                      context, 
                      MaterialPageRoute(
                        builder: (context) => AdminProfilePage(adminId: widget.adminId),
                      ),
                    );
                  }else if(value == 'Logout'){
                    _logout(context);
                  }
                },
              )
            ),
          ],
        ),
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
                          radius: 50,
                          backgroundColor: Colors.red,
                          backgroundImage: adminProfilePicture.isNotEmpty
                              ? NetworkImage(adminProfilePicture)
                              : null,
                          child: adminProfilePicture.isEmpty
                              ? Icon(Icons.person, color: Colors.black, size: 50)
                              : null,
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
                         _buildActionButton('Return', (){
                          Navigator.pop(context);
                        }),
                      ],
                    ),
                  ),
                  // Edit Profile Tab
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.red,
                          child: Icon(Icons.person, color: Colors.black, size: 50),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          adminUsername.isEmpty ? 'Admin Name' : adminUsername,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                         const SizedBox(height: 15),

                        _buildReadOnlyTextField('First Name', adminFirstName),
                        const SizedBox(height: 15),

                        _buildReadOnlyTextField('Last Name', adminLastName),
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
                              _saveChanges('phone_number', newPhoneNumber);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(horizontal: 144, vertical: 14),
                            shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text('Save Changes', style: TextStyle(color: Colors.white)),
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

  Future<void> _edit(String field, String currentValue) async{
    TextEditingController controller = TextEditingController(text: currentValue);
  }

  Widget _buildActionButton(String label, VoidCallback onPressed){
    return ElevatedButton(
      onPressed: onPressed, 
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(label, style: TextStyle(color: Colors.white)),
    );
  }

  void _saveChanges(String field, String newValue) {
    // Here you can handle saving the changes to Firebase or any other storage
    print('Saving changes: $field = $newValue');
    FirebaseFirestore.instance
        .collection('admins')
        .doc(widget.adminId)
        .update({field: newValue});
  }
}