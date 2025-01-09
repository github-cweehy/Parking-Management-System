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
import 'adminPSHistory.dart';
import 'adminPSTransactionHistory.dart';
import 'adminProfile.dart';
import 'login.dart';

class RewardHistoryPage extends StatefulWidget {
  final String? superadminId;
  final String? adminId;

  RewardHistoryPage({required this.superadminId, required this.adminId});

  @override
  _RewardHistoryPage createState() => _RewardHistoryPage();
}

class _RewardHistoryPage extends State<RewardHistoryPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String admin_username = '';

  DateTime startTime = DateTime.now();
  DateTime endTime = DateTime.now();

  List<Map<String, dynamic>> reward = [];

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
    _fetchAllUsernames();
    _fetchRewardFromFirebase();
  }

  // Fetch superadmin username from Firebase
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

  //get filter data
  Stream<QuerySnapshot> getFilteredData() {
    if (startTime != null && endTime != null) {
      return _firestore
        .collection('history parking')
        .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startTime))
        .where('endTime', isLessThanOrEqualTo: Timestamp.fromDate(endTime))
        .snapshots();
    } 
    else {
      return _firestore.collection('history parking').snapshots();
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

    DateTime initialDate = isStartDate ? startTime : endTime;
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
      _fetchRewardFromFirebase();
    }
  }

  //get availabledates
  Future<List<DateTime>> getAvailableDates() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('history parking').get();

      List<DateTime> availableDates = [];
      
      for(var doc in snapshot.docs) {

        if (!doc.exists || !doc.data().toString().contains('startTime')) {
          continue; 
        }

        dynamic startTime = doc['startTime'];
        DateTime dateTime;

        if(startTime is Timestamp) {
          dateTime = startTime.toDate();
        }
        else if(startTime is String) {
          dateTime = DateTime.parse(startTime);
        }
        else{
          continue;
        }

        dateTime = DateTime(dateTime.year, dateTime.month, dateTime.day);

        if(!availableDates.contains(dateTime)) {
          availableDates.add(dateTime);
        }
      }

      if (availableDates.isEmpty) {
        availableDates.add(DateTime.now());
      }
      
      return availableDates;

    } catch (e) {
      print("Error fetching available dates: $e");
      return [];
    }
  }

  //Fetch reward history from firebase
  void _fetchRewardFromFirebase() async {
    try {
      // Fetch all rewards from 'rewards' collection
      QuerySnapshot rewardSnapshot = await _firestore.collection('rewards').get();
      Map<String, Map<String, dynamic>> rewardsMap = {
        for (var doc in rewardSnapshot.docs)
          doc['rewardCode']: {
            'userId': doc['userId'],
            'rewardCode': doc['rewardCode'],
          }
      };

      // Fetch all history parking records within the specified date range
      QuerySnapshot historySnapshot = await _firestore
          .collection('history parking')
          .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startTime))
          .where('endTime', isLessThanOrEqualTo: Timestamp.fromDate(endTime))
          .get();

      List<Map<String, dynamic>> matchedRewards = [];

      for (var doc in historySnapshot.docs) {
        // Skip if 'rewardId' or 'startTime' is missing
        if (!doc.exists || !doc.data().toString().contains('rewardId') || !doc.data().toString().contains('startTime')) {
          continue;
        }

        String rewardId = doc['rewardId'];

        // Match rewardId with rewardCode in rewardsMap
        if (rewardsMap.containsKey(rewardId)) {
          Map<String, dynamic> matchedReward = {
            ...rewardsMap[rewardId]!,
            'startTime':doc['startTime'],
            'endTime': doc['endTime'],
            'location': doc['location'],
            'pricingOption': doc['pricingOption'] ?? 'Unknown',
          };
          matchedRewards.add(matchedReward);
        }
      }

      // Update the state with matched rewards
      setState(() {
        reward = matchedRewards;
      });
    } catch (e) {
      print('Error fetching rewards: $e');
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
                leading: Icon(Icons.person, color: Colors.black, size: 23),
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
                SizedBox(width: 10),
                Text("Reward History", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),)
              ],
            ),
            SizedBox(height: 8),
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
                                "${startTime.day} ${_monthName(startTime.month)} ${startTime.year}",
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
                              "${endTime.day} ${_monthName(endTime.month)} ${endTime.year}",
                              style: TextStyle(color: Colors.black, fontSize: 13.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ]),
              SizedBox(height: 10),
              Expanded(
                child: reward.isEmpty
                ?Center(child: Text("No rewards data."))
                :ListView.builder(
                  itemCount: reward.length,
                  itemBuilder: (context, index) {
                    final Reward = reward[index];
                    final userId = Reward['userId'] ?? '';
                    var username = _usernameCache[userId] ?? 'Unknown User';

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red, width: 1.0),
                      ),
                      padding: EdgeInsets.all(16.0),
                      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 1),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            username,
                            style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white,
                            ),
                          ),
                          Spacer(),
                          Text(
                            'Voucher: ${Reward['pricingOption']}',
                            style: TextStyle(
                              fontSize: 15, 
                              color: Colors.white
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.download, color: Colors.white),
                            onPressed: () {
                              DateTime startTime;
                              DateTime endTime;

                              if(Reward['startTime']is String) {
                                startTime = DateTime.parse(Reward['startTime']);
                              }
                              else if (Reward['startTime'] is Timestamp) {
                                 startTime = (Reward['startTime'] as Timestamp).toDate();
                              }
                              else{
                                startTime = DateTime.now();
                              }

                              if (Reward['endTime'] is String) {
                                endTime = DateTime.parse(Reward['endTime']);
                              } 
                              else if (Reward['endTime'] is Timestamp) {
                                endTime = (Reward['endTime'] as Timestamp).toDate();
                              } 
                              else {
                                endTime = DateTime.now();
                              }

                              String formattedStartDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(startTime);
                              String formattedEndDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(endTime);

                              Navigator.push(
                                context, 
                                MaterialPageRoute(
                                  builder: (context) => ParkingReceiptPage(
                                    district: Reward['location'] ?? 'N/A', 
                                    startTime: formattedStartDate, 
                                    endTime: formattedEndDate,
                                    amount: double.tryParse(Reward['price'] ?? '0') ?? 0,
                                    type: Reward['pricingOption'] ?? 'N/A',
                                  )
                                )
                              );
                            },
                          )
                        ],
                      ),
                    );
                  }
                )
              )
            ],
          ),
        ),
      );
  }
  String _monthName(int month) {
    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return monthNames[month - 1];
  }
}