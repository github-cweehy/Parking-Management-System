import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:parking_management_system/favourite.dart';
import 'history.dart';
import 'mainpage.dart';
import 'login.dart'; 
import 'addparking.dart';

class LocationPage extends StatefulWidget {
  final String userId;
  final String userparkingselectionID;
  final String pricingOption; 
  
  LocationPage({required this.pricingOption, required this.userId, required this.userparkingselectionID});

  @override
  _LocationPageState createState() => _LocationPageState();
}


class _LocationPageState extends State<LocationPage> {
  String username = '';
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  String _currentStreet = "Detecting location...";
  Marker? _currentLocationMarker;

  @override
  void initState() {
    super.initState();
    _fetchUsername();
    _determinePosition();
  }

  Future<void> _fetchUsername() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
    if (userDoc.exists) {
      setState(() {
        username = userDoc.data()?['username'] ?? 'Username';
      });
      print("Username fetched successfully: $username");
    } else {
      print("No document found for the given user ID.");
    }
    } catch (e) {
      print("Error fetching username: $e");
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

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition();
    _updateCurrentLocation(LatLng(position.latitude, position.longitude));
  }

  void _updateCurrentLocation(LatLng position) async {
    setState(() {
      _currentPosition = position;
      _currentLocationMarker = Marker(
        markerId: MarkerId('currentLocation'),
        position: position,
        infoWindow: InfoWindow(title: "You are here"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      );
    });

    _getAddressFromLatLng(position);
    if (_mapController != null) {
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(position, 15.0));
    }
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        setState(() {
          _currentStreet = placemarks[0].street ?? "Unknown Street";
        });
      }
    } catch (e) {
      print(e);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_currentPosition != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(_currentPosition!),
      );
    }
  }

  Future<void> _searchStreet(String streetName) async {
    List<Location> locations = await locationFromAddress("$streetName, Melaka");
    if (locations.isNotEmpty) {
      LatLng searchPosition = LatLng(locations.first.latitude, locations.first.longitude);
      _updateCurrentLocation(searchPosition);
    }
  }

  void _confirmLocation() async {
    try {
      // Use the userParkingSelectionID to update the correct document
      DocumentReference parkingSelectionDocRef = FirebaseFirestore.instance
          .collection('history parking')
          .doc(widget.userparkingselectionID);  // Use the passed ID

      await parkingSelectionDocRef.update({
        'location': _currentStreet,
      });
      print("Location saved successfully.");

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddParkingPage(
            location: _currentStreet,
            pricingOption: widget.pricingOption,
            userId: widget.userId,
            userparkingselectionID: widget.userparkingselectionID,
          ),
        ),
      );
  } catch(e){
    print("Error saving location: $e");
  }
}
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () async{
              try {
                await FirebaseFirestore.instance
                  .collection('history parking')
                  .doc(widget.userparkingselectionID)
                  .delete();
                
                Navigator.pushReplacement(
                  context, 
                  MaterialPageRoute(
                    builder: (context) => MainPage(userId: widget.userId),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting data. Please try again.')),
                );
              }
            },
          ),
        title: Image.asset(
          'assets/logomelaka.jpg', 
          height: 60,
        ),
        centerTitle: true,
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
              leading: Icon(Icons.history, color: Colors.red),
              title: Text('History', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HistoryPage(
                      userId: widget.userId,
                    ),
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
                    builder: (context) => FavouritePage(
                      userId: widget.userId,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: LatLng(2.1938, 102.2496), // Initial center on Melaka Raya
              zoom: 14.0,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: _currentLocationMarker != null ? {_currentLocationMarker!} : {},
          ),
          Positioned(
            top: 20.0,
            left: 15.0,
            right: 15.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10.0)],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search area',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (value) {
                        _searchStreet(value);
                      },
                    ),
                  ),
                  Icon(Icons.search),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 20.0,
            left: 15.0,
            right: 15.0,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onPressed: _confirmLocation,
              child: Text("Confirm location: $_currentStreet"),
            ),
          ),
        ],
      ),
    );
  }
}
