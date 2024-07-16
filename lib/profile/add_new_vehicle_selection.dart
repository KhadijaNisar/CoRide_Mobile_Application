import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hitchify/driverAndVehicleRegistration/register.dart';

import 'add_new_vehicle.dart';

class AddNewVehicleSelection extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: FutureBuilder<List<String>>(
          future: getAvailableVehicleTypes(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              List<String> availableVehicleTypes = snapshot.data!;
              bool allVehicleTypesExist =
                  availableVehicleTypes.contains('Car') &&
                      availableVehicleTypes.contains('Rickshaw') &&
                      availableVehicleTypes.contains('Motorcycle');
              //
              // if (allVehicleTypesExist) {
              //   // Navigate back and show notification
              //   Navigator.pop(context);
              //   ScaffoldMessenger.of(context).showSnackBar(
              //     SnackBar(
              //       content: Text('You have created all vehicle types.'),
              //     ),
              //   );
              // }

              return ListView(
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
                  if (!availableVehicleTypes.contains('Car'))
                    Card(
                      child: ListTile(
                        tileColor: Colors.white,
                        leading:
                            Image(image: AssetImage('assets/images/Car.png')),
                        title: Text('Car'),
                        trailing: Icon(Icons.arrow_forward_ios_outlined),
                        onTap: () {
                          String selectedVehicle = 'Car';
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddNewVehicle(
                                selectedVehicle: selectedVehicle,
                              ),
                            ),
                          );
                          print(
                              "Selected Vehicle: $selectedVehicle"); // Print selected vehicle
                        },
                      ),
                    ),
                  if (!availableVehicleTypes.contains('Rickshaw'))
                    Card(
                      child: ListTile(
                        tileColor: Colors.white,
                        leading: Image(
                            image: AssetImage('assets/images/Rickshaw.png')),
                        title: Text('Rickshaw'),
                        trailing: Icon(Icons.arrow_forward_ios_outlined),
                        onTap: () {
                          String selectedVehicle = 'Rickshaw';
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddNewVehicle(
                                selectedVehicle: selectedVehicle,
                              ),
                            ),
                          );
                          print(
                              'Selected Vehicle: $selectedVehicle'); // Print selected vehicle
                        },
                      ),
                    ),
                  if (!availableVehicleTypes.contains('Motorcycle'))
                    Card(
                      child: ListTile(
                        tileColor: Colors.white,
                        leading:
                            Image(image: AssetImage('assets/images/Bike.png')),
                        title: Text('Motorcycle'),
                        trailing: Icon(Icons.arrow_forward_ios_outlined),
                        onTap: () {
                          String selectedVehicle = 'Motorcycle';
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddNewVehicle(
                                selectedVehicle: selectedVehicle,
                              ),
                            ),
                          );
                          print(
                              'Selected Vehicle: $selectedVehicle'); // Print selected vehicle
                        },
                      ),
                    ),
                ],
              );
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              return Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }

  Future<List<String>> getAvailableVehicleTypes() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        QuerySnapshot querySnapshot = await _firestore
            .collection('vehicle_data')
            .where('userId', isEqualTo: currentUser.uid)
            .get();

        List<String> availableVehicleTypes = [
          'Car',
          'Rickshaw',
          'Motorcycle'
        ]; // Default vehicle types

        if (querySnapshot.docs.isNotEmpty) {
          availableVehicleTypes = availableVehicleTypes.where((type) {
            return querySnapshot.docs.any((doc) => doc['vehicleType'] == type);
          }).toList();
        }

        return availableVehicleTypes;
      } else {
        throw Exception('User is not logged in.');
      }
    } catch (e) {
      throw Exception('Error fetching available vehicle types: $e');
    }
  }
}
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:hitchify/register.dart';
//
// class AddNewVehicleSelection extends StatelessWidget {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back),
//           onPressed: () {
//             Navigator.pop(context);
//           },
//         ),
//       ),
//       body: Padding(
//         padding: EdgeInsets.all(8.0),
//         child: FutureBuilder<List<String>>(
//           future: getAvailableVehicleTypes(),
//           builder: (context, snapshot) {
//             if (snapshot.hasData) {
//               List<String> availableVehicleTypes = snapshot.data!;
//               return ListView(
//                 children: <Widget>[
//                   Center(
//                     child: Text(
//                       "Choose your vehicle",
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: Color.fromRGBO(90, 107, 101, 0.965),
//                       ),
//                     ),
//                   ),
//                   SizedBox(
//                     height: 20,
//                   ),
//                   if (!availableVehicleTypes.contains('Car'))
//                     Card(
//                       child: ListTile(
//                         tileColor: Colors.white,
//                         leading:
//                         Image(image: AssetImage('assets/images/Car.png')),
//                         title: Text('Car'),
//                         trailing: Icon(Icons.arrow_forward_ios_outlined),
//                         onTap: () {
//                           String selectedVehicle = 'Car';
//                           // updateSelectedVehicle(selectedVehicle);
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => Register(
//                                 selectedVehicle: selectedVehicle,
//                               ),
//                             ),
//                           );
//                           print(
//                               "Selected Vehicle: $selectedVehicle"); // Print selected vehicle
//                         },
//                       ),
//                     ),
//                   if (!availableVehicleTypes.contains('Rickshaw'))
//                     Card(
//                       child: ListTile(
//                         tileColor: Colors.white,
//                         leading: Image(
//                             image:
//                             AssetImage('assets/images/Rickshaw.png')),
//                         title: Text('Rickshaw'),
//                         trailing: Icon(Icons.arrow_forward_ios_outlined),
//                         onTap: () {
//                           String selectedVehicle = 'Rickshaw';
//                           // updateSelectedVehicle(selectedVehicle);
//
//                           print('Selected Vehicle: $selectedVehicle'); // Print selected vehicle
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => Register(
//                                 selectedVehicle: selectedVehicle,
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                   if (!availableVehicleTypes.contains('Motorcycle'))
//                     Card(
//                       child: ListTile(
//                         tileColor: Colors.white,
//                         leading:
//                         Image(image: AssetImage('assets/images/Bike.png')),
//                         title: Text('Motorcycle'),
//                         trailing: Icon(Icons.arrow_forward_ios_outlined),
//                         onTap: () {
//                           String selectedVehicle = 'Motorcycle';
//                           // updateSelectedVehicle(selectedVehicle);
//
//                           print('Selected Vehicle: $selectedVehicle'); // Print selected vehicle
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => Register(
//                                 selectedVehicle: selectedVehicle,
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                 ],
//               );
//             } else if (snapshot.hasError) {
//               return Center(child: Text('Error: ${snapshot.error}'));
//             } else {
//               return Center(child: CircularProgressIndicator());
//             }
//           },
//         ),
//       ),
//     );
//   }
//
//   Future<List<String>> getAvailableVehicleTypes() async {
//     try {
//       User? currentUser = _auth.currentUser;
//       if (currentUser != null) {
//         QuerySnapshot querySnapshot = await _firestore
//             .collection('vehicle_data')
//             .where('userId', isEqualTo: currentUser.uid)
//             .get();
//
//         List<String> availableVehicleTypes = [
//           'Car',
//           'Rickshaw',
//           'Motorcycle'
//         ]; // Default vehicle types
//
//         if (querySnapshot.docs.isNotEmpty) {
//           availableVehicleTypes = availableVehicleTypes.where((type) {
//             return querySnapshot.docs
//                 .any((doc) => doc['vehicleType'] == type);
//           }).toList();
//         }
//
//         return availableVehicleTypes;
//       } else {
//         throw Exception('User is not logged in.');
//       }
//     } catch (e) {
//       throw Exception('Error fetching available vehicle types: $e');
//     }
//   }
//
//   // void updateSelectedVehicle(String selectedVehicle) async {
//   //   try {
//   //     User? currentUser = _auth.currentUser;
//   //     if (currentUser != null) {
//   //       await _firestore.collection('users').doc(currentUser.uid).update({
//   //         'Vehicletype': selectedVehicle,
//   //       });
//   //     } else {
//   //       print('User is not logged in.');
//   //     }
//   //   } catch (e){
//   //     print('Error updating selected vehicle: $e');
//   //   }
//   // }
// }
