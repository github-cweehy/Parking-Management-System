import 'package:flutter/material.dart';

class AdminNavigator extends StatelessWidget{
  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),

        title: Image.asset(
          'assets/logomelaka.jpg',
          height: 40,
        ),
        centerTitle: true,
      ),
    );
  }
}

class DrawerMenu extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          //Admin Profile
          ListTile(
            leading: Icon(Icons.person),
            title: Text('Admin Profile', style: TextStyle(fontWeight: FontWeight.bold),),
            onTap: () {
              //Navigator to Admin Profile Page
            },
          ),

          //Manage Admin Profile
          ListTile(
            leading: Icon(Icons.account_circle),
            title: Text('Manage Admin Account', style: TextStyle(fontWeight: FontWeight.bold),),
            onTap: () {
              //Navigator to Manage Admin Account Page
            },
          ),

          //Parking Selection List Option
          ExpansionTile(
            leading: Icon(Icons.list),
            title: Align(
              alignment: Alignment.centerLeft,
              child: Text('Parking Selection', style: TextStyle(fontWeight: FontWeight.bold),),
            ),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: ListTile(
                  leading: Icon(Icons.create),
                  title: Text('Edit Parking Selection'),
                  onTap: () {
                    //Navigator to Edit Selection Page
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: ListTile(
                  leading: Icon(Icons.history),
                  title: Text('Parking Selection History'),
                  onTap: () {
                    //Navigator to Parking Selection History Page
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: ListTile(
                  leading: Icon(Icons.receipt_long_rounded),
                  onTap: () {
                    //Navigator to Payement History Page
                  },
                ),
              ),
            ],
          ),

          //Packages Bought List Option
          ExpansionTile(
            leading: Icon(Icons.list),
            title: Align(
              alignment: Alignment.centerLeft,
              child: Text('Packages Bought', style: TextStyle(fontWeight: FontWeight.bold),),
            ),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: ListTile(
                  leading: Icon(Icons.create),
                  title: Text('Edit Packges Bought'),
                  onTap: () {
                    //Navigator Edit Packages Bought Page
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: ListTile(
                  leading: Icon(Icons.history),
                  title: Text('Packages Bought History'),
                  onTap: () {
                    //Navigator to Packages History Page
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: ListTile(
                  leading: Icon(Icons.receipt_long_rounded),
                  title: Text('Payment History'),
                  onTap: () {
                    //Navigator to Packages History Page
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}