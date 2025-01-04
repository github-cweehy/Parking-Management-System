import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:parking_management_system/sa.manageaccount.dart';
import 'adminCustomerList.dart';
import 'adminEditPackagesBought.dart';
import 'adminEditParkingSelection.dart';
import 'adminMainPage.dart';
import 'adminPBHistory.dart';
import 'adminPBTransactionHistory.dart';
import 'adminPSHistory.dart';
import 'adminPSTransactionHistory.dart';
import 'adminProfile.dart';
import 'adminReward.dart';
import 'login.dart';

class UserHelpPage extends StatefulWidget {
  final String? adminId;
  final String? superadminId;

  UserHelpPage({required this.superadminId, required this.adminId});

  @override
  _UserHelpPage createState() => _UserHelpPage();
}

class _UserHelpPage extends State<UserHelpPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String admin_username = '';

  DateTime? selectedDate;
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();

  List<Map<String, dynamic>> helpMessages = [];
  List<Map<String, dynamic>> usersData = [];

  final Map<String, String> _usernameCache = {};
  Future<String> _fetchUsername(String userId) async{
    if(_usernameCache.containsKey(userId)){
      return _usernameCache[userId]!;
    }

     try{
      DocumentSnapshot userSnapshot = await _firestore.collection('users').doc(userId).get();
      if(userSnapshot.exists){
        String username = userSnapshot['username'] ?? 'Unknown User';
        setState(() {
          _usernameCache[userId] = username;
        });
        
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
    _fetchUserData();
    _fetchHelpMessages();
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

  //get filter data
  Stream<QuerySnapshot> getFilteredData() {
    if (startDate != null && endDate != null) {
      return _firestore
        .collection('help')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .snapshots();
    } 
    else {
      return _firestore.collection('help').snapshots();
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

    DateTime initialDate = isStartDate ? startDate : endDate;
    if (initialDate.isAfter(maxDate)) {
      initialDate = maxDate;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate, 
      firstDate: minDate,
      lastDate: maxDate,
      selectableDayPredicate: (date) {
        return availableDates.contains(DateTime(date.year, date.month, date.day));
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          startDate = DateTime(picked.year, picked.month, picked.day); 
          
          if (endDate.isBefore(startDate)) {
            endDate = DateTime(startDate.year, startDate.month, startDate.day, 23, 59, 59); 
          }
        }
        else {
          endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59); 
          if (startDate.isAfter(endDate)) {
            startDate = DateTime(endDate.year, endDate.month, endDate.day); 
          }
        }
      });
      _fetchHelpMessages();
    }
  }

  //get availabledates
  Future<List<DateTime>> getAvailableDates() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('help').get();

      List<DateTime> availableDates = snapshot.docs.map((doc) {
        Timestamp timestamp = doc['timestamp'];
        return DateTime(timestamp.toDate().year, timestamp.toDate().month, timestamp.toDate().day);
      }).toList();

      if (availableDates.isEmpty) {
        availableDates.add(DateTime.now());
      }

      return availableDates;

    } catch (e) {
      print("Error fetching available dates: $e");
      return [];
    }
  }

  //Load all user data at once
  void _fetchUserData() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('users').get();
        setState(() {
          usersData = snapshot.docs.map((doc){ 
            return{
              'id': doc.id, 
              'email': doc['email'] ?? 'Unknown Email',
            };
          }).toList();
        });
    }catch (e) {
        print("Error fetching user data: $e");
      }
  }

  //fetch Help Messages 
  void _fetchHelpMessages() async {
    try {
      QuerySnapshot snapshot = await _firestore
      .collection('help')
      .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
      .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
      .get();

      List<Map<String, dynamic>> messages = [];

      for(var doc in snapshot.docs) {
        String userId = doc['userId']; 
        String username = await _fetchUsername(userId);
        String problem = doc['problem'] ?? 'No problem description';
        Timestamp timestamp = doc['timestamp'] ?? Timestamp.now();
        String email = usersData.firstWhere(
          (user) => user['id'] == userId, orElse: () => {'email': 'Unknown Email'}
        )['email'];

        DateTime dateTime = timestamp.toDate().toLocal();
        dateTime = dateTime.add(Duration(hours: 8)); 
        String formatDate = DateFormat('dd-MM-yyyy HH:mm').format(dateTime);

        messages.add({
          'username': username,
          'email': email,
          'problem': problem,
          'timestamp': formatDate,
        });

        setState(() {
          helpMessages = messages;
        });
      }
    }catch(e) {
      print('Error fetching messages: $e');
    }
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
              underline: Container(),
              icon: Row(
                children: [
                  Text(admin_username, style: TextStyle(color: Colors.black)),
                  Icon(Icons.arrow_drop_down, color: Colors.black),
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
                  "Help",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                //Start Date
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
                            Icon(Icons.calendar_month, color: Colors.grey, size: 20),
                            SizedBox(width: 5),
                            //Text
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

                //End Date
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
                          Icon(Icons.calendar_month, color: Colors.grey, size: 20),
                          SizedBox(width: 5),
                          //Text
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
            ]),
            SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: helpMessages.length,
                itemBuilder: (context, index){
                  final message = helpMessages[index];

                  var username = message['username'];
                  var problem = message['problem'];
                  var email = message['email'];
                  var timestamp = message['timestamp'];

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red, width: 1.0),
                    ),
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Icon(Icons.person, color: Colors.white, size: 22),
                              SizedBox(width: 6),
                              Text(
                                username,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Spacer(),
                              Text(
                                '${message['timestamp']}',
                                style: TextStyle(fontSize: 13, color: Colors.white),
                              ),
                              SizedBox(height: 2),
                            ],
                          ),
                          SizedBox(height: 1),
                          Row(
                            children: [
                              Icon(Icons.email, color: Colors.white, size: 20),
                              SizedBox(width: 6),
                              Text(
                                email,
                                style: TextStyle(fontSize: 14, color: Colors.white),
                              ),
                            ],
                          ),
                          SizedBox(height: 15),
                          Row(
                            children: [
                              Icon(Icons.help, color: Colors.white, size: 20),
                              SizedBox(width: 6),
                              Text(
                                problem,
                                 style: TextStyle(fontSize: 15, color: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }
              )
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