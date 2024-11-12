import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:parking_management_system/eWallet.dart';
import 'package:parking_management_system/onlinebanking.dart';
import 'creditcard.dart';
import 'userprofile.dart'; 
import 'login.dart'; 

class PaymentMethodPage extends StatefulWidget{
  final String userId;
  final String userparkingselectionID;
  final double price;

  PaymentMethodPage({required this.userparkingselectionID, required this.userId, required this.price});

  @override
  _PaymentMethodPageState createState() => _PaymentMethodPageState();

}

class _PaymentMethodPageState extends State<PaymentMethodPage>{
  String username = '';

  @override
  void initState() {
    super.initState();
    _fetchUsername();
  }

  Future<void> _fetchUsername() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      setState(() {
        username = userDoc.data()?['username'] ?? 'Username';
      });
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
      
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: 
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Payment Method",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () async {
                try {
                  // Use the userParkingSelectionID to update the correct document
                  DocumentReference parkingSelectionDocRef = FirebaseFirestore.instance
                      .collection('history parking')
                      .doc(widget.userparkingselectionID);  // Use the passed ID

                  await parkingSelectionDocRef.update({
                    'payment method': 'Card Payment',
                  });
                  print("Data saved successfully.");

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CardPaymentPage(price:widget.price, userId: widget.userId),
                      ),
                    );
                } catch(e){
                  print("Error saving data: $e");
                }
              }, 
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    "Card Payment",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                   Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
            SizedBox(height: 40),

            ElevatedButton(
              onPressed: () async {
                try {
                  // Use the userParkingSelectionID to update the correct document
                  DocumentReference parkingSelectionDocRef = FirebaseFirestore.instance
                      .collection('history parking')
                      .doc(widget.userparkingselectionID);  // Use the passed ID

                  await parkingSelectionDocRef.update({
                    'payment method': 'Online Banking',
                  });
                  print("Data saved successfully.");

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OnlineBankingPage(price:widget.price, userId: widget.userId),
                      ),
                    );
                } catch(e){
                  print("Error saving data: $e");
                }
              }, 
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    "Online Banking",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                   Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
            SizedBox(height: 40),

            ElevatedButton(
              onPressed: () async {
                try {
                  // Use the userParkingSelectionID to update the correct document
                  DocumentReference parkingSelectionDocRef = FirebaseFirestore.instance
                      .collection('history parking')
                      .doc(widget.userparkingselectionID);  // Use the passed ID

                  await parkingSelectionDocRef.update({
                    'payment method': 'E-wallet',
                  });
                  print("Data saved successfully.");

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EWalletPaymentPage(price:widget.price, userId: widget.userId),
                      ),
                    );
                } catch(e){
                  print("Error saving data: $e");
                }
              }, 
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    "E-wallet             ",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                   Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
            SizedBox(height: 70),
            CancelButton(),
          ],
        ),
      ),
    );
  }
}

class CancelButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 300,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: EdgeInsets.symmetric(vertical: 10),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cancel,
                color: Colors.white,
              ),
              SizedBox(width: 10),
              Text(
                'Cancel Payment',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}