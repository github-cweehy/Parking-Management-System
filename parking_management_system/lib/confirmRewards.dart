import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'mainpage.dart';

class ConfirmUsingVoucherPage extends StatefulWidget {
  final String userId;
  final String rewardId;
  final DateTime startDateTime;
  final DateTime endDateTime;

  ConfirmUsingVoucherPage({
    required this.userId,
    required this.rewardId,
    required this.startDateTime,
    required this.endDateTime,
  });

  @override
  State<ConfirmUsingVoucherPage> createState() => _ConfirmUsingVoucherPageState();
}

class _ConfirmUsingVoucherPageState extends State<ConfirmUsingVoucherPage> {
  String selectedPlate = '';

  List<DropdownMenuItem<String>> vehiclePlates = [];

  @override
  void initState() {
    super.initState();
    _fetchVehiclePlates();
  }

  Future<void> _fetchVehiclePlates() async {
    List<DropdownMenuItem<String>> plates = [];
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      List<dynamic> vehicleList = userDoc.data()?['vehicles'] ?? [];
      for (var vehicle in vehicleList) {
        plates.add(DropdownMenuItem<String>(
          value: vehicle['registrationNumber'],
          child: Text(vehicle['registrationNumber']),
        ));
      }
    } catch (e) {
      print("Error fetching vehicle plates: $e");
    }
    setState(() {
      vehiclePlates = plates;
      if (plates.isNotEmpty) {
        selectedPlate = plates.first.value!; 
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat("dd MMMM yyyy");

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context); 
          },
        ),
        title: Image.asset(
          'assets/logomelaka.jpg', 
          height: 60,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Confirmation of Using Rewards',
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold
                ),
              ),
              SizedBox(height: 20),

              // Start Date and Time
              Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.red),
                  SizedBox(width: 10),
                  Text(
                    'Start Date: ${dateFormat.format(widget.startDateTime)}',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.access_time, color: Colors.red),
                  SizedBox(width: 10),
                  Text(
                    'Start Time: ${DateFormat.jm().format(widget.startDateTime)}',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // End Date and Time
              Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.red),
                  SizedBox(width: 10),
                  Text(
                    'End Date: ${dateFormat.format(widget.endDateTime)}',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
              SizedBox(height: 10),

              Row(
                children: [
                  Icon(Icons.access_time, color: Colors.red),
                  SizedBox(width: 10),
                  Text(
                    'End Time: ${DateFormat.jm().format(widget.endDateTime)}',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
              SizedBox(height: 30),

              // Registration Plate
              DropdownButtonFormField<String>(
                value: selectedPlate,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedPlate = newValue!;
                  });
                },
                items: vehiclePlates, 
                decoration: InputDecoration(
                  labelText: "Select Vehicle Plate",
                  prefixIcon: Icon(Icons.directions_car),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                isExpanded: true,
              ),
              SizedBox(height: 30),

              // Confirm Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await _saveParkingHistory(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.all(12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Confirm',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveParkingHistory(BuildContext context) async {
    if (selectedPlate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a vehicle plate.')),
      );
      return;
    }

    try {
      // Check if reward is already used
      DocumentSnapshot rewardDoc = await FirebaseFirestore.instance
          .collection('rewards')
          .doc(widget.rewardId)
          .get();

      if (rewardDoc.exists) {
        Map<String, dynamic>? rewardData = rewardDoc.data() as Map<String, dynamic>?;
        if (rewardData != null && rewardData['isUsed'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('This reward has already been used.')),
          );
          return;
        }
      }

      // Check for active packages
      final activePackagesQuery = await FirebaseFirestore.instance
          .collection('packages_bought')
          .where('vehiclePlateNum', isEqualTo: selectedPlate)
          .where('endTime', isGreaterThan: Timestamp.fromDate(DateTime.now()))
          .get();

      // Check for active parking history
      final activeParkingQuery = await FirebaseFirestore.instance
          .collection('history parking')
          .where('vehiclePlateNum', isEqualTo: selectedPlate)
          .where('endTime', isGreaterThan: Timestamp.fromDate(DateTime.now()))
          .get();

      if (activePackagesQuery.docs.isNotEmpty || activeParkingQuery.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('This vehicle plate is currently in parking. Please select another.')),
        );
        return;
      }

      // Add parking record
      DocumentReference parkingDocRef = await FirebaseFirestore.instance.collection('history parking').add({
        'userID': widget.userId,
        'startTime': Timestamp.fromDate(widget.startDateTime),
        'endTime': Timestamp.fromDate(widget.endDateTime),
        'isUsedByVoucher': true,
        'rewardId': widget.rewardId,
        'location': "All Melaka Area",
        'pricingOption': "Daily",
        'vehiclePlateNum': selectedPlate,
      });

      // Update reward to mark as used
      await FirebaseFirestore.instance
          .collection('rewards')
          .doc(widget.rewardId)
          .update({
        'isUsed': true,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Parking added successfully!')),
      );

      // Navigate back to main page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainPage(userId: widget.userId),
        ),
      );
    } catch (e) {
      print("Error saving parking history: $e"); // Logs the error to the console
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving parking history. Please try again.')),
      );
    }
  }
}