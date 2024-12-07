import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'confirmPackage.dart';
import 'favourite.dart';
import 'history.dart';
import 'mainpage.dart';
import 'packageshistory.dart';
import 'rewards.dart';
import 'userprofile.dart';
import 'login.dart';

class PackagesPage extends StatefulWidget {
  final String userId;

  PackagesPage({required this.userId});

  @override
  State<PackagesPage> createState() => _PackagesPageState();
}

class _PackagesPageState extends State<PackagesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String username = '';
  List<Map<String, dynamic>> packages = [];

  @override
  void initState() {
    super.initState();
    _fetchUsername();
    _fetchPackagePrices();
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
  
  Future<void> _fetchPackagePrices() async {
    try {
      final packageCollection = await _firestore.collection('packagesprice').get();
      
      List<Map<String, dynamic>> tempPackages = [];

      // Loop through each document and add to the list
      for (var doc in packageCollection.docs) {
        tempPackages.add({
          'duration': doc.id, 
          'price': (doc.data()['price'] ?? 0.0).toDouble(),
        });
      }

      // Sort packages by duration
      tempPackages.sort((a, b) {
        return _compareDurations(a['duration'], b['duration']);
      });

      setState(() {
        packages = tempPackages;
      });
    } catch (e) {
      print("Error fetching package prices: $e");
    }
  }

  int _compareDurations(String durationA, String durationB) {
    // Extract the numeric part from the duration string
    int numA = int.parse(durationA.split('-')[0]);
    int numB = int.parse(durationB.split('-')[0]);

    // Compare the numeric values
    return numA.compareTo(numB);
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

  void _navigateToConfirmPackage(String duration, double price) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConfirmPackagePage(
          userId: widget.userId,
          duration: duration,
          price: price,
        ),
      ),
    );
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
                    builder: (context) => FavouritePage(userId: widget.userId),
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
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Packages",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            ...packages.map((package) {
              return GestureDetector(
                onTap: () => _navigateToConfirmPackage(package['duration'], package['price']),
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 10),
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${package['duration']}',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      SizedBox(width: 150),
                      Text(
                        'RM ${package['price'].toString()}',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      Icon(Icons.arrow_forward_ios, color: Colors.white),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}