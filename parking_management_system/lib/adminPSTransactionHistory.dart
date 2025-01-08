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
import 'adminPBTransactionHistory.dart';
import 'adminPSHistory.dart';
import 'adminProfile.dart';
import 'adminReward.dart';
import 'login.dart';

class ParkingSelectionTransactionHistoryPage extends StatefulWidget {
  final String? superadminId;
  final String? adminId;

  ParkingSelectionTransactionHistoryPage({required this.superadminId, required this.adminId});

  @override
  _ParkingSelectionTransactionHistoryPage createState() => _ParkingSelectionTransactionHistoryPage();
}

class _ParkingSelectionTransactionHistoryPage extends State<ParkingSelectionTransactionHistoryPage>{
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();
  String admin_username = '';

  Timestamp? startTimestamp;
  Timestamp? endTimestamp;

  final Map<String, String> _usernameCache = {};
  Future<String> _fetchUsername(String userId) async{
    if(_usernameCache.containsKey(userId)){
      return _usernameCache[userId]!;
    }

    try{
      DocumentSnapshot userSnapshot = await _firestore.collection('users').doc(userId).get();
      if(userSnapshot.exists){
        String username = userSnapshot['username'] ?? 'Unknown User';
        _usernameCache[userId] = username;
        return username;
      }
      else{
        return 'Unknown User';
      }
    }catch(e){
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
      DocumentSnapshot snapshot =
          await _firestore.collection('admins').doc(widget.adminId).get();
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
      return _firestore
          .collection('transactions')
          .where('timestamp', isGreaterThanOrEqualTo: startTimestamp)
          .where('timestamp', isLessThanOrEqualTo: endTimestamp)
          .snapshots();
    } else {
      return _firestore.collection('transactions').snapshots();
    }
  }

  void _selectDate(BuildContext context, bool isStartDate) async{
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

  void _loadDataForDate(DateTime date) {
    setState(() {
      startDate = date;
      endDate = date;
      startTimestamp = Timestamp.fromDate(startDate);
      endTimestamp = Timestamp.fromDate(endDate);
    });
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
          height: 60
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
              items: ['Profile', 'Logout'].map((String value) {
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
                  "Parking Selection Transaction History", 
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
                      child: Text(
                        "Start Date", style: TextStyle(fontSize: 13)),
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
                      child: 
                        Text("End Date", style: TextStyle(fontSize: 13)),
                    ),

                    GestureDetector(
                      onTap: () => _selectDate(context, false),
                      child: Container(
                        width: 185,
                        height: 40,
                        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
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
                          return Center(child: Text(
                            startTimestamp != null && endTimestamp != null
                              ? 'No data found for the selected date.'
                              : 'No records available.'
                          ),
                          );
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
                            var parking = transaction['parking']; //transactions parking
                            Timestamp timestamp = transaction['timestamp'];
                            var parkingId = transaction['parking']; //history parking
                            var payment = transaction['paymentMethod'];
                            final price = transaction['amount']?.toStringAsFixed(2) ?? 0.0;

                            //Format dates and times
                            DateTime dateTime = timestamp.toDate().toLocal();
                            String formatdateTime = DateFormat('d MMM yyyy  h:mm a').format(dateTime);

                            //Determine if parking is null
                            if(parking == null){
                              return SizedBox.shrink();
                            }

                            return FutureBuilder<DocumentSnapshot>(
                              future: _firestore.collection('history parking').doc(parkingId).get(), 
                              builder: (context, parkingSnapshot){
                                if (parkingSnapshot.connectionState == ConnectionState.waiting) {
                                  return CircularProgressIndicator();
                                }
                                if (parkingSnapshot.hasError) {
                                  return Text('Error fetching parking details');
                                }
                                if (!parkingSnapshot.hasData || !parkingSnapshot.data!.exists) {
                                  return SizedBox.shrink(); 
                                }

                                //Get startTime endTime from history parking
                                var parkingData = parkingSnapshot.data!;
                                dynamic StartTimes = parkingData['startTime'];
                                dynamic EndTimes = parkingData['endTime'];

                                DateTime startTime;
                                DateTime endTime;

                                if (StartTimes is Timestamp) {
                                  startTime = StartTimes.toDate();
                                } 
                                else if (StartTimes is String) {
                                  startTime = DateTime.parse(StartTimes);
                                }
                                else {
                                  startTime = DateTime.now(); 
                                }

                                if (EndTimes is Timestamp) {
                                  endTime = EndTimes.toDate();
                                } 
                                else if (EndTimes is String) {
                                  endTime = DateTime.parse(EndTimes);
                                } 
                                else {
                                  endTime = DateTime.now();
                                }

                                String pricingOption = parkingData['pricingOption'] ?? 'Not available';
                                String PlateNum = parkingData['vehiclePlateNum'] ??'Not available';

                                //format datetime
                                String formatStartTime = DateFormat('d MMM yyyy h:mm a').format(startTime);
                                String formatEndTime = DateFormat('d MMM yyyy h:mm a').format(endTime);

                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.grey.shade400, width: 1.0),
                                  ),
                                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
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
                        
                                        Row(
                                          children: [
                                            Icon(Icons.calendar_month_outlined, color: Colors.grey, size: 16),
                                            SizedBox(width: 3),
                                            Text(formatStartTime, style: TextStyle(fontSize: 13, color: Colors.black)),
                                          ],
                                        ),
                                        SizedBox(height: 3),
                                        Row(
                                          children: [
                                            Icon(Icons.calendar_month_outlined, color: Colors.grey, size: 16,),
                                            SizedBox(width: 3),
                                            Text(formatEndTime, style: TextStyle(fontSize: 13, color: Colors.black)),
                                          ],
                                        ),
                                        SizedBox(height: 3),
                                        Row(
                                          children: [
                                            Icon(Icons.work_history_outlined, color: Colors.grey, size: 16),
                                            SizedBox(width: 3),
                                            Text(pricingOption, style: TextStyle(fontSize: 13, color: Colors.black)),
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
    List<String> monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return monthNames[month - 1];
  }
}