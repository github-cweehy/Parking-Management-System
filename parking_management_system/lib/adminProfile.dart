import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminProfilePage extends StatelessWidget {
  Future<Map<String, dynamic>?> _fetchAdminData() async {

    final snapshot = await FirebaseFirestore.instance
        .collection('admin')
        .doc('adminId') // 替换为实际的管理员 ID
        .get();
    return snapshot.data();
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
              // handle menu press
            },
          ),
          
          title: Image.asset(
            'assets/logomelaka.jpg',
            height: 60,
          ),

          bottom: TabBar(
            indicatorColor: Colors.red,
            tabs: [
              Tab(
                child: Text(
                  "Profile",
                  style: TextStyle(color: Colors.black),
                ),
              ),

              Tab(
                child: Text(
                  "Edit Profile",
                  style: TextStyle(color: Colors.black),
                ),
              )
            ],
          ),
        ),

        body: FutureBuilder<Map<String, dynamic>?>(
          future: _fetchAdminData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error fetching admin data."));
            }
            if (!snapshot.hasData || snapshot.data == null) {
              return Center(child: Text("No admin data found."));
            }

            final adminData = snapshot.data!;
            return TabBarView(
              children: [
                // Profile Tab
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Profile Avatar (picture)
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.red,
                        child: Icon(Icons.person, color: Colors.black, size: 50),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        adminData['admin_username'] ?? "Admin Username",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),

                      // Display Admin Username (read-only)
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Admin Username',
                          filled: true,
                          fillColor: Colors.grey[300],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        controller: TextEditingController(text: adminData['admin_username']),
                        readOnly: true,
                      ),
                      const SizedBox(height: 10),

                      // Display First Name
                      TextField(
                        decoration: InputDecoration( 
                          labelText: 'First Name',
                          filled: true,
                          fillColor: Colors.grey[300],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        controller: TextEditingController(text: adminData['first_name']),
                        readOnly: true,
                      ),
                      const SizedBox(height: 10),

                      // Display Last Name
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Last Name',
                          filled: true,
                          fillColor: Colors.grey[300],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        controller: TextEditingController(text: adminData['last_name']),
                        readOnly: true,
                      ),
                      const SizedBox(height: 10),

                      // Display Email
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Email',
                          filled: true,
                          fillColor: Colors.grey[300],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        controller: TextEditingController(text: adminData['email']),
                        readOnly: true,
                      ),
                      const SizedBox(height: 10),

                      // Display Phone Number
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          filled: true,
                          fillColor: Colors.grey[300],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        controller: TextEditingController(text: adminData['phone_number']),
                        readOnly: true,
                      ),
                      const SizedBox(height: 10),

                      // Return Button
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Return',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),

                // Edit Profile Tab
                Center(
                  child: Text("Edit Profile - To be implemented"),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}