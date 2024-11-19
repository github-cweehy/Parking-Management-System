import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:parking_management_system/adminProfile.dart';

class EditParkingSelectionPage extends StatefulWidget {
  final String adminId;

  EditParkingSelectionPage({required this.adminId});

  @override
  _EditParkingSelectionPageState createState() =>
      _EditParkingSelectionPageState();
}

class _EditParkingSelectionPageState extends State<EditParkingSelectionPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String adminUsername = '';

  Map<String, dynamic> hourlyRates = {};
  Map<String, dynamic> dailyRates = {};
  Map<String, dynamic> weeklyRates = {};
  Map<String, dynamic> halflyRates = {};

  @override
  void initState() {
    super.initState();
    _fetchRatesFromFirebase();
    _fetchAdminUsername();
  }

  // 获取管理员用户名
  void _fetchAdminUsername() async {
    try {
      DocumentSnapshot snapshot =
          await _firestore.collection('admins').doc(widget.adminId).get();
      if (snapshot.exists && snapshot.data() != null) {
        setState(() {
          adminUsername = snapshot['admin_username'];
        });
      }
    } catch (e) {
      print("Error fetching admin username: $e");
    }
  }

  // 获取停车费率数据
  void _fetchRatesFromFirebase() async {
    try {
      // 获取每个费率类型的数据
      DocumentSnapshot hourlySnapshot = await _firestore
          .collection('parkingselection')
          .doc('Hourly')
          .get();
      DocumentSnapshot dailySnapshot = await _firestore
          .collection('parkingselection')
          .doc('Daily')
          .get();
      DocumentSnapshot weeklySnapshot = await _firestore
          .collection('parkingselection')
          .doc('Weekly')
          .get();
      DocumentSnapshot halflySnapshot = await _firestore
          .collection('parkingselection')
          .doc('Halfly')
          .get();

      // 将每个文档数据转换为 Map<String, dynamic> 格式
      if (hourlySnapshot.exists && hourlySnapshot.data() != null) {
        setState(() {
          hourlyRates =
              Map<String, dynamic>.from(hourlySnapshot.data() as Map);
        });
      }
      if (dailySnapshot.exists && dailySnapshot.data() != null) {
        setState(() {
          dailyRates =
              Map<String, dynamic>.from(dailySnapshot.data() as Map);
        });
      }
      if (weeklySnapshot.exists && weeklySnapshot.data() != null) {
        setState(() {
          weeklyRates =
              Map<String, dynamic>.from(weeklySnapshot.data() as Map);
        });
      }
      if (halflySnapshot.exists && halflySnapshot.data() != null) {
        setState(() {
          halflyRates =
              Map<String, dynamic>.from(halflySnapshot.data() as Map);
        });
      }
    } catch (e) {
      print("Error fetching rates: $e");
    }
  }

  // 保存修改后的停车费率
  void saveChanges() async {
    try {
      // 保存停车费率数据
      await _firestore.collection('parkingselection').doc('Hourly').set(hourlyRates);
      await _firestore.collection('parkingselection').doc('Daily').set(dailyRates);
      await _firestore.collection('parkingselection').doc('Weekly').set(weeklyRates);
      await _firestore.collection('parkingselection').doc('Halfly').set(halflyRates);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Rates saved successfully!'),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to save rates: $e'),
      ));
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
            Scaffold.of(context).openDrawer();
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
                    adminUsername,
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
                      builder: (context) =>
                          AdminProfilePage(adminId: widget.adminId),
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
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios, color: Colors.black),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                SizedBox(width: 10),
                Text(
                  "Edit Parking Selection",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 30),
            buildRateSection('Hourly', hourlyRates),
            buildRateSection('Daily', dailyRates),
            buildRateSection('Weekly', weeklyRates),
            buildRateSection('Halfly', halflyRates),
            Spacer(),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: ElevatedButton(
                  onPressed: saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: EdgeInsets.symmetric(horizontal: 35, vertical: 10),
                  ),
                  child: Text('Save', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建费率区块
  Widget buildRateSection(String title, Map<String, dynamic> rates) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: Icon(Icons.add_circle_outline, color: Colors.black),
                  onPressed: () {
                    addNewRate(title);
                  },
                ),
              ],
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: rates.length,
              itemBuilder: (context, index) {
                String duration = rates.keys.elementAt(index);
                double price = rates[duration];
                return ListTile(
                  title: Text('$duration'),
                  subtitle: Text('\$${price.toStringAsFixed(2)}'),
                  trailing: IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () async {
                      var result = await _showEditDialog(
                        context,
                        duration,
                        price.toString(),
                      );
                      if (result != null) {
                        setState(() {
                          rates[duration] = double.tryParse(result[1]) ?? price;
                        });
                      }
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // 编辑对话框
  Future<List<String>?> _showEditDialog(
      BuildContext context, String currentDuration, String currentPrice) {
    TextEditingController durationController = TextEditingController(text: currentDuration);
    TextEditingController priceController = TextEditingController(text: currentPrice);

    return showDialog<List<String>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit $currentDuration Rate'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: durationController,
                decoration: InputDecoration(labelText: 'Duration'),
              ),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Price'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, [durationController.text, priceController.text]);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // 添加新费率
  void addNewRate(String rateType) {
    // 根据需要实现
  }

  // 退出登录
  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }
}
