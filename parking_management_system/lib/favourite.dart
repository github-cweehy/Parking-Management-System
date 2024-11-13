import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'history.dart';
import 'mainpage.dart';
import 'userprofile.dart';
import 'login.dart';

class FavouritePage extends StatefulWidget {
  final String userId;

  FavouritePage({required this.userId});

  @override
  State<FavouritePage> createState() => _FavouritePageState();
}

class _FavouritePageState extends State<FavouritePage> {
  String username = '';
  final CollectionReference favouritesCollection = FirebaseFirestore.instance.collection('favourite');
  List<Map<String, dynamic>> favourites = [];

  @override
  void initState() {
    super.initState();
    fetchFavourites();
  }

  void fetchFavourites() async {
    try {
      final snapshot = await favouritesCollection.where('userId', isEqualTo: widget.userId).get();
      setState(() {
        favourites = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      });
    } catch (e) {
      print("Error fetching favourites: $e");
    }
  }

  void addFavourite(String location, String district, String price, String time, String vehicleType) async {
    try {
      await favouritesCollection.add({
        'userId': widget.userId,
        'location': location,
        'district': district,
        'price': price,
        'time': time,
        'vehicleType': vehicleType,
      });
      fetchFavourites(); // Refresh the list after adding
    } catch (e) {
      print("Error adding favourite: $e");
    }
  }

  void removeFavourite(String docId) async {
    try {
      await favouritesCollection.doc(docId).delete();
      fetchFavourites(); // Refresh the list after deleting
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
              title: Text('History', style: TextStyle(color: Colors.red)),
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
          ],
        ),
      ),
      body: favourites.isEmpty
          ? Center(
              child: Card(
                color: Colors.red,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'No Favourites',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
            )
          : ListView.builder(
              itemCount: favourites.length,
              itemBuilder: (context, index) {
                final favourite = favourites[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Icon(Icons.location_on, color: Colors.red),
                    title: Text(favourite['location']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("District: ${favourite['district']}"),
                        Text("Price: ${favourite['price']}"),
                        Text("Time: ${favourite['time']}"),
                        Text("Vehicle: ${favourite['vehicleType']}"),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            addFavourite(
                              favourite['location'],
                              favourite['district'],
                              favourite['price'],
                              favourite['time'],
                              favourite['vehicleType'],
                            );
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: Text("Add This Parking"),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            removeFavourite(favourite['id']);
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: Text("Remove"),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
