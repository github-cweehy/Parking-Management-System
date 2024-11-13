import 'package:flutter/material.dart';

class ReceiptPage extends StatelessWidget {
  final String district;
  final String startTime;
  final String endTime;
  final double amount;
  final String type;

  ReceiptPage({
    required this.district,
    required this.startTime,
    required this.endTime,
    required this.amount,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Receipt"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Image.asset('assets/logomelaka.jpg', height: 100),
            SizedBox(height: 16),
            Text(
              "Melaka Parking",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text("email: mlkparking@gmail.com"),
            Text("tel: 062531789"),
            Divider(thickness: 2),
            SizedBox(height: 10),
            Text(
              "Time: $startTime - $endTime\nDistrict: $district\nParking Selection: $type",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Divider(thickness: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Total"),
                Text("MYR $amount", style: TextStyle(fontSize: 16)),
              ],
            ),
            Divider(thickness: 2),
            SizedBox(height: 30),
            ElevatedButton.icon(
              icon: Icon(Icons.save),
              label: Text("Save"),
              onPressed: () {
                // Add code to save/download receipt as PDF
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
