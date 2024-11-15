import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:parking_management_system/adminMainPage.dart';
import 'package:parking_management_system/adminProfile.dart';

class EditParkingSelectionPage extends StatefulWidget {
  final String adminId;

  EditParkingSelectionPage({required this.adminId});

  @override
  _EditParkingSelectionPageState createState() => _EditParkingSelectionPageState();
}

class _EditParkingSelectionPageState extends State<EditParkingSelectionPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> hourlyRates = [];
  List<Map<String, dynamic>> dailyRates = [];
  List<Map<String, dynamic>> weeklyRates = [];

  @override
  void initState() {
    super.initState();
    _fetchRatesFromFirebase();
  }

  // get data from Firebase
  void _fetchRatesFromFirebase() async {
    DocumentSnapshot snapshot = await _firestore.collection('parkingRates').doc('rates').get();
    setState(() {
      hourlyRates = List<Map<String, dynamic>>.from(snapshot['hourlyRates']);
      dailyRates = List<Map<String, dynamic>>.from(snapshot['dailyRates']);
      weeklyRates = List<Map<String, dynamic>>.from(snapshot['weeklyRates']);
    });
  }

  // update price rates
  void updateRate(int index, String type, String newDuration, double newPrice) {
    setState(() {
      if (type == 'hourly') {
        hourlyRates[index]['duration'] = newDuration;
        hourlyRates[index]['price'] = newPrice;
      } 
      else if (type == 'daily') {
        dailyRates[index]['duration'] = newDuration;
        dailyRates[index]['price'] = newPrice;
      } 
      else if (type == 'weekly') {
        weeklyRates[index]['duration'] = newDuration;
        weeklyRates[index]['price'] = newPrice;
      }
    });
  }

  // save changes to Firebase
  void saveChanges() async {
    await _firestore.collection('parkingRates').doc('rates').set({
      'hourlyRates': hourlyRates,
      'dailyRates': dailyRates,
      'weeklyRates': weeklyRates,
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Rates saved successfully!')));
  }

  @override
  Widget build(BuildContext context) {
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
                    'admin_username', // 替换为实际用户名变量
                    style: TextStyle(color: Colors.black),
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
                      builder: (context) => AdminMainPage(adminId: widget.adminId),
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

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            buildRateSection('Hourly', hourlyRates, 'hourly'),
            buildRateSection('Daily', dailyRates, 'daily'),
            buildRateSection('Weekly', weeklyRates, 'weekly'),
            SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: saveChanges,
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // update price 
  Widget buildRateSection(String title, List<Map<String, dynamic>> rates, String type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                setState(() {
                  rates.add({'duration': 'New Duration', 'price': 0.0});
                });
              },
            ),
          ],
        ),
        
        ...rates.asMap().entries.map((entry) {
          int index = entry.key;
          Map<String, dynamic> rate = entry.value;
          return ListTile(
            leading: Icon(Icons.access_time, color: Colors.white),
            title: Row(
              children: [
                Expanded(child: Text('${rate['duration']}')),
                SizedBox(width: 10),
                Expanded(child: Text('RM ${rate['price'].toStringAsFixed(2)}')),
              ],
            ),
            trailing: IconButton(
              icon: Icon(Icons.edit),
              onPressed: () async {
                String newDuration = await _showEditDialog(context, rate['duration']);
                double newPrice = double.parse(await _showEditDialog(context, rate['price'].toString()));
                updateRate(index, type, newDuration, newPrice);
              },
            ),
          );
        }).toList(),
      ],
    );
  }

  // pop out edit dialogue box
  Future<String> _showEditDialog(BuildContext context, String currentText) async {
    TextEditingController controller = TextEditingController(text: currentText);
    return await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: 'Enter new value'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
      ),
      child: Text(
        label,
        style: 
          TextStyle(
            color: Colors.white,), 
        ),
    );
  }

  void _logout(BuildContext context) {
    // handle delete 
    
    Navigator.of(context).pop();
  }
}
