import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:parking_management_system/adminMainPage.dart';
import 'package:parking_management_system/parkingreceipt.dart';
import 'package:parking_management_system/sa.manageaccount.dart';
import 'adminCustomerList.dart';
import 'adminEditPackagesBought.dart';
import 'adminEditParkingSelection.dart';
import 'adminHelp.dart';
import 'adminPBHistory.dart';
import 'adminPBTransactionHistory.dart';
import 'adminPSTransactionHistory.dart';
import 'adminProfile.dart';
import 'adminReward.dart';
import 'login.dart';

class ParkingSelectionHistoryPage extends StatefulWidget {
  final String? superadminId;
  final String? adminId;

  ParkingSelectionHistoryPage({required this.superadminId, required this.adminId});

  @override
  _ParkingSelectionHistoryPageState createState() => _ParkingSelectionHistoryPageState();
}

class _ParkingSelectionHistoryPageState extends State<ParkingSelectionHistoryPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String admin_username = '';

  DateTime startTime = DateTime.now();
  DateTime endTime = DateTime.now();
  
  final Map<String, String> _usernameCache = {};

   Future<String> _fetchUsername(String userId) async {
    if (_usernameCache.containsKey(userId)) {
      return _usernameCache[userId]!;
    }

    try {
      DocumentSnapshot userSnapshot = await _firestore.collection('users').doc(userId).get();
      if (userSnapshot.exists) {
        String username = userSnapshot['username'] ?? 'Unknown User';
        _usernameCache[userId] = username;
        return username;
      } else {
        return 'Unknown User';
      }
    } catch (e) {
      print('Error fetching username for userId $userId: $e');
      return 'Unknown User';
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchSuperAdminUsername();
    _fetchAdminUsername();
  }

  // Fetch admin username from Firebase
  void _fetchSuperAdminUsername() async {
    try {
      DocumentSnapshot snapshot = await _firestore.collection('superadmin').doc(widget.superadminId).get();
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

  Stream<QuerySnapshot> getFilteredData() {
    return _firestore.collection('history parking').snapshots();
  }

  void _selectDate(BuildContext context, bool isStartDate) async {
    List<DateTime> availableDates = await getAvailableDates();

    if (availableDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No available dates to select.")),
      );
      return;
    }

    DateTime initialDate = availableDates.firstWhere(
      (date) => date.year == startTime.year && date.month == startTime.month && date.day == startTime.day,
      orElse: () => availableDates.first, 
    );

     final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate, 
      firstDate: availableDates.reduce((a, b) => a.isBefore(b) ? a : b),
      lastDate: availableDates.reduce((a, b) => a.isAfter(b) ? a : b),
      selectableDayPredicate: (date) {

        return availableDates.any((availableDate) =>
            availableDate.year == date.year &&
            availableDate.month == date.month &&
            availableDate.day == date.day);
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          startTime = DateTime(picked.year, picked.month, picked.day);

          if (endTime.isBefore(startTime)) {
            endTime = DateTime(startTime.year, startTime.month, startTime.day, 23, 59, 59); 
          } 
        } 
        else {
          endTime = DateTime(picked.year, picked.month, picked.day, 23, 59, 59); 
          if (startTime.isAfter(endTime)) {
            startTime = DateTime(endTime.year, endTime.month, endTime.day); 
          }
        }
      });
    }
  }

  Future<List<DateTime>> getAvailableDates() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('history parking').get();

      List<DateTime> availableDates = snapshot.docs
          .map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            if (data.containsKey('startTime')) {
              var startTime = data['startTime'];

              if (startTime is String) {
                try {
                   return DateTime.parse(startTime);
                } catch (e) {
                  print('Error parsing date: $startTime in document ${doc.id}');
                  return null;
                }
              } 
              else if(startTime is Timestamp) {
                return startTime.toDate();
              }
              else {
                print('Warning: startTime is neither String nor Timestamp in document ${doc.id}');
                return null;
              }
            } 
            else {
              print('Warning: startTime field missing in document ${doc.id}');
              return null;
            }
          })
          .whereType<DateTime>()
          .toList();

      print('Available Dates: $availableDates'); 
      return availableDates;
    } catch (e) {
      print("Error fetching available dates: $e");
      return [];
    }
  }

  void _logout(BuildContext context) async {
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
              icon: Icon(Icons.menu, color: Colors.black),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              }),
        ),
        title: Image.asset('assets/logomelaka.jpg', height: 60),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButton<String>(
              underline: Container(),
              icon: Row(
                children: [
                  Text(admin_username, style: TextStyle(color: Colors.black)),
                  Icon(Icons.arrow_drop_down, color: Colors.black),
                ],
              ),
              items: [
                'Profile',
                'Logout'
              ].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? value) {
                if (value == 'Profile') {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminProfilePage(superadminId: widget.superadminId, adminId: widget.adminId),
                    ),
                  );
                } else if (value == 'Logout') {
                  _logout(context);
                }
              },
            ),
          ),
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
      body: Padding(
        padding: EdgeInsets.all(16.0),
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
                  "Parking Selection History",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Start Date Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 10.0),
                      child: Text("Start Date", style: TextStyle(fontSize: 13)),
                    ),
                    GestureDetector(
                      onTap: () => _selectDate(context, true),
                      child: Container(
                        width: 185,
                        height: 40,
                        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.calendar_month,
                              color: Colors.grey,
                              size: 20,
                            ),
                            SizedBox(width: 5),
                            Text(
                              "${startTime.day} ${_monthName(startTime.month)} ${startTime.year}",
                              style: TextStyle(color: Colors.black, fontSize: 13.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // End Date Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 10.0),
                      child: Text("End Date", style: TextStyle(fontSize: 13)),
                    ),
                    GestureDetector(
                      onTap: () => _selectDate(context, false),
                      child: Container(
                        width: 185,
                        height: 40,
                        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.calendar_month,
                              color: Colors.grey,
                              size: 20,
                            ),
                            SizedBox(width: 5),
                            Text(
                              "${endTime.day} ${_monthName(endTime.month)} ${endTime.year}",
                              style: TextStyle(color: Colors.black, fontSize: 13.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
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
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: getFilteredData(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Center(child: CircularProgressIndicator());
                        }

                        final docs = snapshot.data!.docs;

                        // Filtering data and parsing time
                        final filteredDocs = docs.where((doc) {
                          var data = doc.data() as Map<String, dynamic>;

                          DateTime docStartTime;
                          DateTime docEndTime;

                          if (data['startTime'] is String) {
                            docStartTime = DateTime.parse(data['startTime']);
                          } else if (data['startTime'] is Timestamp) {
                            docStartTime = (data['startTime'] as Timestamp).toDate();
                          } else {
                            return false; 
                          }

                          if (data['endTime'] is String) {
                            docEndTime = DateTime.parse(data['endTime']);
                          } else if (data['endTime'] is Timestamp) {
                            docEndTime = (data['endTime'] as Timestamp).toDate();
                          } else {
                            return false; 
                          }

                          return docStartTime.isAfter(startTime) && docEndTime.isBefore(endTime);
                        }).toList();

                        //Sort filteredDocs by startTime in descending order (newest first)
                        filteredDocs.sort((a, b) {
                          var aData = a.data() as Map<String, dynamic>;
                          var bData = b.data() as Map<String, dynamic>;

                          DateTime aStartTime = aData['startTime'] is String
                            ? DateTime.parse(aData['startTime'])
                            : (aData['startTime'] as Timestamp).toDate();

                          DateTime bStartTime = bData['startTime'] is String
                            ? DateTime.parse(bData['startTime'])
                            : (bData['startTime'] as Timestamp).toDate();

                          return bStartTime.compareTo(aStartTime); // Descending order
                        });

                        if (filteredDocs.isEmpty) {
                          return Center(child: Text("No data available."));
                        }

                        return ListView.builder(
                          itemCount: filteredDocs.length,
                          itemBuilder: (context, index) {
                            var record = filteredDocs[index];
                            var data = record.data() as Map<String, dynamic>;

                            if (!data.containsKey('username')) {
                              return SizedBox.shrink();
                            }

                            var username = data['username'] ?? 'Anonymous';
                            var pricingOption = data['pricingOption'] ?? 'Unknown';
                            var price = double.tryParse(data['price'].toString()) ?? 0.0;

                            DateTime startTime;
                            if (data['startTime'] is String) {
                              startTime = DateTime.parse(data['startTime']);
                            } else if (data['startTime'] is Timestamp) {
                              startTime = (data['startTime'] as Timestamp).toDate();
                            } else {
                              startTime = DateTime.now();
                            }

                            DateTime endTime;
                            if (data['endTime'] is String) {
                              endTime = DateTime.parse(data['endTime']);
                            } else if (data['endTime'] is Timestamp) {
                              endTime = (data['endTime'] as Timestamp).toDate();
                            } else {
                              endTime = DateTime.now();
                            }

                            String formattedStartDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(startTime);
                            String formattedEndDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(endTime);

                            return Card(
                              color: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: Colors.red, width: 1),
                              ),
                              margin: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            username,
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'Packages: $pricingOption',
                                            style: TextStyle(
                                              fontSize: 15,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            'RM ${price.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.download, color: Colors.white),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ParkingReceiptPage(
                                              district: data['location'],
                                              startTime: formattedStartDate,
                                              endTime: formattedEndDate,
                                              amount: double.tryParse(data['price'] ?? '0') ?? 0,
                                              type: data['pricingOption'] ?? 'N/A',
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    )
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int month) {
    List<String> monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return monthNames[month - 1];
  }
}