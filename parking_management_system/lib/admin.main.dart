import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:parking_management_system/adminProfile.dart';

void main()
{
  runApp(MyApp());
}

class MyApp extends StatelessWidget
{
  @override
  Widget build(BuildContext context)
  {
    return MaterialApp
    (
      home: adminMainPage(),
    );
  }
}

class AdminMainPage extends StatelessWidget
{
  final String username = 'Admin';

  @override
  Widget build(BuildContext context)
  {
    return Scaffold
    (
      appBar: AppBar
      (
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton
        (
          icon: Icon(Icons.menu, color: Colors.black),
          onPressed: ()
          {
            //Handle menu press
          },
        ),
       
        title: Image.asset
        (
          'assets/logomelaka.jpg',
          height: 60,
        ),
        centerTitle: true,
        actions: 
        [
          Padding
          (
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButton<String>
            (
              underline: SizedBox(),
              icon: Row
              (
                children: 
                [
                  Text
                  (
                    username,
                    style: TextStyle(color: Colors.black),
                  ),

                  Icon
                  (
                    Icons.arrow_drop_down,
                    color: Colors.black,
                  ),
                ],
              ),

              items: <String>['Profile', 'Logout'].map((String value)
              {
                return DropdownMenuItem<String>
                (
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? value)
              {
                if(value == 'Profile')
                {
                  Navigator.push
                  (
                    context, 
                    MaterialPageRoute
                    (
                      builder: (context) => AdminProfilePage(),
                    ),
                  );
                }

                else if(value == 'Logout')
                {
                  _logout(context);
                }
              },
            ),
          )
        ],
      ),

      body: Padding
      (
        padding: const EdgeInsets.all(16.0)
        child: Column
        (
          children: 
          [
            //Parking Selection Card
            CustomCard
            (
              title: 'Parking Selection',
              options: 
              [
                OptionItem
                (
                  icon: Icons.edit, 
                  text: 'Edit Parking Selection',
                  onTap:()
                  {
                    //Handle Edit Parking Selection tap
                  }
                ),

                OptionItem
                (
                  icon: Icons.history, 
                  text: 'Parking Selection History', 
                  onTap:()
                  {
                    //Handle Parking Selection History tap
                  }
                ),

                OptionItem
                (
                  icon: Icons.payment, 
                  text: 'Payment History', 
                  onTap:()
                  {
                    //Handle Payment History tap
                  }
                ),
              ],
            ),
            SizedBox(height: 20),

            //Packages Bought
            CustomCard
            (
              title: 'Packages Bought',
              options: 
              [
                OptionItem
                (
                  icon: Icons.edit, 
                  text: 'Edit Packages Bought', 
                  onTap:()
                  {
                    //Handle Edit Packages Bought tap
                  }
                ),

                OptionItem
                (
                  icon: Icons.history, 
                  text: 'Packages Bought History', 
                  onTap:()
                  {
                    //Handle Packages Bought History tap
                  }
                ),

                OptionItem
                (
                  icon: Icons.payment, 
                  text: 'Payment History', 
                  onTap:()
                  {
                    //Handle Payement History tap
                  }
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _logout(BuildContext context) async
  {
    try
    {
      //Sign out from Firebase Authentication
      await FirebaseAuth.instance.signOut();

      //Navigate to LoginPage and replace the current page
      Navigator.pushReplacement
      (
        context, 
        MaterialPageRoute(builder: (context)=> LoginPage()),
      );
    }catch(e)
    {
      //Handle any errors that occur during sign-out
      print("Error singing out: $e");

      ScaffoldMessenger.of(context).showSnackBar
      (
        SnackBar(content: Text('Error Signing out. Please try again.')),
      );
    }
  }

  //Placeholder for AdminProfilePage widget
  class AdminProfilePage extends StatelessWidget
  {
    @override
    Widget build(BuildContext context)
    {
      return Scaffold
      (
        appBar: AppBar(title: Text('Admin Profile')),
        body: Center(child: Text('Profile Page')),
      );
    }
  }

  class CustomCard extends StatelessWidget
  {
    final String title;
    final List<OptionItem>options;

    CustomCard({required this.title, required this.options});

    @override
    Widget build(BuildContext context)
    {
      return Card
      (
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding
        (
          padding: const EdgeInsets.all(16.0)
        ),

        child: Column
        (
          crossAxisAlignment: CrossAxisAlignment.start,

          children: 
          [
            Text
            ( 
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Column
            (
              children: options,
            ),
          ],
        ),
      );
    }
  }

  class OptionItem extends StatelessWidget
  {
    final IconData icon;
    final String text;
    final VoidCallBack onTap;

    OptionItem
    (
      {required this.icon, required this.text, required this.onTap}
    );

    @override
    Widget build(BuildContext context)
    {
      return InkWell
      (
        onTap: onTap,
        child: ListTile
        (
          leading: Icon(icon),
          title: Text(text),
        ),
      );
    }
  }
}