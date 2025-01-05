import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chart_plus/flutter_chart.dart';
import 'package:intl/intl.dart';
import 'package:parking_management_system/adminCustomerList.dart';
import 'package:parking_management_system/adminHelp.dart';
import 'package:parking_management_system/adminPBHistory.dart';
import 'package:parking_management_system/adminPBTransactionHistory.dart';
import 'package:parking_management_system/adminPSTransactionHistory.dart';
import 'package:parking_management_system/adminReward.dart';
import 'package:parking_management_system/sa.manageaccount.dart';
import 'adminEditPackagesBought.dart';
import 'adminEditParkingSelection.dart';
import 'adminPSHistory.dart';
import 'adminProfile.dart';
import 'login.dart';

class AdminMainPage extends StatefulWidget {
  final String? superadminId;
  final String? adminId;

  AdminMainPage({required this.superadminId, required this.adminId});

  @override
  State<AdminMainPage> createState() => _AdminMainPageState();
}

class _AdminMainPageState extends State<AdminMainPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String admin_username = '';

  double totalSales = 0;
  double totalParkingTransactions = 0;
  double totalPackagesTransactions = 0;
  int totalParkingCount = 0;
  int totalPackagesCount = 0;
  List<Map<String, dynamic>> dataList = [];

  DateTime? selectedDate;
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();

  Map<DateTime, double> dailyProfitList = {};

  @override
  void initState() {
    super.initState();
    startDate = DateTime.now(); //initialize current date
    endDate = DateTime.now();
    _fetchAdminUsername();
    _fetchSuperAdminUsername();
    _fetchTransactionsData();
  }

  // Fetch superadmin username from Firebase
  void _fetchSuperAdminUsername() async {
    try {
      DocumentSnapshot snapshot = await _firestore.collection('superadmin').doc(widget.superadminId).get();
      if (snapshot.exists && snapshot.data() != null) {
        setState(() {
          admin_username = snapshot['superadmin_username'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $e')),
      );
    }
  }

  // Fetch admin username from Firebase
  void _fetchAdminUsername() async {
    try {
      final adminDoc = await FirebaseFirestore.instance.collection('admins').doc(widget.adminId).get();

      setState(() {
        admin_username = adminDoc.data()?['admin_username'] ?? 'Admin Username';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $e')),
      );
    }
  }

  //get filter data
  Stream<QuerySnapshot> getFilteredData() {
    if (startDate != null && endDate != null) {
      return _firestore
        .collection('transactions')
        .where('timestamp', isGreaterThanOrEqualTo: startDate)
        .where('timestamp', isLessThanOrEqualTo: endDate)
        .snapshots();
    } 
    else {
      return _firestore.collection('transactions').snapshots();
    }
  }

  //selected date
  void _selectDate(BuildContext context, bool isStartDate) async {
    List<DateTime> availableDates = await getAvailableDates();

    if (availableDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No available dates to select.")),
      );
      return;
    }

    DateTime minDate = availableDates.reduce((a, b) => a.isBefore(b) ? a : b);
    DateTime maxDate = availableDates.reduce((a, b) => a.isAfter(b) ? a : b);

    DateTime initialDate = isStartDate ? startDate : endDate;
    if (initialDate.isAfter(maxDate)) {
      initialDate = maxDate;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate, 
      firstDate: minDate,
      lastDate: maxDate,
      selectableDayPredicate: (date) {
        return availableDates.contains(DateTime(date.year, date.month, date.day));
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          startDate = DateTime(picked.year, picked.month, picked.day); 
          
          if (endDate.isBefore(startDate)) {
            endDate = DateTime(startDate.year, startDate.month, startDate.day, 23, 59, 59); 
          }
        }
        else {
          endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59); 
          if (startDate.isAfter(endDate)) {
            startDate = DateTime(endDate.year, endDate.month, endDate.day); 
          }
        }
      });
      _fetchTransactionsData();
    }
  }

  Future<List<DateTime>> getAvailableDates() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('transactions').get();

      List<DateTime> availableDates = snapshot.docs.map((doc) {
        Timestamp timestamp = doc['timestamp'];
        return DateTime(timestamp.toDate().year, timestamp.toDate().month, timestamp.toDate().day);
      }).toList();

      if (availableDates.isEmpty) {
        availableDates.add(DateTime.now());
      }

      return availableDates;

    } catch (e) {
      print("Error fetching available dates: $e");
      return [];
    }
  }

  //fetch sales form firebase
  void _fetchTransactionsData() async {
    try {
      QuerySnapshot transactionsSnapshot = await _firestore
        .collection('transactions')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

      double sales = 0;
      double parkingProfit = 0;
      double packagesProfit = 0;
      int parkingCount = 0;
      int packagesCount = 0;

      //Data grouped by day
      Map<DateTime, double> dailyParkingProfit = {};
      Map<DateTime, double> dailyPackagesProfit = {};

      for (var doc in transactionsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        double amount = data['amount'] ?? 0.0;
        String? parking = data['parking'];
        String? packages = data['packages'];
        DateTime date = (data['timestamp'] as Timestamp).toDate();
        DateTime dateKey = DateTime(date.year, date.month, date.day);

        sales += amount;

        if (parking != null) {
          parkingProfit += amount;
          parkingCount++;
          dailyParkingProfit[dateKey] = (dailyParkingProfit[dateKey] ?? 0) + amount;
        }

        if (packages != null) {
          packagesProfit += amount;
          packagesCount++;
          dailyPackagesProfit[dateKey] = (dailyPackagesProfit[dateKey] ?? 0) + amount;
        }
      }

      //Combine parkingProfit and packagesProfit into dailyProfitList, then send the data to Barchart
      final dailyProfitList = List<Map<String, dynamic>>.from(
         dailyParkingProfit.keys.map((dateKey){
          return {
            'Date': dateKey,
            'parkingProfit': dailyParkingProfit[dateKey] ?? 0.0,
            'packagesProfit': dailyPackagesProfit[dateKey] ?? 0.0,
          };
         }),
      );

      if(dailyProfitList.isEmpty) {
        dailyProfitList.add({
          'Date': DateTime.now(),
          'parkingProfit': 0.0,
          'packagesProfit': 0.0,
        });
      }

      print(dataList);

      setState(() {
        totalSales = sales;
        totalParkingTransactions = parkingProfit;
        totalPackagesTransactions = packagesProfit;
        totalParkingCount = parkingCount;
        totalPackagesCount = packagesCount;
        dataList = dailyProfitList;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching sales data: $e')),
      );
    }
  }

  void _logout(BuildContext context) async {
    try {
      // Sign out from firebase authentication
      await FirebaseAuth.instance.signOut();

      // Navigate to LoginPage and replace current page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } catch (e) {
      // Handle any errors that occur during sign-out
      print("Error sign out: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sign out. Please try again')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
              icon: Icon(Icons.menu, color: Colors.black),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              }),
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
                    admin_username,
                    style: TextStyle(color: Colors.black),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: Colors.black,
                  ),
                ],
              ),
              items: <String>[
                'Profile',
                'Logout'
              ].map((String value) {
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
                      builder: (context) => AdminProfilePage(superadminId: widget.superadminId, adminId: widget.adminId),
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
      drawer: Drawer(
          child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.red,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
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
            leading: Icon(Icons.home, color: Colors.black, size: 23),
            title: Text('Home Page', style: TextStyle(color: Colors.black, fontSize: 16)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminMainPage(superadminId: widget.superadminId, adminId: widget.adminId),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.groups, color: Colors.black),
            title: Text('Manage Admin Account', style: TextStyle(color: Colors.black)),
            onTap: () {
              if (widget.superadminId != null && widget.superadminId!.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ManageAccountPage(superadminId: widget.superadminId, adminId: widget.adminId),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Access Denied: Superadmin Only!')),
                );
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.edit, color: Colors.black, size: 23),
            title: Text('Edit Parking Selection', style: TextStyle(color: Colors.black, fontSize: 16)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditParkingSelectionPage(superadminId: widget.superadminId, adminId: widget.adminId),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.history, color: Colors.black, size: 23),
            title: Text('Parking Selection History', style: TextStyle(color: Colors.black, fontSize: 16)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ParkingSelectionHistoryPage(superadminId: widget.superadminId, adminId: widget.adminId),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.payment, color: Colors.black, size: 23),
            title: Text('Parking Selection Transaction History', style: TextStyle(color: Colors.black, fontSize: 16)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ParkingSelectionTransactionHistoryPage(superadminId: widget.superadminId, adminId: widget.adminId),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.edit, color: Colors.black, size: 23),
            title: Text('Edit Packages Bought', style: TextStyle(color: Colors.black, fontSize: 16)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditPackagesBoughtPage(superadminId: widget.superadminId, adminId: widget.adminId),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.history, color: Colors.black, size: 23),
            title: Text('Packages Bought History', style: TextStyle(color: Colors.black, fontSize: 16)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PackagesBoughtHistoryPage(superadminId: widget.superadminId, adminId: widget.adminId),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.payment, color: Colors.black, size: 23),
            title: Text('Packages Bought Transaction History', style: TextStyle(color: Colors.black, fontSize: 16)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PackagesBoughtTransactionHistoryPage(superadminId: widget.superadminId, adminId: widget.adminId),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.menu_open, color: Colors.black, size: 23),
            title: Text('User Data List', style: TextStyle(color: Colors.black, fontSize: 16)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CustomerListPage(superadminId: widget.superadminId, adminId: widget.adminId),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.celebration_rounded, color: Colors.black, size: 23),
            title: Text('Reward History', style: TextStyle(color: Colors.black, fontSize: 16)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RewardHistoryPage(superadminId: widget.superadminId, adminId: widget.adminId),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.help_outline_sharp, color: Colors.black, size: 23),
            title: Text('Help Center', style: TextStyle(color: Colors.black, fontSize: 16)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserHelpPage(superadminId: widget.superadminId, adminId: widget.adminId),
                ),
              );
            },
          ),
        ],
      )),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, 
              children: [
              //Start Date
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 10.0),
                    child: Text("Start Date", style: TextStyle(fontSize: 13)),
                  ),
                  GestureDetector(
                    onTap: () => _selectDate(context, true),
                    child: Container(
                      width: 185,
                      height: 40,
                      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_month, color: Colors.grey, size: 20),
                          SizedBox(width: 5),
                          //Text
                          Text(
                              "${startDate.day} ${_monthName(startDate.month)} ${startDate.year}",
                              style: TextStyle(color: Colors.black, fontSize: 13.5),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              //End Date
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 10.0),
                    child: Text("End Date", style: TextStyle(fontSize: 13)),
                  ),
                  GestureDetector(
                    onTap: () => _selectDate(context, false),
                    child: Container(
                      width: 185,
                      height: 40,
                      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_month, color: Colors.grey, size: 20),
                          SizedBox(width: 5),
                          //Text
                          Text(
                              "${endDate.day} ${_monthName(endDate.month)} ${endDate.year}",
                              style: TextStyle(color: Colors.black, fontSize: 13.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ]),
            SizedBox(height: 6),
            SizedBox(
              width: 500,
              child: Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.grey.shade400, width: 1.0),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Total Sales',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'RM ${totalSales.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 25),

            //Bar Chart
            Container(
              height: 250,
              padding: EdgeInsets.all(8),
              child: dataList.isEmpty 
                ?Center(child: Text('No data available', style: TextStyle(color: Colors.grey)))
              :ChartWidget(
                coordinateRender: ChartDimensionsCoordinateRender(
                  yAxis: [
                    YAxis(min: 0,max: 1000)
                  ],
                  margin: EdgeInsets.only(left: 40, top: 0, right: 0, bottom: 30),
                  xAxis: XAxis(
                    //avoid count by 0
                    count: dataList.length > 0 ? dataList.length : 1,
                    max: dataList.length.toDouble(),
                    formatter: (index) {
                      if(dataList.isEmpty) {
                        return 'No Data';
                      }
                      final DateTime date = dataList[index.toInt()]['Date'] as DateTime;
                      return DateFormat('dd').format(date);
                    },
                  ), 
                  charts: [
                    StackBar(
                      data: dataList,
                      colors: [Colors.blue, Colors.green],
                      position: (item) {
                        final DateTime date = item['Date'] as DateTime;
                        final daysDifference = date.difference(startDate).inDays;

                        return daysDifference.clamp(0, dataList.length - 1).toDouble(); 
                      },
                      direction: Axis.horizontal,
                      itemWidth: 18,
                      highlightColor: Colors.red,
                      values: (item) => [
                        item['parkingProfit'] ?? 0.0,
                        item['packagesProfit'] ?? 0.0,
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 6),
            
            Card(
              color: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.red, width: 1.0),
              ),
              child: Container(
                width: 500,
                height: 120,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Parking',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Profit : RM ${totalParkingTransactions.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Sales : $totalParkingCount',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
            Card(
              color: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.red, width: 1.0),
              ),
              child: Container(
                width: 500,
                height: 120,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Packages',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Profit : RM ${totalPackagesTransactions.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Sales : $totalPackagesCount',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  String _monthName(int month) {
    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return monthNames[month - 1];
  }
}

extension DateTimeFormatting on DateTime {
  String toStringWithFormat({required String format}) {
    return DateFormat(format).format(this);
  }
}


