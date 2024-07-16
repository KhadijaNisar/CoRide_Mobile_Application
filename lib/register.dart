// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:hitchify/create_ride.dart';
import 'package:hitchify/home/home_screen.dart';
import 'package:hitchify/profile.dart';
import 'package:hitchify/cnic.dart';
import 'package:hitchify/vehicle.dart';
import 'package:hitchify/vehicle_info.dart';

class Register extends StatelessWidget {
  const Register({super.key});

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
                  // Navigator.pushNamed(context, '/vehicle');
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CreateRideScreen()));
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
}
