import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'userprofile.dart'; 
import 'login.dart'; 


class AddParkingPage extends StatefulWidget {
  final String userId;
  final String location;
  final String pricingOption;

  AddParkingPage({required this.location, required this.pricingOption, required this.userId});

  @override
  _AddParkingPageState createState() => _AddParkingPageState();
}

class _AddParkingPageState extends State<AddParkingPage> {
  String username = '';
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();
  TimeOfDay startTime = TimeOfDay(hour: 9, minute: 0);
  TimeOfDay endTime = TimeOfDay(hour: 10, minute: 0);
  double price = 0.0;
  TextEditingController registrationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUsername();
    _setInitialDatesAndPrice();
  }

  Future<void> _fetchUsername() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      setState(() {
        username = userDoc.data()?['username'] ?? '';
      });
    } catch (e) {
      print("Error fetching username: $e");
    }
  }


  void _setInitialDatesAndPrice() {
    if (widget.pricingOption == "Weekly") {
      endDate = startDate.add(Duration(days: 7));
      price = 23.00;
    } else if (widget.pricingOption == "Daily") {
      endDate = startDate;
      price = 5.00;
    } else if (widget.pricingOption == "Hourly") {
      endDate = startDate;
      price = 1.00; // Base price for the first hour
    }
  }

  void _updateEndDate() {
    if (widget.pricingOption == "Weekly") {
      setState(() {
        endDate = startDate.add(Duration(days: 7));
      });
    } else {
      setState(() {
        endDate = startDate;
      });
    }
  }

  void _updatePrice() {
    if (widget.pricingOption == "Hourly") {
      final int startMinutes = startTime.hour * 60 + startTime.minute;
      final int endMinutes = endTime.hour * 60 + endTime.minute;
      final int durationMinutes = endMinutes - startMinutes;

      if (durationMinutes <= 60) {
        price = 1.00;
      } else {
        final int extraMinutes = durationMinutes - 60;
        // Calculate number of half-hours, rounding up
        int halfHours = (extraMinutes / 30).ceil();
        price = 1.00 + (halfHours * 0.40);
      }
    }
    setState(() {});
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime initialDate = isStart ? startDate : endDate;
    final DateTime firstDate = isStart ? DateTime.now() : startDate;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
          _updateEndDate();
        } else {
          endDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay initialTime = isStart ? startTime : endTime;
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          startTime = picked;
        } else {
          endTime = picked;
        }
        if (widget.pricingOption == "Hourly") {
          _updatePrice();
        }
      });
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
    final dateFormat = DateFormat("d MMMM yyyy");
    final timeFormat = DateFormat.jm();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.black),
          onPressed: () {
            // Handle menu press
          },
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            // crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location and Pricing Option
              Row(
                children: [
                  Icon(Icons.location_pin, color: Colors.red, size: 30),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.location,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.pricingOption,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30),
              
              // Start Date and Time
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Start Date & Time",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  // Start Date
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectDate(context, true),
                      child: AbsorbPointer(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: "Date",
                            prefixIcon: Icon(Icons.calendar_today),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          controller: TextEditingController(text: dateFormat.format(startDate)),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  // Start Time
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectTime(context, true),
                      child: AbsorbPointer(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: "Time",
                            prefixIcon: Icon(Icons.access_time),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          controller: TextEditingController(text: startTime.format(context)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // End Date and Time (Conditional)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "End Date & Time",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  // End Date
                  Expanded(
                    child: GestureDetector(
                      onTap: widget.pricingOption == "Weekly" ? () => _selectDate(context, false) : null,
                      child: AbsorbPointer(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: "Date",
                            prefixIcon: Icon(Icons.calendar_today),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          controller: TextEditingController(text: dateFormat.format(endDate)),
                          enabled: widget.pricingOption == "Weekly",
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  // End Time
                  Expanded(
                    child: widget.pricingOption == "Hourly"
                        ? GestureDetector(
                            onTap: () => _selectTime(context, false),
                            child: AbsorbPointer(
                              child: TextField(
                                decoration: InputDecoration(
                                  labelText: "Time",
                                  prefixIcon: Icon(Icons.access_time),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                controller: TextEditingController(text: endTime.format(context)),
                              ),
                            ),
                          )
                        : widget.pricingOption == "Daily"
                            ? Text(
                                "17:00",
                                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                              )
                            : SizedBox(),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Registration Plate
              TextField(
                controller: registrationController,
                decoration: InputDecoration(
                  labelText: "Registration Plate",
                  prefixIcon: Icon(Icons.directions_car),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              SizedBox(height: 30),

              // Price Display
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Price: RM ${price.toStringAsFixed(2)}",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      // Handle parking addition
                      // You can add validation and submission logic here
                    },
                    icon: Icon(Icons.add_circle, color: Colors.white),
                    label: Text(
                      widget.pricingOption == "Weekly" ? "Add Parking & Pay" : "Add Parking",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
