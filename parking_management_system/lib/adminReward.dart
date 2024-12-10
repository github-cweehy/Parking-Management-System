import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'adminCustomerList.dart';
import 'adminEditPackagesBought.dart';
import 'adminEditParkingSelection.dart';
import 'adminPBHistory.dart';
import 'adminPBTransactionHistory.dart';
import 'adminPSHistory.dart';
import 'adminPSTransactionHistory.dart';
import 'adminProfile.dart';
import 'login.dart';

class RewardHistoryPage extends StatefulWidget {
  final String adminId;

  RewardHistoryPage({required this.adminId});

  @override
  _RewardHistoryPage createState() => _RewardHistoryPage();
}

class _RewardHistoryPage extends State<RewardHistoryPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String admin_username = '';

  Map<String, List<Map<String, dynamic>>> rewards = {
    'activeRewards': [],
    'pastRewards': [],
  };

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
    _fetchAdminUsername();
    _fetchAllUsernames();
    _fetchRewardFromFirebase();
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

  //Fetch reward history from firebase
  void _fetchRewardFromFirebase() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('rewards').get();

      List<Map<String, dynamic>> activeRewards = [];
      List<Map<String, dynamic>> pastRewards = [];

      snapshot.docs.forEach((doc) {
        var reward = {
          'id': doc.id,
          'userId': doc['userId'],
          'createdAt': doc['createdAt'] != null ? doc['createdAt'].toDate() : null,
          'expiryDate': doc['expiryDate'] != null ? doc['expiryDate'].toDate() : null,
          'isUsed': doc['isUsed'],
        };

        // Check isUsed to sort into active or past rewards
        if (doc['isUsed'] == true) {
          pastRewards.add(reward);
        } else {
          activeRewards.add(reward);
        }
      });
      setState(() {
        rewards['activeRewards'] = activeRewards;
        rewards['pastRewards'] = pastRewards;
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
                        builder: (context) => AdminProfilePage(adminId: widget.adminId),
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
                title: Text('Admin Profile', style: TextStyle(color: Colors.black, fontSize: 16)),
                onTap: () {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (context) => AdminProfilePage(adminId: widget.adminId),
                    ),
                  );
                },
              ),

              /*ListTile(
                leading: Icon(Icons.groups, color: Colors.grey),
                title: Text('Manage Admin Account', style: TextStyle(color: Colors.grey)),
                onTap: () {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (context) => AdminProfilePage(adminId: widget.adminId),
                    ),
                  );
                },
              ), */

              ListTile(
                leading: Icon(Icons.edit, color: Colors.black, size: 23),
                title: Text('Edit Parking Selection', style: TextStyle(color: Colors.black, fontSize: 16)),
                onTap: () {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (context) => EditParkingSelectionPage(adminId: widget.adminId),
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
                      builder: (context) => ParkingSelectionHistoryPage(adminId: widget.adminId),
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
                      builder: (context) => ParkingSelectionTransactionHistoryPage(adminId: widget.adminId),
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
                      builder: (context) => EditPackagesBoughtPage(adminId: widget.adminId),
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
                      builder: (context) => PackagesBoughtHistoryPage(adminId: widget.adminId),
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
                      builder: (context) => PackagesBoughtTransactionHistoryPage(adminId: widget.adminId),
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
                      builder: (context) => CustomerListPage(adminId: widget.adminId),
                    ),
                  );
                },
              ),
            ],
          )
        ),
        body: Column(
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

            TabBar(
              indicatorColor: Colors.red,
              tabs: [
                Tab(child: Text("Active Rewards", style: TextStyle(color: Colors.black))),
                Tab(child: Text("Past Rewards", style: TextStyle(color: Colors.black))),
              ],
            ),      
            Expanded(
              child: TabBarView(
                children: [
                  //Active Rewards
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ListView.builder(
                      itemCount: rewards['activeRewards']?.length ?? 0,
                      itemBuilder: (context, index) {
                        final reward = rewards['activeRewards']![index];
                        final userId = reward['userId'] ?? '';
                        var username = _usernameCache[userId] ?? 'Unknown User';

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red, width: 1.0),
                          ),
                          padding: EdgeInsets.all(16.0),
                          margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              //Pass Rewards
                              Row(
                                children: [
                                  Text(
                                    '@$username',
                                    style: TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 15),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, color: Colors.white, size: 20),
                                  SizedBox(width: 5),
                                  Text(
                                    reward['createdAt'] != null
                                      ? 'Created: ${DateFormat('dd MMMM yyyy').format(reward['createdAt'])}'
                                      : 'Created: Unknown',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, color: Colors.white, size: 20),
                                  SizedBox(width: 5),
                                  Text(
                                    'Expiry: ${DateFormat('dd MMMM yyyy').format(reward['expiryDate'].toDate())}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 18),
                              Text(
                                'Status: Unsed',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  ),
                  //Past Reward
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ListView.builder(
                      itemCount: rewards['pastRewards']?.length ?? 0,
                      itemBuilder: (context, index) {
                        final reward = rewards['pastRewards']![index];
                        final userId = reward['userId'] ?? '';
                        var username = _usernameCache[userId] ?? 'Unknown User';

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red, width: 1.0),
                          ),
                          padding: EdgeInsets.all(16.0),
                          margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              //Pass Rewards
                              Row(
                                children: [
                                  Text(
                                    '@$username',
                                    style: TextStyle(
                                      fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 15),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, color: Colors.white, size: 20),
                                  SizedBox(width: 5),
                                  Text(
                                    reward['createdAt'] != null
                                      ? 'Created: ${DateFormat('dd MMMM yyyy').format(reward['createdAt'])}'
                                      : 'Created: Unknown',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, color: Colors.white, size: 20),
                                  SizedBox(width: 5),
                                  Text(
                                    'Expiry: ${DateFormat('dd MMMM yyyy').format(reward['expiryDate'])}',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Status: Used',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}