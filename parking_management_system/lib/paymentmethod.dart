import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'eWallet.dart';
import 'onlinebanking.dart';
import 'creditcard.dart';
import 'history.dart';
import 'mainpage.dart';
import 'userprofile.dart'; 
import 'login.dart'; 

class PaymentMethodPage extends StatefulWidget{
  final String userId;
  final String? userparkingselectionID;
  final double price;
  final String? duration;
  final String source;
  final String? packageId;

  PaymentMethodPage({
    this.packageId, 
    required this.source, 
    this.duration, 
    this.userparkingselectionID, 
    required this.userId, 
    required this.price
    }
  );

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
          icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () async{
              try {
                await FirebaseFirestore.instance
                  .collection('history parking')
                  .doc(widget.userparkingselectionID)
                  .delete();
                
                await FirebaseFirestore.instance
                  .collection('packages_bought')
                  .doc(widget.packageId)
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
      // Add the drawer here
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
                    builder: (context) => HistoryPage(
                      userId: widget.userId,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
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
                  // Determine the collection and document ID
                  String collection = widget.source == 'history' ? 'history parking' : 'packages_bought';
                  String? documentId = widget.source == 'history' 
                      ? widget.userparkingselectionID 
                      : widget.packageId;

                  if (documentId == null) {
                    throw "Document ID is null for the selected source.";
                  }

                  DocumentReference docRef = FirebaseFirestore.instance.collection(collection).doc(documentId);
                  
                  await docRef.update({
                    'payment method': 'Card Payment',
                    'status': 'confirmed',
                  });
                  print("Data saved successfully.");

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CardPaymentPage(
                        packages:widget.packageId, 
                        parking:widget.userparkingselectionID, 
                        price:widget.price, 
                        userId: widget.userId
                        ),
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
                  // Determine the collection and document ID
                  String collection = widget.source == 'history' ? 'history parking' : 'packages_bought';
                  String? documentId = widget.source == 'history' 
                      ? widget.userparkingselectionID 
                      : widget.packageId;

                  if (documentId == null) {
                    throw "Document ID is null for the selected source.";
                  }

                  DocumentReference docRef = FirebaseFirestore.instance.collection(collection).doc(documentId);

                  await docRef.update({
                    'payment method': 'Online Banking',
                    'status': 'confirmed',
                  });
                  print("Data saved successfully.");

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OnlineBankingPage(
                        packages:widget.packageId, 
                        parking:widget.userparkingselectionID, 
                        price:widget.price, 
                        userId: widget.userId
                        ),
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
                  // Determine the collection and document ID
                  String collection = widget.source == 'history' ? 'history parking' : 'packages_bought';
                  String? documentId = widget.source == 'history' 
                      ? widget.userparkingselectionID 
                      : widget.packageId;

                  if (documentId == null) {
                    throw "Document ID is null for the selected source.";
                  }

                  DocumentReference docRef = FirebaseFirestore.instance.collection(collection).doc(documentId);
                  
                  await docRef.update({
                    'payment method': 'E-wallet',
                    'status': 'confirmed',
                  });
                  print("Data saved successfully.");

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EWalletPaymentPage(
                        packages:widget.packageId, 
                        parking:widget.userparkingselectionID, 
                        price:widget.price, 
                        userId: widget.userId
                        ),
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
            CancelButton(
              source:widget.source, 
              userParkingSelectionID: 
              widget.userparkingselectionID, 
              userId: widget.userId,
              packageId: widget.packageId,
            ),
          ],
        ),
      ),
    );
  }
}

class CancelButton extends StatelessWidget {
  final String? userParkingSelectionID;
  final String userId;
  final String? packageId;
  final String source;

  CancelButton({this.userParkingSelectionID, this.packageId, required this.userId, required this.source});

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
          onPressed: () async {
            try {
              String collection = source == 'history' ? 'history parking' : 'packages_bought';
              String? documentId = source == 'history' ? userParkingSelectionID : packageId;
              
              if (documentId == null) {
                throw "Document ID is null for the selected source.";
              }

              if (packageId != null) {
                await FirebaseFirestore.instance
                    .collection('packages_bought')
                    .doc(packageId)
                    .delete();
                print("Packages bought document deleted.");
              }

              await FirebaseFirestore.instance.collection(collection).doc(documentId).delete();
              print("Document deleted successfully.");

              // Navigate back to the main page
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => MainPage(userId: userId),
                ),
              );
            } catch (e) {
              print("Error deleting document: $e");
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error canceling payment. Please try again.')),
              );
            }
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