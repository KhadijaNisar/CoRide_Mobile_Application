import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hitchify/UI/auth/loginWithPhone.dart';
import 'package:hitchify/core/app_export.dart';
import 'package:hitchify/home/driver_home.dart';
import 'package:hitchify/home/home_screen.dart';

import '../help&support/help_center.dart';
import '../profile/driver_profile_screen.dart';
import '../profile/passenger_profile.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

class NavBar extends StatefulWidget {
  final String userType; // Add userType parameter to the constructor
  final String passenger; // Add userType parameter to the constructor

  NavBar({required this.userType, required this.passenger});

  @override
  _NavBarState createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController addressController;
  late TextEditingController cnicController;
  String _imagePath = '';
  Map<String, dynamic> userData = {};
  String _name = '';

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    emailController = TextEditingController();
    addressController = TextEditingController();
    cnicController = TextEditingController();
    _fetchUserData();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    addressController.dispose();
    cnicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.75,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: appTheme.teal500,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundImage: _imagePath.isNotEmpty
                          ? NetworkImage(_imagePath) as ImageProvider
                          : AssetImage('assets/images/avatar.jpg'),
                    ),
                    SizedBox(height: 5),
                    Text(
                      _name.isNotEmpty ? _name : 'Default Name',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                    // Text(
                    //   userData['displayName'] ?? 'Default Name',
                    //   style: TextStyle(
                    //     color: Colors.white,
                    //     fontSize: 18,
                    //   ),
                    // ),
                    Text(
                      userData['email'] ?? 'Default Email',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Home'),
              onTap: () {
                // Handle settings button press
                if (widget.userType == 'passenger') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HomeScreen()),
                  );
                } else if (widget.userType == 'driver') {
                  // print("Type: $widget.userType");
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => driverHome()),
                  );
                }
                // context, MaterialPageRoute(builder: (context) => EditProfileScreen()));
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                // Handle settings button press
                if (widget.userType == 'passenger') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => EditProfileScreen(userType: widget.userType,)),
                  );
                } else if (widget.userType == 'driver') {
                  // print("Type: $widget.userType");
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => DriverProfileScreen(userType: widget.userType)),
                  );
                }
                // context, MaterialPageRoute(builder: (context) => EditProfileScreen()));
              },
            ),
            ListTile(
              leading: Icon(Icons.report),
              title: Text('Complain'),
              onTap: () {
                // Handle complain button press
              },
            ),
            ListTile(
              leading: Icon(Icons.help),
              title: Text('Help and Support'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => helpCenter()),
                );
                // Handle help and support button press
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Log Out'),
              onTap: () {
                _signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginWithPhone(),
                  ),
                    (route)=>false
                );
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) => LoginWithPhone(),
                //   ),
                // );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchUserData() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      String? userId = currentUser?.uid;

      // Fetch user data from Firestore
      DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(userId)
          .get();
      userData = userDoc.data()!;

      setState(() {
        nameController.text = userData['name'] as String? ?? '';
        emailController.text = userData['email'] as String? ?? '';
        addressController.text = userData['address'] as String? ?? '';
        cnicController.text = userData['cnic'] as String? ?? '';
        _imagePath = userData['image'] as String? ?? '';
        _name = userData['displayName'] as String? ?? '';
        print('$userData');
        print('image: $_imagePath');
        print('name: $nameController.text');
      });
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      print("User signed out");
    } catch (e) {
      print("Error during sign out");
    }
  }
}
