import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:parking_management_system/packageshistory.dart';
import 'history.dart';
import 'mainpage.dart';
import 'packages.dart';
import 'userprofile.dart';
import 'login.dart';
import 'addparking.dart';
import 'packageshistory.dart';

class FavouritePage extends StatefulWidget {
  final String userId;

  FavouritePage({required this.userId});

  @override
  State<FavouritePage> createState() => _FavouritePageState();
}

class _FavouritePageState extends State<FavouritePage> {
  final CollectionReference favouritesCollection = FirebaseFirestore.instance.collection('favourite');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? currentUser = FirebaseAuth.instance.currentUser;
  String username = '';

  @override
  void initState() {
    super.initState();
    _fetchUsername();
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

  void addFavourite(Map<String, dynamic> favouriteData) async {
    try {
      await favouritesCollection.add({
        ...favouriteData,
        'userId': widget.userId,
      });
    } catch (e) {
      print("Error adding favourite: $e");
    }
  }

  void removeFavourite(String docId) async {
    try {
      await favouritesCollection.doc(docId).delete();
    } catch (e) {
      print("Error removing favourite: $e");
    }
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
          ],
        ),
      ),
      body: StreamBuilder(
        stream: favouritesCollection.where('userId', isEqualTo: widget.userId).snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Card(
                color: Colors.red,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('No Favourites', style: TextStyle(color: Colors.white, fontSize: 18)),
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final favourite = doc.data() as Map<String, dynamic>;
              final docId = doc.id;

              return Card(
                margin: EdgeInsets.all(10),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.red),
                          SizedBox(width: 20),
                          Text(
                            favourite['location'],
                            style: TextStyle(
                              fontSize: 16, 
                              fontWeight: FontWeight.bold, 
                              color: Colors.green),
                          ),
                          SizedBox(width: 230),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green[400],
                              borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            favourite['pricingOption'],
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.directions_car, color: Colors.red),
                            SizedBox(width: 10),
                            Text(
                              favourite['vehiclePlateNum'], 
                              style: TextStyle(fontSize: 16)),
                          ],
                        ),
                        Text(
                          "RM ${favourite['price']}",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddParkingPage(
                                  userparkingselectionID: docId, // Pass the document ID
                                  location: favourite['location'], // Pass location
                                  pricingOption: favourite['pricingOption'] ?? 'Daily', // Pass pricing option, default to 'Daily'
                                  userId: widget.userId, // Pass the user ID
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add, color: Colors.white),
                              Text(
                                "Add This Parking",
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            removeFavourite(docId);
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.delete_outline, color: Colors.white),
                              Text(
                                "Remove",
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ),
  );
  }
}
