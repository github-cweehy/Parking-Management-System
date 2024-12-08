import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'favourite.dart';
import 'history.dart';
import 'packagereceipt.dart';
import 'packages.dart';
import 'package:intl/intl.dart';
import 'mainpage.dart';
import 'rewards.dart';
import 'userprofile.dart';
import 'login.dart';

class PackagesHistoryPage extends StatefulWidget {
  final String userId;

  PackagesHistoryPage({required this.userId});

  @override
  State<PackagesHistoryPage> createState() => _PackagesHistoryPageState();
}

class _PackagesHistoryPageState extends State<PackagesHistoryPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String username = '';
  List<Map<String, dynamic>> _allPackageHistory = [];
  List<Map<String, dynamic>> _filteredPackageHistory = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchUsername();
    _fetchPackageHistory().then((history){
      setState(() {
        _allPackageHistory = history;
        _filteredPackageHistory = _allPackageHistory;
      });
    });
  }

  Future<void> _fetchUsername() async {
    try {
      final userDoc = await _firestore.collection('users').doc(widget.userId).get();
      setState(() {
        username = userDoc.data()?['username'] ?? 'Username';
      });
    } catch (e) {
      print("Error fetching username: $e");
    }
  }

  // Fetch history records from `packages_bought` collection where `userId` field matches
  Future<List<Map<String, dynamic>>> _fetchPackageHistory() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('packages_bought')
          .where('userId', isEqualTo: widget.userId)
          .get();

        return querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();    
    } catch (e) {
        print("Error fetching package history: $e");
        return [];
    }
  }

  void _filterPackageHistory(String query) {
    setState(() {
      _searchQuery = query;
      _filteredPackageHistory = _allPackageHistory.where((history){
        final duration = history['duration']?.toLowerCase()?? '';
        return duration.contains(query.toLowerCase());
      }).toList();
    });
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
                if (value == 'Profile') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfilePage(userId: widget.userId),
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
                    builder: (context) => MainPage(userId: widget.userId),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.history, color: Colors.red),
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
              title: Text('Favourite', style: TextStyle(color: Colors.red)),
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
          ],
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: _filterPackageHistory,
              decoration: InputDecoration(
                labelText: 'Search by Duration',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchPackageHistory(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Card(
                      margin: EdgeInsets.all(20),
                      color: Colors.red,
                      child: Padding(
                        padding: const EdgeInsets.all(30.0),
                        child: Text(
                          'No history available.',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                }
            
                final historyDocs = snapshot.data!;
            
                return ListView.builder(
                  itemCount: _filteredPackageHistory.length,
                  itemBuilder: (context, index) {
                    var data = _filteredPackageHistory[index];
            
                    // Convert Timestamp to DateTime
                    DateTime startDate = data['startDate'].toDate();
                    DateTime endDate = data['endDate'].toDate();
                    
                    // Format the dates
                    String formattedStartDate = DateFormat('yyyy-MM-dd').format(startDate);
                    String formattedEndDate = DateFormat('yyyy-MM-dd').format(endDate);
            
                    return Card(
                      margin: EdgeInsets.all(10),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.calendar_month, color: Colors.red),
                                SizedBox(width: 20),
                                Text(
                                  data['duration'],
                                  style: TextStyle(
                                    fontSize: 18, 
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green),
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
            
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.access_time, color: Colors.red),
                                    SizedBox(width: 10),
                                    Column(
                                      children: [
                                        Text(
                                          "Start Date : $formattedStartDate",
                                          style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                                        ),
                                        Text(
                                          "End Date  : $formattedEndDate",
                                          style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[800],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    data['vehiclePlate'],
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(Icons.price_change, color: Colors.red),
                                SizedBox(width: 10),
                                Text(
                                  "RM ${data['price']}",
                                  style: TextStyle(fontSize: 16, color: Colors.black),
                                ),
                              ],
                            ),
                            SizedBox(height: 25),
                            Center(
                              child: 
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PackageReceiptPage(
                                        duration: data['duration'] ?? 'Unknown package',
                                        startDate: '$formattedStartDate',
                                        endDate: '$formattedEndDate',
                                        amount: data['price'] ?? 0,
                                        vehiclePlate: data['vehiclePlate'] ?? 'N/A',
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                    child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.save_alt, color: Colors.white),
                                      Text(
                                        'Receipt',
                                        style: TextStyle(fontSize: 16, color: Colors.white,)
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
            
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
