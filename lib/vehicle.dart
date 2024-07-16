// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:hitchify/register.dart';

class Vehicle extends StatelessWidget {
  const Vehicle({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: ListView(
          children: <Widget>[
            Center(
              child: Text(
                "Choose your vehicle",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color.fromRGBO(90, 107, 101, 0.965),
                ),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Card(
              child: ListTile(
                tileColor: Colors.white,
                leading: Image(image: AssetImage('assets/images/Car.png')),
                title: Text('Car'),
                trailing: Icon(Icons.arrow_forward_ios_outlined),
                onTap: () {
                  // Navigator.pushNamed(context, '/register');
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => Register()));
                },
              ),
            ),
            Card(
              child: ListTile(
                tileColor: Colors.white,
                leading: Image(image: AssetImage('assets/images/Rickshaw.png')),
                title: Text('Rickshaw'),
                trailing: Icon(Icons.arrow_forward_ios_outlined),
                onTap: () {
                  // Navigator.pushNamed(context, '/register');
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => Register()));
                },
              ),
            ),
            Card(
              child: ListTile(
                tileColor: Colors.white,
                leading: Image(image: AssetImage('assets/images/Bike.png')),
                title: Text('Motorcycle'),
                trailing: Icon(Icons.arrow_forward_ios_outlined),
                onTap: () {
                  // Navigator.pushNamed(context, '/register');
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => Register()));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
