import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminProfilePage extends StatefulWidget{
  final String adminId;

  AdminProfilePage({required this.adminId});

  @override
  _AdminProfilePageState createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage>{
  Map<String, dynamic>? adminData;
  List<Map<String, dynamic> >editProfile = [];
  TextEditingController phoneController = TextEditingController();

  @override
  void initState(){
    super.initState();
    _fetchAdminData();
  }

  //to get admin data
  Future<void>_fetchAdminData() async{
    try{
      DocumentSnapshot adminDoc = await FirebaseFirestore.instance
      .collection('admins')
      .doc(widget.adminId)
      .get();

      Map<String, dynamic>? data = adminDoc.data() as Map<String, dynamic>?;

      if(data != null){
        setState((){
          adminData = data;
        });
      }
    } catch (e){
      print("Error fetching admin data: $e");
    }
  }

  Future<void>_edit(String field, String currentValue) async{
    TextEditingController controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (BuildContext context){
        return AlertDialog(
          title: Text('Edit $field'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: 'Enter new $field'),
          ),
          actions: [
            TextButton(
              child: Text('Return'),
              onPressed: (){
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () async{
                String newValue = controller.text.trim();
                if(newValue.isNotEmpty){
                  if(field == 'phone_number'){
                    if(await _isPhoneNumberDuplicate(newValue)){
                      _showSnackBar("Phone number already in use");

                      return;
                    }
                  }
                  try{
                    await FirebaseFirestore.instance
                    .collection('admins')
                    .doc(widget.adminId)
                    .update({field: newValue});

                    setState(() {
                      if(field == 'phone_number'){
                        adminData?['phone_number'] = newValue;
                      }
                    });
                    Navigator.of(context).pop();
                  }catch(e){
                    print("Error update $field: $e");
                    _showSnackBar("Failed to update $field");
                  }
                }
              },
            )
          ],
        );
      },
    );
  }

  Future<bool> _isPhoneNumberDuplicate(String phoneNumber) async{
    try{
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
      .collection('admin')
      .where('phone_number', isEqualTo: phoneNumber)
      .get();

      return querySnapshot.docs.isNotEmpty;
    }catch(e){
      print("Error check for the Duplicate Phone Number: $e");

      return false; //Assume no duplicates on error
    }
  }

  //Display alert message
  void _showSnackBar(String message){
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context){
    return DefaultTabController(
      length: 2, 
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.menu, color: Colors.black),
            onPressed: (){
              //Handle Navigator menu
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
                    adminData?['admin']??'',
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
                Tab(child: Text("Edit Profile", style: TextStyle(color: Colors.black))),
              ],
            ),

            //Tab Bar View
            Expanded(
              child: TabBarView(
                children: [ 
                  //Profile Tab
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
                          adminData?['Admin Username']?? "Admin Name",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),

                        //First name
                        _buildReadOnlyTextField('First Name', adminData?['first_name']),
                        const SizedBox(height: 10),

                        _buildReadOnlyTextField('Last Name', adminData?['last_name']),
                        const SizedBox(height: 10),

                        _buildReadOnlyTextField('Email', adminData?['email']),
                        const SizedBox(height: 10),

                        _buildEditableTextField('Phone Number', adminData?['phone_number'],(){
                          _edit('phone_number', adminData?['phone_number']?? '');
                        }),
                        const SizedBox(height: 10),

                        //Return Button
                        _buildActionButton('Return', (){
                          Navigator.pop(context);
                        }),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),


                  //Edit Profile Tab
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        //upload photo
                        /*GestureDetector()
                        CircleAvatar(
                          radius: 50,
                        )*/

                        //Display Admin Username
                        _buildReadOnlyTextField('Admin Username', adminData?['admin_username']),
                        const SizedBox(height: 10),

                        //Edit Phone Number
                        _buildEditableTextField('Phone Number', adminData?['phone_number'],(){
                          _edit('phone_number', adminData?['phone_number']?? '');
                        }),
                        const SizedBox(height: 20),

                        //Save change button
                        ElevatedButton(
                          onPressed: (){
                            String newPhoneNumber = phoneController.text.trim();
                            if(newPhoneNumber != adminData?['phone_number']) {
                              _saveChanges('phone_number', newPhoneNumber);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text('Save Changes', style: TextStyle(color: Colors.white)),
                        ),

                        //Change Password Button
                        _buildActionButton('Change Password', (){
                          //Handle Change Password
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      )
    );
  }

  Widget _buildEditableTextField(String label, String? value, VoidCallback onEdit){
    return TextField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[190],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      controller: TextEditingController(text: value?? ''),
    );
  }

  Widget _buildReadOnlyTextField(String label, String? value) {
    return TextField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[190],
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
      child: 
        Text(
          label,
          style: 
            TextStyle(
              color: Colors.white), 
        ),
    );
  }

  //Save Change
  void _saveChanges(String field, String newValue) async{
    try{
      await FirebaseFirestore.instance
      .collection('admins')
      .doc(widget.adminId)
      .update({field: newValue});

      setState(() {
        if(field == 'phone_number'){
          adminData?['phone_number'] = newValue;
        }
      });

      _showSnackBar("$field updated successfully");
    }catch(e){
      print("Error updating $field: $e");
      _showSnackBar("Failed to updated $field");
    }
  }
}



