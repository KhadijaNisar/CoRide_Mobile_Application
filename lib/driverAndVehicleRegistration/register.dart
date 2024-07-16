// ignore_for_file: prefer_const_constructors

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hitchify/driverAndVehicleRegistration/profile.dart';
import 'package:hitchify/driverAndVehicleRegistration/cnic.dart';
import 'package:hitchify/driverAndVehicleRegistration/vehicle_info.dart';

import '../home/driver_home.dart';

class Register extends StatelessWidget {
  final String? selectedVehicle;

  Register({Key? key, this.selectedVehicle}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Registration')),
      ),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: ListView(
          children: <Widget>[
            Card(
              child: ListTile(
                tileColor: Colors.white,
                title: Text('Basic Info'),
                trailing: Icon(Icons.arrow_forward_ios_outlined),
                onTap: () {
                  // Navigator.pushNamed(context, '/profile');
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => Profile()));
                },
              ),
            ),
            Card(
              child: ListTile(
                tileColor: Colors.white,
                title: Text('CNIC'),
                trailing: Icon(Icons.arrow_forward_ios_outlined),
                onTap: () {
                  Navigator.push(
                      context, MaterialPageRoute(builder: (context) => CNIC()));
                },
              ),
            ),
            Card(
              child: ListTile(
                tileColor: Colors.white,
                title: Text('Vehicle Info'),
                trailing: Icon(Icons.arrow_forward_ios_outlined),
                onTap: () {
                  // Navigator.pushNamed(context, '/info');
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => VehicleForm()));
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
    );
  }
  //
  // final FirebaseAuth _auth = FirebaseAuth.instance;
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Future<void> updateSelectedVehicle(String selectedVehicle) async {
  //   try {
  //     // Get the current user
  //     User? currentUser = _auth.currentUser;
  //     if (currentUser != null) {
  //       // Update Firestore document with the selected vehicle
  //       await _firestore.collection('users').doc(currentUser.uid).update({
  //         'Vehicletype': selectedVehicle,
  //       });
  //     } else {
  //       print('User is not logged in.');
  //     }
  //   } catch (e) {
  //     print('Error updating selected vehicle: $e');
  //   }
  // }
}
