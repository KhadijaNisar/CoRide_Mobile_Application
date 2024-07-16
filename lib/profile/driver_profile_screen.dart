// ignore_for_file: prefer_const_constructors

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hitchify/driverAndVehicleRegistration/profile.dart';
import 'package:hitchify/driverAndVehicleRegistration/cnic.dart';
import 'package:hitchify/profile/update_cnic.dart';
import 'package:hitchify/profile/update_profile.dart';
import 'package:hitchify/profile/update_vehicle.dart';
import 'package:hitchify/driverAndVehicleRegistration/vehicle_info.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';

import 'package:hitchify/home/driver_home.dart';

import '../home/animated_downbar.dart';
import '../home/home_screen.dart';
import 'add_new_vehicle_selection.dart';

class DriverProfileScreen extends StatefulWidget {
  final String userType;
  final String? selectedVehicle;

  DriverProfileScreen({Key? key, this.selectedVehicle,required this.userType}) : super(key: key);

  @override
  _DriverProfileScreenState createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  late final String? selectedVehicle;

  // DriverProfileScreen({Key? key, this.selectedVehicle}) : super(key: key);

  bool allVehicleTypesExist = false;
  bool myInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => driverHome()),(route)=>false
    );
    // Navigator.pushReplacement(
    //   context,
    //   MaterialPageRoute(builder: (context) => driverHome()),
    // );
    return true;
  }

  @override
  void initState() {
    super.initState();
    checkVehicleTypesExist();
    BackButtonInterceptor.add(myInterceptor);
  }

  Future<void> checkVehicleTypesExist() async {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid;

    if (userId != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('vehicle_data')
          .where('userId', isEqualTo: userId)
          .get();

      final documents = snapshot.docs;

      final vehicleTypes = documents.map((doc) => doc['vehicleType']).toList();
      print("Vehicle: $vehicleTypes");
      setState(() {
        allVehicleTypesExist = vehicleTypes.contains('Car') &&
            vehicleTypes.contains('Rickshaw') &&
            vehicleTypes.contains('Motorcycle');
      });
    }
  }
  @override
  void dispose() {
    BackButtonInterceptor.remove(myInterceptor);
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Edit Driver Profile')),
        leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
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
            }),
      ),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: ListView(
          children: <Widget>[
            Card(
              child: ListTile(
                tileColor: Colors.white,
                title: Text('Edit Basic Info'),
                trailing: Icon(Icons.arrow_forward_ios_outlined),
                onTap: () {
                  // Navigator.pushNamed(context, '/profile');
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => UpdateProfile()));
                },
              ),
            ),
            Card(
              child: ListTile(
                tileColor: Colors.white,
                title: Text('Edit CNIC'),
                trailing: Icon(Icons.arrow_forward_ios_outlined),
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => UpdateCNIC()));
                },
              ),
            ),
            Card(
              child: ListTile(
                tileColor: Colors.white,
                title: Text('Edit Existing Vehicle Info'),
                trailing: Icon(Icons.arrow_forward_ios_outlined),
                onTap: () {
                  // Navigator.pushNamed(context, '/info');
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => UpdateVehicleForm()));
                },
              ),
            ),
            Card(
              child: ListTile(
                tileColor: Colors.white,
                title: Text('Add Vehicle'),
                trailing: Icon(Icons.arrow_forward_ios_outlined),
                onTap: () {
                  if (allVehicleTypesExist) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('You have created all vehicle types.'),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddNewVehicleSelection(),
                      ),
                    );
                  }
                  // Navigator.push(context,
                  //     MaterialPageRoute(builder: (context) => AddNewVehicleSelection()));
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: TextButton(
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => driverHome()));
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF008955),
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  padding:
                      EdgeInsets.symmetric(vertical: 10.0, horizontal: 30.0),
                  child: Text(
                    "Done",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                  "By submiting > i agree with Terms and Conditions, I  acknowledged and agree with processing and transfer data according of Privacy Policy"),
            )
          ],
        ),
      ),
      bottomNavigationBar: AnimatedDownBar(userType: 'driver',screenNo: 3,),
    );
  }
}
