import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'mainpage.dart';
import 'paymentmethod.dart';


class AddParkingPage extends StatefulWidget {
  final String userId;
  final String location;
  final String userparkingselectionID;
  final String pricingOption;

  AddParkingPage({required this.userparkingselectionID, required this.location, required this.pricingOption, required this.userId});

  @override
  _AddParkingPageState createState() => _AddParkingPageState();
}

class _AddParkingPageState extends State<AddParkingPage> {
  String username = '';
  List<String> vehiclePlates = [];
  String selectedPlate = '';
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();
  TimeOfDay startTime = TimeOfDay(hour: 9, minute: 0);
  TimeOfDay endTime = TimeOfDay(hour: 10, minute: 0);
  double price = 0.0;
  TextEditingController registrationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchVehiclePlates();
    _fetchPricing();
    AwesomeNotifications().isNotificationAllowed().then((isAllowed){
      if(!isAllowed){
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

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

Future<void> _fetchPricing() async {
  try {
    final pricingDoc = await FirebaseFirestore.instance
        .collection('parkingselection')
        .doc(widget.pricingOption) 
        .get();

    if (pricingDoc.exists) {
      setState(() {
        // Fetch the price values from Firestore document
        price = pricingDoc.data()?['price'] ?? 0.0;
      });
    }
  } catch (e) {
    print("Error fetching pricing: $e");
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
        price = price; // Base price for the first hour
      } else {
        final int extraMinutes = durationMinutes - 60;
        // Calculate number of half-hours, rounding up
        int halfHours = (extraMinutes / 30).ceil();
        price = price + (halfHours * 0.40); // Add half-hourly charge
      }
    } else {
      // Handle the price for daily, weekly, or other pricing options
      setState(() {});
    }
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

  Future<void> updateUserPurchaseCount() async {
    try {
      DocumentReference userDocRef = FirebaseFirestore.instance.collection('users').doc(widget.userId);
      DocumentSnapshot userDoc = await userDocRef.get();

      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

      int purchaseCount = userData?['purchaseCount'] ?? 0;
      purchaseCount++;

      // Update the purchase count 
      await userDocRef.update({'purchaseCount': purchaseCount});

      // Check if the user is eligible for a reward
      if (purchaseCount % 10 == 0) {
        // Grant a free daily parking reward
        await _generateReward();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Congratulations! You have earned a free daily parking!')),
        );
      }
    } catch (e) {
      print("Error updating purchase count: $e");
    }
}

  Future<void> _generateReward() async {
    try {
      DocumentReference userDocRef = FirebaseFirestore.instance.collection('users').doc(widget.userId);
      
      DocumentReference rewardDocRef = FirebaseFirestore.instance.collection('rewards').doc();

      Map<String, dynamic> RewardData = {
        'userId': widget.userId,
        'rewardCode': rewardDocRef.id, 
        'isUsed': false,
        'createdAt': FieldValue.serverTimestamp(),
        'expiryDate': DateTime.now().add(Duration(days: 30)),
      };

      await rewardDocRef.set(RewardData);

      await userDocRef.update({
        'Free parking': FieldValue.arrayUnion([rewardDocRef.id]), 
      });

    } catch (e) {
      print("Error generating reward: $e");
    }
  }

  Future<bool> _hasActivePackage(String vehiclePlateNum) async {
    try {
      DateTime now = DateTime.now();
      QuerySnapshot activePackages = await FirebaseFirestore.instance
          .collection('packages bought')
          .where('vehiclePlateNum', isEqualTo: vehiclePlateNum)
          .where('endDate', isGreaterThan: now) 
          .get();

      return activePackages.docs.isNotEmpty; 
    } catch (e) {
      print("Error checking active packages: $e");
      return false; 
    }
  }

  void scheduleNotification() {
    final now = DateTime.now();
    final parkingEndTime = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      endTime.hour,
      endTime.minute,
    );

    final notificationTime = parkingEndTime.subtract(Duration(minutes: 3));

    if (notificationTime.isAfter(now)) {
      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 10,
          channelKey: 'basic_channel',
          title: 'Parking Expiring Soon',
          body: 'Your parking is expiring in 3 minutes.',
        ),
        schedule: NotificationCalendar.fromDate(date: notificationTime),
      );
    } else{
      print('Notification time is in the past or invalid.');
    }
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
          onPressed: () async {
            try {
              // Fetch the parking document
              DocumentSnapshot parkingDoc = await FirebaseFirestore.instance
                  .collection('history parking')
                  .doc(widget.userparkingselectionID)
                  .get();

              // Check if the document exists and has the "temporary" status
              if (parkingDoc.exists) {
                Map<String, dynamic>? data = parkingDoc.data() as Map<String, dynamic>?;
                if (data != null && data['status'] == 'temporary') {
                  // Delete the document
                  await FirebaseFirestore.instance
                      .collection('history parking')
                      .doc(widget.userparkingselectionID)
                      .delete();

                  print("Temporary parking entry deleted.");
                }
              }

              // Navigate back to the main page
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => MainPage(userId: widget.userId),
                ),
              );
            } catch (e) {
              // Handle any errors during the process
              print("Error checking or deleting temporary parking: $e");
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error deleting temporary parking. Please try again.')),
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

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                      onTap: widget.pricingOption == "Weekly" ? null : () => _selectDate(context, false),
                      child: AbsorbPointer(
                        child: TextField(
                              readOnly:true,
                              decoration: InputDecoration(
                                labelText: "Date",
                                filled: true,
                                fillColor: Colors.grey[200],
                                prefixIcon: Icon(Icons.access_time),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              controller: TextEditingController(text: dateFormat.format(endDate)),
                            )
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
                        : widget.pricingOption == "Daily" || widget.pricingOption == "Weekly"
                            ? GestureDetector(
                              child: AbsorbPointer(
                                child: TextField(
                                  readOnly:true,
                                  decoration: InputDecoration(
                                    labelText: "Time",
                                    filled: true,
                                    fillColor: Colors.grey[200],
                                    prefixIcon: Icon(Icons.access_time),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  controller: TextEditingController(text: "05:00 PM"),
                                ),
                              )
                            )
                            : SizedBox(),
                        
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Registration Plate
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
                    onPressed: () async {
                      try {
                        bool hasActivePackage = await _hasActivePackage(selectedPlate);
                        if (hasActivePackage) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('This vehicle has an active package. Cannot add parking.')),
                          );
                          return; 
                        }

                        DateTime startDateTime = DateTime(
                          startDate.year, startDate.month, startDate.day, startTime.hour, startTime.minute);
                        DateTime endDateTime = DateTime(
                          endDate.year, endDate.month, endDate.day, endTime.hour, endTime.minute);

                        // Check if there's any ongoing parking session for the same plate number
                        QuerySnapshot ongoingParkings = await FirebaseFirestore.instance
                            .collection('history parking')
                            .where('vehiclePlateNum', isEqualTo: selectedPlate)
                            .where('endTime', isGreaterThan: DateTime.now().toString())
                            .get();

                        if (ongoingParkings.docs.isNotEmpty) {
                          // If there are unexpired parking sessions, show an error message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('This vehicle already has an active parking session.')),
                          );
                          return;
                        }

                        // Proceed to save the parking details if no conflicts are found
                        DocumentReference parkingSelectionDocRef = FirebaseFirestore.instance
                            .collection('history parking')
                            .doc(widget.userparkingselectionID);

                        await parkingSelectionDocRef.update({
                          'vehiclePlateNum': selectedPlate,
                          'price': price.toStringAsFixed(2),
                          'startTime': Timestamp.fromDate(startDateTime),
                          'endTime': Timestamp.fromDate(endDateTime),
                          'status' : 'temporary',
                        });

                        print("Data saved successfully.");

                        await updateUserPurchaseCount();
                        scheduleNotification();

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PaymentMethodPage(
                              userId: widget.userId, 
                              price:price, 
                              userparkingselectionID: widget.userparkingselectionID,
                              source: 'history',
                              ),
                            ),
                          );
                      } catch(e){
                        print("Error saving data: $e");
                      }
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

  @override
  void dispose() {
    registrationController.dispose();
    super.dispose();
  }
}



