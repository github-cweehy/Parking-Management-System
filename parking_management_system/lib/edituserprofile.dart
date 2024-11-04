import 'package:flutter/material.dart';

class EditUserProfile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/logomelaka.jpg',
          height: 40,
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15.0),
            child: DropdownButton<String>(
              underline: SizedBox(),
              icon: Row(
                children: [
                  Text("UserName"),
                  Icon(Icons.arrow_drop_down),
                ],
              ),
              items: <String>['Profile', 'Logout'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (_) {},
            ),
          ),
        ],
      ),
      drawer: Drawer(), // Add your drawer here if needed
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              
              // Tab Bar for Profile and Vehicles
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          "Profile",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        Container(
                          height: 2,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          "Vehicles",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        Container(
                          height: 2,
                          color: Colors.transparent,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),

              // Profile Picture and Upload Button
              Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.red,
                    child: CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.red,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -10,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Add upload logic
                      },
                      icon: Icon(Icons.upload, color: Colors.white),
                      label: Text("Upload"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 30),

              // Text Fields for First Name, Last Name, Username, Phone Number
              ProfileTextField(labelText: 'First Name'),
              const SizedBox(height: 20),
              ProfileTextField(labelText: 'Last Name'),
              const SizedBox(height: 20),
              ProfileTextField(labelText: 'Username'),
              const SizedBox(height: 20),
              ProfileTextField(labelText: 'Phone Number'),
              
              const SizedBox(height: 30),

              // Save Changes Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Add save changes logic
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
              
              const SizedBox(height: 30),

              // Change Password Section
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Change your password',
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
              ),
              const SizedBox(height: 20),
              ProfileTextField(labelText: 'New Password', isPassword: true),
              const SizedBox(height: 20),
              ProfileTextField(labelText: 'Confirm New Password', isPassword: true),
              
              const SizedBox(height: 30),

              // Change Password Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Add change password logic
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Change Password',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),

              // Return Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Return',
                    style: TextStyle(fontSize: 18, color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileTextField extends StatelessWidget {
  final String labelText;
  final bool isPassword;

  ProfileTextField({required this.labelText, this.isPassword = false});

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: labelText,
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
