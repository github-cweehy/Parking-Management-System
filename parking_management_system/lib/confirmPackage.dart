import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ConfirmPackagePage extends StatefulWidget {
  final String duration; 
  final double price;
  final String userId;

  ConfirmPackagePage({required this.duration, required this.price, required this.userId});

  @override
  _ConfirmPackagePageState createState() => _ConfirmPackagePageState();
}

class _ConfirmPackagePageState extends State<ConfirmPackagePage> {
  String? selectedPlate;
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();
  List<String> vehiclePlates = [];


  // Fetch registration plates from Firebase users collection
  Future<void> _fetchVehiclePlates() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
          
      // Get the list of vehicles from the user's data
      List<dynamic> vehicleList = userDoc.data()?['vehicles'] ?? [];
      List<String> plates = vehicleList.map<String>((vehicle) {
      return vehicle['registrationNumber'] ?? '';
      }).toList();

      String defaultVehicle = userDoc.data()?['default_vehicle'] ?? '';


      setState(() {
        vehiclePlates = plates;
        selectedPlate = defaultVehicle.isNotEmpty && plates.contains(defaultVehicle) 
            ? defaultVehicle 
            : plates.isNotEmpty 
              ? plates.first 
              : '';    });
    } catch (e) {
      print("Error fetching vehicle plates: $e");
    }
  }

  // Calculate end date based on selected duration
  void calculateEndDate() {
    if (widget.duration.contains("1-month")) {
      endDate = DateTime(startDate.year, startDate.month + 1, startDate.day);
    } else if (widget.duration.contains("3-months")) {
      endDate = DateTime(startDate.year, startDate.month + 3, startDate.day);
    }
    else if (widget.duration.contains("6-months")) {
      endDate = DateTime(startDate.year, startDate.month + 6, startDate.day);
    }
  }

  @override
  void initState() {
    super.initState();
    calculateEndDate();
    _fetchVehiclePlates();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Packages"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: DropdownButton(
              underline: SizedBox(),
              icon: const Icon(Icons.person, color: Colors.white),
              items: const [
                DropdownMenuItem(value: "Username", child: Text("Username"))
              ],
              onChanged: (value) {},
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.red),
                SizedBox(width: 20),
                Text(
                  "All Melaka Area",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(height: 30),
            
            TextFormField(
              readOnly: true,
              initialValue: DateFormat('dd MMMM yyyy').format(startDate),
              decoration: InputDecoration(
                labelText: "Start Date",
                prefixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            TextFormField(
              readOnly: true,
              initialValue: DateFormat('dd MMMM yyyy').format(endDate),
              decoration: InputDecoration(
                labelText: "End Date",
                prefixIcon: const Icon(Icons.access_time),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 40),

              DropdownButtonFormField<String>(
                value: selectedPlate,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedPlate = newValue!;
                  });
                },
                items: vehiclePlates.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                decoration: InputDecoration(
                  labelText: "Registration Plate",
                  prefixIcon: Icon(Icons.directions_car),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                isExpanded: true,
              ),
              const SizedBox(height: 40),
            const SizedBox(height: 20),

            Center(
              child: Column(
                children: [
                  Text(
                    "Price : RM ${widget.price.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 15),
                    ),
                    onPressed: () {
                      // Handle confirm payment logic here
                      if (selectedPlate == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text("Please select a plate number.")));
                        return;
                      }
                      // Save to Firebase or handle further steps
                      print(
                          "Confirmed package with plate: $selectedPlate, duration: ${widget.duration}, start: $startDate, end: $endDate, price: RM ${widget.price}");
                    },
                    child: const Text(
                      "Confirm Payment",
                      style: TextStyle(fontSize: 16),
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
