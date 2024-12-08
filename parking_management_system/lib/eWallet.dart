import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:parking_management_system/mainpage.dart';

class EWalletPaymentPage extends StatefulWidget {
  final double price;
  final String userId;
  final String? parking;
  final String? packages;

  EWalletPaymentPage({this.packages,this.parking, required this.price, required this.userId});

  @override
  State<EWalletPaymentPage> createState() => _EWalletPaymentPageState();
}

class _EWalletPaymentPageState extends State<EWalletPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  String? _selectedEWallet; // To store the selected e-wallet

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveEWalletTransactionToFirebase() async {
    try {
      CollectionReference transactions = FirebaseFirestore.instance.collection('transactions');
      QuerySnapshot snapshot = await transactions.where(FieldPath.documentId, isGreaterThanOrEqualTo: 'ew001').get();
      int idCounter = snapshot.size + 1;
      String transactionId = 'ew${idCounter.toString().padLeft(3, '0')}';

      await transactions.doc(transactionId).set({
        'userId': widget.userId,
        'phone': _phoneController.text,
        'selectedEWallet': _selectedEWallet,
        'amount': widget.price,
        'timestamp': FieldValue.serverTimestamp(),
        'paymentMethod': 'E-Wallet',
        'packages': widget.packages,
        'parking': widget.parking,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('E-wallet transaction successful')),
      );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MainPage(userId: widget.userId)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('E-wallet transaction failed')),
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
                  'Add your e-wallet payment information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 20),

              // E-wallet selection dropdown
              DropdownButtonFormField<String>(
                value: _selectedEWallet,
                decoration: InputDecoration(
                  labelText: 'Select E-Wallet',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: ['PayNet', 'Boost', 'Touch \'n Go', 'GrabPay']
                    .map((wallet) => DropdownMenuItem(
                          value: wallet,
                          child: Text(wallet),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedEWallet = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select an e-wallet';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),

              // Phone number Input
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  final RegExp phoneRegExp = RegExp(r'^\d{10,11}$');
                  if (!phoneRegExp.hasMatch(value)) {
                    return 'Please enter a valid phone number (10-11 digits)';
                  }
                  return null;
                },
              ),
              SizedBox(height: 40),

              // Confirm Payment button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _saveEWalletTransactionToFirebase();
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
            ],
          ),
        ),
      ),
    );
  }
}
