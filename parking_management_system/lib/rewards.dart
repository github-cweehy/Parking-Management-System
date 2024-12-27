import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'confirmRewards.dart';
import 'favourite.dart';
import 'help.dart';
import 'history.dart';
import 'login.dart';
import 'mainpage.dart';
import 'packages.dart';
import 'packageshistory.dart';
import 'userprofile.dart';
import 'package:intl/intl.dart';

class FreeParkingRewardsPage extends StatefulWidget {
  final String userId;

  FreeParkingRewardsPage({required this.userId});

  @override
  State<FreeParkingRewardsPage> createState() => _FreeParkingRewardsPageState();
}

class _FreeParkingRewardsPageState extends State<FreeParkingRewardsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String username = '';

  @override
  void initState() {
    super.initState();
    fetchUsername(); 
  }

  void _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } catch (e) {
      print("Error signing out: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out. Please try again.')),
      );
    }
  }

  Future<void> fetchUsername() async {
    try {
      final userDoc = await _firestore.collection('users').doc(widget.userId).get();
      setState(() {
        username = userDoc.data()?['username'] ?? 'Username';
      });
    } catch (e) {
      print("Error fetching username: $e");
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
              icon: Icon(Icons.menu, color: Colors.black),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
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
                      username,
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
                  if (value == 'Logout') {
                    _logout(context);
                  } else if (value == 'Profile') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserProfilePage(userId: widget.userId),
                      ),
                    );
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
                  mainAxisAlignment: MainAxisAlignment.center,
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
                leading: Icon(Icons.home, color: Colors.red),
                title: Text('Home Page', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MainPage(
                        userId: widget.userId,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.history, color: Colors.red,),
                title: Text('Parking History', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HistoryPage(userId: widget.userId),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.favorite, color: Colors.red),
                title: Text('Favorite', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FavouritePage(userId: widget.userId),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.local_grocery_store_outlined, color: Colors.red),
                title: Text('Packages', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PackagesPage(userId: widget.userId),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.work_history_outlined, color: Colors.red),
                title: Text('Packages History', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PackagesHistoryPage(userId: widget.userId),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.celebration_rounded, color: Colors.red),
                title: Text('Your Rewards', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FreeParkingRewardsPage(userId: widget.userId),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.help_outline_sharp, color: Colors.red),
                title: Text('Help Center', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HelpPage(userId: widget.userId),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        body: Column(
          children: [
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
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('rewards')
                          .where('userId', isEqualTo: widget.userId)
                          .where('isUsed', isEqualTo: false)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                    
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(child: Text('No free parking rewards available.'));
                        }
                    
                        final rewards = snapshot.data!.docs;
                    
                        return ListView.builder(
                          itemCount: rewards.length,
                          itemBuilder: (context, index) {
                            final reward = rewards[index];
                            return Container(
                              margin: EdgeInsets.symmetric(vertical: 10),
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.shade200,
                                    blurRadius: 5,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Free Daily Parking',
                                    style : TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today, color: Colors.white),
                                      SizedBox(width: 10),
                                      Text(
                                        'Valid until: ${DateFormat('dd MMMM yyyy').format(reward['expiryDate'].toDate())}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 15),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {

                                        DateTime now = DateTime.now();
                                        DateTime endDateTime = now.add(Duration(days: 1));

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ConfirmUsingVoucherPage(
                                              userId: widget.userId, 
                                              rewardId: reward.id, 
                                              startDateTime: now, 
                                              endDateTime: endDateTime
                                            ),
                                          ),
                                        );                                        
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        padding: EdgeInsets.all(10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        )
                                      ),
                                      child: Text(
                                        'Use Reward',
                                        style: TextStyle(fontSize: 18, color: Colors.red),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  // Past Rewards
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('rewards')
                          .where('userId', isEqualTo: widget.userId)
                          .where('isUsed', isEqualTo: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                    
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(child: Text('No past rewards available.'));
                        }
                    
                        final pastRewards = snapshot.data!.docs;
                    
                        return ListView.builder(
                          itemCount: pastRewards.length,
                          itemBuilder: (context, index) {
                            final reward = pastRewards[index];
                            return Container(
                              margin: EdgeInsets.symmetric(vertical: 8.0),
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.shade200,
                                    blurRadius: 5,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Free Daily Parking',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today, color: Colors.white),
                                      SizedBox(width: 10),
                                      Text(
                                        'Expiry: ${DateFormat('dd MMMM yyyy').format(reward['expiryDate'].toDate())}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 15),
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
}
