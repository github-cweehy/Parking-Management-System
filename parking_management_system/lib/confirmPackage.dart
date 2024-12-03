import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:parking_management_system/paymentmethod.dart';

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

  void calculateEndDate() {
  int monthsToAdd;
  switch (widget.duration) {
    case "1-month":
      monthsToAdd = 1;
      break;
    case "3-month":
      monthsToAdd = 3;
      break;
    case "6-month":
      monthsToAdd = 6;
      break;
    default:
      return;  
  }

    
    setState(() {
      endDate = DateTime(
        startDate.year,
        startDate.month + monthsToAdd,
        startDate.day,
      );

      if (endDate.month != ((startDate.month + monthsToAdd - 1) % 12 + 1)) {
        endDate = DateTime(endDate.year, endDate.month + 1, 0);
      }
    });

  }

  @override
  void initState() {
    super.initState();
    calculateEndDate();
    _fetchVehiclePlates();
  }

  Future<String?> _savePackageToFirestore() async {
    try {
      if (selectedPlate == null || selectedPlate!.isEmpty) {
        throw Exception("Vehicle plate is null or empty.");
      }

      // Check if there's already an active package for the selected plate
      final existingPackageQuery = await FirebaseFirestore.instance
          .collection('packages_bought')
          .where('vehiclePlate', isEqualTo: selectedPlate)
          .where('endDate', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()))
          .get();

      if (existingPackageQuery.docs.isNotEmpty) {
        // Show an error message if there's already an active package
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "This vehicle plate already has an active package.",
              style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
        // Navigate back to the package selection page
        Navigator.pop(context);
        return null;
      }

      DocumentReference docRef = await FirebaseFirestore.instance
        .collection('packages_bought')
        .add({
          'userId': widget.userId,
          'duration': widget.duration,
          'price': widget.price,
          'startDate': startDate,
          'endDate': endDate,
          'vehiclePlate': selectedPlate,
      });

      print("Package saved to Firestore with ID: ${docRef.id}");
      return docRef.id;

    } catch (e) {
      print("Error saving package to Firestore: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Packages"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
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
                    onPressed: () async {
                      // Handle confirm payment logic here
                      if (selectedPlate == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text("Please select a plate number.")));
                        return;
                      }

                      String? packageId = await _savePackageToFirestore();

                      if (packageId == null) {
                        return; // Do not navigate further
                      }

                       Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentMethodPage(
                            userId: widget.userId, 
                            packageId: packageId,
                            price:widget.price, 
                            duration: widget.duration,
                            source: 'packages',
                            ),
                          ),
                        );
                    },
                    child: const Text(
                      "Confirm Payment",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white),
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