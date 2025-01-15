import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:parking_management_system/adminMainPage.dart';
import 'package:parking_management_system/adminProfile.dart';
import 'adminCustomerList.dart';
import 'adminEditParkingSelection.dart';
import 'adminHelp.dart';
import 'adminPBHistory.dart';
import 'adminPBTransactionHistory.dart';
import 'adminPSHistory.dart';
import 'adminPSTransactionHistory.dart';
import 'adminReward.dart';
import 'login.dart';
import 'sa.manageaccount.dart';


class EditPackagesBoughtPage extends StatefulWidget {
  final String? adminId;
  final String? superadminId;

  EditPackagesBoughtPage({required this.superadminId, required this.adminId});

  @override
  _EditPackagesBoughtPageState createState() => _EditPackagesBoughtPageState();
}

class _EditPackagesBoughtPageState extends State<EditPackagesBoughtPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String admin_username = '';

  List<Map<String, dynamic>> monthly = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRatesFromFirebase();
    _fetchSuperAdminUsername();
    _fetchAdminUsername();
  }

  // Fetch admin username from Firebase
  void _fetchSuperAdminUsername() async {
    try {
      DocumentSnapshot snapshot =
          await _firestore.collection('superadmin').doc(widget.superadminId).get();
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

  // Fetch rates data from Firebase
  void _fetchRatesFromFirebase() async {
    setState(() {
      isLoading = true;
    });
    try {
      List<Map<String, dynamic>> rates = [];
      QuerySnapshot querySnapshot = await _firestore.collection('packagesprice').get();

      for (var doc in querySnapshot.docs) {
        String duration = doc.id;
          rates.add({
            'duration': duration.replaceAll('-', ' ').split(' ').map((word) => word[0].toUpperCase() + word.substring(1)).join(' '),
            'price': doc['price'].toDouble(),
            'docId': doc.id,
          });
      }
      //follow numeric Value to arrange
       rates.sort((a, b) {
        int extractNumericValue(String duration) {
          final numericValue = RegExp(r'\d+').stringMatch(duration);
          return numericValue != null ? int.parse(numericValue) : 0;
        }

        return extractNumericValue(a['duration']).compareTo(extractNumericValue(b['duration']));
      });

      setState(() {
        monthly = rates;
      });
    } catch (e) {
      print("Error fetching rates: $e");
    }
    finally{
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showAddPackageDialog(){
    TextEditingController durationController = TextEditingController();
    TextEditingController priceController = TextEditingController();

    showDialog(
      context: context, 
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Add New Packages"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: durationController,
                decoration: InputDecoration(labelText: "Duration (e.g., 1-month)"),
              ),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Price"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: (){
                Navigator.of(context).pop();
              }, 
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: (){
                String duration = durationController.text;
                double?  price = double.tryParse(priceController.text);

                if(duration.isNotEmpty && price != null) {
                  setState(() {
                    monthly.add({
                      'duration': duration,
                      'price': price,
                      'docId': duration.replaceAll(' ', '-').toLowerCase(),
                    });
                  });
                   _addPackageToFirebase(duration, price);

                   Navigator.of(context).pop();
                }
                else{
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter valid data.'),
                  ));
                }
              }, 
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, 
              ),
              child: Text("Add", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      }
    );
  }

  //add packages
  void _addPackageToFirebase(String duration, double price) async{
    try{
      String docId = duration.replaceAll(' ', '-').toLowerCase();

      await _firestore.collection('packagesprice').doc(docId).set({
        'price': price,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('New package added succesfully!')));
      
      _fetchRatesFromFirebase();
    }catch(e){
      print("Error adding package: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding new package. Please try again.')));
    }
  }

  //delete packages
  void _deletePackages(String docId, int index) async{
    try{
      await _firestore.collection('packagesprice').doc(docId).delete();

      setState(() {
        monthly.removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Package deleted successfully!'))
      );
    }catch(e){
      print("Error deleting package: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting package. Please try again!'))
      );
    }
  }

  // Save changes to Firebase
  void saveChanges() async {
    try {
      for (var rate in monthly) {
        await _firestore.collection('packagesprice').doc(rate['docId']).update({
          'price': rate['price'],
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Prices saved successfully!')));
    } catch (e) {
      print("Error saving changes: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error saving changes. Please try again!")));
    }
  }

  // Show dialog to edit price
  void _showEditDialog(BuildContext context, int index) {
    TextEditingController priceController = TextEditingController(
      text: monthly[index]['price'].toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Edit Price for ${monthly[index]['duration']}"),
          content: TextField(
            controller: priceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Enter new price",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                showDialog(
                  context: context, 
                  builder: (BuildContext context){
                    return AlertDialog(
                      title: Text("Comfirm Delete"),
                      content: Text("Are you sure want to delete this packages?"),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          }, 
                          child: Text("Cancel"),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: (){
                            _deletePackages(monthly[index]['docId'], index);
                            
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Package deleted successfuly!")),
                            );
                          }, 
                          child: Text("Delete", style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    );
                  }
                );
              },
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                setState(() {
                  // Validate the price input is valid
                  double ? newPrice = double.tryParse(priceController.text);

                  if(newPrice != null){
                    monthly[index]['price'] = newPrice;
                  }
                });
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text("Save", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _logout(BuildContext context) async{
    try {
      // Sign out from Firebase Authentication
      await FirebaseAuth.instance.signOut();
      
      // Navigate to LoginPage and replace the current page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } catch (e) {
      // Handle any errors that occur during sign-out
      print("Error signing out: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out. Please try again.')),
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
            icon: Icon(Icons.menu, color:  Colors.black),
            onPressed: (){
              Scaffold.of(context).openDrawer();
            }
          ),
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
                    admin_username,
                    style: TextStyle(color: Colors.black),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: Colors.black,
                  ),
                ],
              ),
              items: <String>['Profile', 'Logout'].map((String value) {
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
                  // Navigate to profile
                  _logout(context);
                }
              },
            ),
          )
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
                if(widget.superadminId != null && widget.superadminId!.isNotEmpty) {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (context) => ManageAccountPage(superadminId: widget.superadminId, adminId: widget.adminId),
                    ),
                  );
                }
                else{
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
        )
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
                SizedBox(width: 10),
                Text(
                  "Edit Packages Bought",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 8),
            Expanded(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: Colors.grey.shade400, 
                        width: 1.0,       
                      ),
                      borderRadius: BorderRadius.circular(10), 
                    ),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _firestore.collection('packagesprice').snapshots(), 
                      builder: (context, snapshot){
                        if(!snapshot.hasData){
                          return Center(child: CircularProgressIndicator());
                        }

                        var packages = snapshot.data!.docs;
                        List<Widget> packageWidgets = [];

                        for(var package in packages){
                          var price = package['price'];
                        }

                        return ListView.builder(
                          itemCount: monthly.length,
                          padding: const EdgeInsets.all(8.0),
                          itemBuilder: (context, index) {
                            final rate = monthly[index];
                            return Card(
                              color: Colors.red,
                              margin: EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                leading: Icon(Icons.access_time, color: Colors.white),
                                title: Text(
                                  "${rate['duration']}",
                                  style: TextStyle(color: Colors.white),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "RM ",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(width: 3),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 1),
                                      child: Text(
                                        monthly[index]['price'].toStringAsFixed(2),
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.edit, color: Colors.white),
                                      onPressed: () async{
                                        _showEditDialog(context, index);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }
                    )
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed:(){
                _showAddPackageDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                fixedSize: Size(100, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Add',
                style: TextStyle(color: Colors.white, fontSize: 16)),
              
            ),

            ElevatedButton(
              onPressed: saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                fixedSize: Size(100, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ) // Background color
              ),
              child: Text(
                "Save",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}