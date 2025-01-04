import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:parking_management_system/adminMainPage.dart';
import 'package:parking_management_system/sa.manageaccount.dart';
import 'adminCustomerList.dart';
import 'adminEditPackagesBought.dart';
import 'adminEditParkingSelection.dart';
import 'adminHelp.dart';
import 'adminPBHistory.dart';
import 'adminPSHistory.dart';
import 'adminPSTransactionHistory.dart';
import 'adminProfile.dart';
import 'adminReward.dart';
import 'login.dart';

class PackagesBoughtTransactionHistoryPage extends StatefulWidget {
  final String? superadminId;
  final String? adminId;

  PackagesBoughtTransactionHistoryPage({required this.superadminId, required this.adminId});

  @override
  _PackagesBoughtTransactionHistoryPage createState() => _PackagesBoughtTransactionHistoryPage();
}

class _PackagesBoughtTransactionHistoryPage extends State<PackagesBoughtTransactionHistoryPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String admin_username = '';
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();

  Timestamp? startTimestamp;
  Timestamp? endTimestamp;

  final Map<String, String> _usernameCache = {};
  Future<String> _fetchUsername(String userId) async {
    if (_usernameCache.containsKey(userId)) {
      return _usernameCache[userId]!;
    }

    try {
      DocumentSnapshot userSnapshot = await _firestore.collection('users').doc(userId).get();
      if (userSnapshot.exists) {
        String username = userSnapshot['username'] ?? 'Unknown User';
        setState(() {
          _usernameCache[userId] = username;
        });

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
    _fetchAllUsernames();
    startTimestamp = Timestamp.fromDate(startDate);
    endTimestamp = Timestamp.fromDate(endDate);
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

  //Load all user data at once
  void _fetchAllUsernames() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('users').get();
      setState(() {
        _usernameCache.addEntries(
          snapshot.docs.map((doc) => MapEntry(doc.id, doc['username'] ?? 'Unknown User')),
        );
      });
    } catch (e) {
      print("Error fetching usernames: $e");
    }
  }

  Stream<QuerySnapshot> getFilteredData() {
    if (startTimestamp != null && endTimestamp != null) {
      return _firestore.collection('transactions').where('timestamp', isGreaterThanOrEqualTo: startTimestamp).where('timestamp', isLessThanOrEqualTo: endTimestamp).snapshots();
    } 
    else {
      return _firestore.collection('transactions').snapshots();
    }
  }

  //selected date
  void _selectDate(BuildContext context, bool isStartDate) async {
    List<DateTime> availableDates = await getAvailableDates();

    if (availableDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No available dates to select.")),
      );

      return;
    }

    DateTime minDate = availableDates.reduce((a, b) => a.isBefore(b) ? a : b);
    DateTime maxDate = availableDates.reduce((a, b) => a.isAfter(b) ? a : b);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: availableDates.first,
      firstDate: minDate,
      lastDate: maxDate,
      selectableDayPredicate: (date) {
        return availableDates.contains(DateTime(date.year, date.month, date.day));
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          startDate = DateTime(picked.year, picked.month, picked.day); // 设置时间为 00:00:00
          startTimestamp = Timestamp.fromDate(startDate);
        } 
        else {
          endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59); // 设置时间为 23:59:59
          endTimestamp = Timestamp.fromDate(endDate);
        }
      });
    }
  }

  Future<List<DateTime>> getAvailableDates() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('transactions').get();

      List<DateTime> availableDates = snapshot.docs.map((doc) {
        Timestamp timestamp = doc['timestamp'];
        return DateTime(timestamp.toDate().year, timestamp.toDate().month, timestamp.toDate().day);
      }).toList();

      // prevent duplicate date
      return availableDates.toSet().toList();
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
        title: Image.asset(
          'assets/logomelaka.jpg',
          height: 60,
        ),
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
              items: <String>[
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
                  "Packages Bought Transaction History",
                  style: TextStyle(
                    fontSize: 18,
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
                              "${startDate.day} ${_monthName(startDate.month)} ${startDate.year}",
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
                              "${endDate.day} ${_monthName(endDate.month)} ${endDate.year}",
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
                      color: Colors.grey.shade200,
                      border: Border.all(
                        color: Colors.grey.shade400,
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: getFilteredData(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(child: Text(startTimestamp != null && endTimestamp != null ? 'No data found for the selected date.' : 'No records available.'));
                        }

                        var transactions = snapshot.data!.docs;

                        return ListView.builder(
                          padding: const EdgeInsets.all(8.0),
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            var transaction = transactions[index];
                            var userId = transaction['userId'];
                            var username = _usernameCache[userId] ?? 'Unknown User';
                            var transactionId = transaction.id;
                            var package = transaction['packages']; //transactions packages
                            Timestamp timestamp = transaction['timestamp'];
                            var packageId = transaction['packages']; //history package
                            var payment = transaction['paymentMethod'];
                            final price = transaction['amount'].toStringAsFixed(2) ?? 0.0;

                            //Determine if packages is null
                            if (package == null) {
                              return SizedBox.shrink();
                            }

                            return FutureBuilder<DocumentSnapshot>(
                              future: _firestore.collection('packages_bought').doc(packageId).get(),
                              builder: (context, packageSnapshot) {
                                if (packageSnapshot.connectionState == ConnectionState.waiting) {
                                  return CircularProgressIndicator();
                                }
                                if (packageSnapshot.hasError) {
                                  return Text('Error fetching parking details');
                                }
                                if (!packageSnapshot.hasData || !packageSnapshot.data!.exists) {
                                  return SizedBox.shrink();
                                }

                                //Get startTime endTime from packages_bought
                                var packageData = packageSnapshot.data!;
                                Timestamp startTimestamp = packageData['startDate'];
                                Timestamp endTimestamp = packageData['endDate'];

                                //String convert to DateTime &(packages_bought)duration (transactions packagesId)
                                DateTime startDate = startTimestamp.toDate().add(Duration(hours: 8));
                                DateTime endDate = endTimestamp.toDate().add(Duration(hours: 8));
                                String duration = packageData['duration'] ?? 'Not available';
                                String PlateNum = packageData['vehiclePlate'] ?? 'Not available';

                                //format datetime
                                String formatStartTime = DateFormat('d MMM yyyy h:mm a').format(startDate);
                                String formatEndTime = DateFormat('d MMM yyyy h:mm a').format(endDate);

                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.grey.shade400, width: 1.0),
                                  ),
                                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '@$username',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.red,
                                              ),
                                            ),
                                            Text(
                                              transactionId,
                                              style: TextStyle(fontSize: 12, color: Colors.red),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        Row(children: [
                                          Icon(Icons.calendar_month_outlined, color: Colors.grey, size: 16),
                                          SizedBox(width: 3),
                                          Text(formatStartTime, style: TextStyle(fontSize: 13, color: Colors.black)),
                                        ]),
                                        SizedBox(height: 3),
                                        Row(children: [
                                          Icon(Icons.calendar_month_outlined, color: Colors.grey, size: 16),
                                          SizedBox(width: 3),
                                          Text(formatEndTime, style: TextStyle(fontSize: 13, color: Colors.black)),
                                        ]),
                                        SizedBox(height: 3),
                                        Row(
                                          children: [
                                            Icon(Icons.work_history_outlined, color: Colors.grey, size: 16),
                                            SizedBox(width: 3),
                                            Text(duration, style: TextStyle(fontSize: 13, color: Colors.black)),
                                          ],
                                        ),
                                        SizedBox(height: 3),
                                        Row(
                                          children: [
                                            Icon(Icons.payment_outlined, color: Colors.grey, size: 16),
                                            SizedBox(width: 3),
                                            Text(payment, style: TextStyle(fontSize: 13, color: Colors.black)),
                                          ],
                                        ),
                                        SizedBox(height: 3),
                                        Row(
                                          children: [
                                            Icon(Icons.directions_car, color: Colors.grey, size: 16),
                                            SizedBox(width: 3),
                                            Text(PlateNum, style: TextStyle(fontSize: 13, color: Colors.black)),
                                            Spacer(),
                                            Text('RM $price', style: TextStyle(fontSize: 16, color: Colors.green)),
                                          ],
                                        ),
                                        SizedBox(height: 3),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
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

  String _monthName(int month) {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return monthNames[month - 1];
  }
}
