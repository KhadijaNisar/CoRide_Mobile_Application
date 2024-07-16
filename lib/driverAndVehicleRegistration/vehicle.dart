// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:hitchify/register.dart';
//
// class Vehicle extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(),
//       body: Padding(
//         padding: EdgeInsets.all(8.0),
//         child: ListView(
//           children: <Widget>[
//             Center(
//               child: Text(
//                 "Choose your vehicle",
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                   color: Color.fromRGBO(90, 107, 101, 0.965),
//                 ),
//               ),
//             ),
//             SizedBox(
//               height: 20,
//             ),
//             Card(
//               child: ListTile(
//                 tileColor: Colors.white,
//                 leading: Image(image: AssetImage('assets/images/Car.png')),
//                 title: Text('Car'),
//                 trailing: Icon(Icons.arrow_forward_ios_outlined),
//                 onTap: () {
//                   String selectedVehicle = 'Car';
//                   updateSelectedVehicle(selectedVehicle);
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                         builder: (context) =>
//                             Register(selectedVehicle: selectedVehicle)),
//                   );
//                   print(
//                       "Selected Vehicle: $selectedVehicle"); // Print selected vehicle
//                 },
//               ),
//             ),
//             Card(
//               child: ListTile(
//                 tileColor: Colors.white,
//                 leading: Image(image: AssetImage('assets/images/Rickshaw.png')),
//                 title: Text('Rickshaw'),
//                 trailing: Icon(Icons.arrow_forward_ios_outlined),
//                 onTap: () {
//                   String selectedVehicle = 'Rickshaw';
//                   updateSelectedVehicle(selectedVehicle);
//
//                   print(
//                       'Selected Vehicle: $selectedVehicle'); // Print selected vehicle
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                         builder: (context) =>
//                             Register(selectedVehicle: selectedVehicle)),
//                   );
//                 },
//               ),
//             ),
//             Card(
//               child: ListTile(
//                 tileColor: Colors.white,
//                 leading: Image(image: AssetImage('assets/images/Bike.png')),
//                 title: Text('Motorcycle'),
//                 trailing: Icon(Icons.arrow_forward_ios_outlined),
//                 onTap: () {
//                   String selectedVehicle = 'Motorcycle';
//                   updateSelectedVehicle(selectedVehicle);
//
//                   print(
//                       'Selected Vehicle: $selectedVehicle'); // Print selected vehicle
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                         builder: (context) =>
//                             Register(selectedVehicle: selectedVehicle)),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   void updateSelectedVehicle(String selectedVehicle) async {
//     try {
//       // Get the current user
//       User? currentUser = _auth.currentUser;
//       if (currentUser != null) {
//         // Update Firestore document with the selected vehicle
//         await _firestore.collection('users').doc(currentUser.uid).update({
//           'Vehicletype': selectedVehicle,
//         });
//       } else {
//         print('User is not logged in.');
//       }
//     } catch (e) {
//       print('Error updating selected vehicle: $e');
//     }
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hitchify/driverAndVehicleRegistration/register.dart';

class Vehicle extends StatelessWidget {
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
                  String selectedVehicle = 'Car';
                  // updateSelectedVehicle(selectedVehicle);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            Register(selectedVehicle: selectedVehicle)),
                  );
                  print(
                      "Selected Vehicle: $selectedVehicle"); // Print selected vehicle
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
                  String selectedVehicle = 'Rickshaw';
                  // updateSelectedVehicle(selectedVehicle);

                  print(
                      'Selected Vehicle: $selectedVehicle'); // Print selected vehicle
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            Register(selectedVehicle: selectedVehicle)),
                  );
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
                  String selectedVehicle = 'Motorcycle';
                  // updateSelectedVehicle(selectedVehicle);

                  print(
                      'Selected Vehicle: $selectedVehicle'); // Print selected vehicle
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            Register(selectedVehicle: selectedVehicle)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void updateSelectedVehicle(String selectedVehicle) async {
    try {
      // Get the current user
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        // Update Firestore document with the selected vehicle
        // await _firestore.collection('users').doc(currentUser.uid).update({
        //   'Vehicletype': selectedVehicle,
        // });
        CollectionReference collection =
            FirebaseFirestore.instance.collection('vehicle_data');

        // Create a new document with the userId field and anotherField
        await collection.add({
          'userId': currentUser.uid,
          'vehicleType': selectedVehicle,
        });
      } else {
        print('User is not logged in.');
      }
    } catch (e) {
      print('Error updating selected vehicle: $e');
    }
  }
}
