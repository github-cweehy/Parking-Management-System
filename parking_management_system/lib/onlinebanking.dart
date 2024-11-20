import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'mainpage.dart';

class OnlineBankingPage extends StatefulWidget {
  final double price;
  final String userId;
  final String? parking;
  final String? packages;


  OnlineBankingPage({this.packages, this.parking, required this.price, required this.userId});

  @override
  State<OnlineBankingPage> createState() => _OnlineBankingPageState();
}

class _OnlineBankingPageState extends State<OnlineBankingPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _accountNameController = TextEditingController();

  Future<void> _saveTransactionToFirebase() async {
  try {
    // Generate unique ID 
    CollectionReference transactions = FirebaseFirestore.instance.collection('transactions');
    QuerySnapshot snapshot = await transactions.where(FieldPath.documentId, isGreaterThanOrEqualTo: 'cp001').get();
    int idCounter = snapshot.size + 1;
    String transactionId = 'ob${idCounter.toString().padLeft(3, '0')}';

    await transactions.doc(transactionId).set({
      'userId': widget.userId,
      'bankName': _bankNameController.text,
      'accountNumber': _accountNumberController.text,
      'accountNameHolder': _accountNameController.text,
      'amount': widget.price,
      'timestamp': FieldValue.serverTimestamp(),
      'paymentMethod': 'Online Banking',
      'packages': widget.packages,
      'parking': widget.parking,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Transaction successfully')),
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MainPage(userId: widget.userId)));
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Transaction failed')),
    );}
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
                  .doc(widget.parking)
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Add your payment information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 20),

              //Bank Name
              TextFormField(
                controller: _bankNameController,
                decoration: InputDecoration(
                  labelText: 'Bank Name',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  )
                ),
              ),
              SizedBox(height: 20),

              //Account Number
              TextFormField(
                controller: _accountNumberController,
                decoration: InputDecoration(
                  labelText: 'Account Number',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  )
                ),
              ),
              SizedBox(height: 20),

              //Account Name
              TextFormField(
                controller: _accountNameController,
                decoration: InputDecoration(
                  labelText: 'Account Holder Name',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  )
                ),
              ),
              SizedBox(height: 20),

              // Confirm Payment button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, // Button color
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: (){
                    if (_formKey.currentState!.validate()) {
                      _saveTransactionToFirebase();
                    }
                  },
                  child: Text(
                    'Confirm Payment : RM ${widget.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ]
          )
        )
      )
    );
  }
}
