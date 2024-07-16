import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hitchify/driverSideRide/acceptedRideDriver.dart';
import 'package:hitchify/home/home_screen.dart';

import 'package:hitchify/passengerSideRide/Rides.dart';

import '../passengerSideRide/GlobalMatchedRideIds.dart';
import '../passengerSideRide/match_rides.dart';

class DriverRideData {
  late Position driverPosition = Position(
    latitude: 0.0,
    longitude: 0.0,
    timestamp: DateTime.now(),
    accuracy: 0.0,
    altitude: 0.0,
    heading: 0.0,
    speed: 0.0,
    speedAccuracy: 0.0,
    altitudeAccuracy: 0.0,
    headingAccuracy: 0.0,
  );
}

DriverRideData driverRideData = DriverRideData();

StreamSubscription<Position> startDriverLocationUpdates(String driverId) {
  StreamController<Position> controller = StreamController();

  Timer timer = Timer.periodic(Duration(seconds: 20), (Timer t) async {
    try {
      driverRideData.driverPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      print('Current position: ${driverRideData.driverPosition}');

      // Update driver's location in Firestore
      await FirebaseFirestore.instance
          .collection('driversLocations')
          .doc(driverId)
          .set({
        'location': GeoPoint(driverRideData.driverPosition.latitude,
            driverRideData.driverPosition.longitude),
        'driverId': driverId,
      });

      controller.add(
          driverRideData.driverPosition); // Emit the position to the stream
    } catch (e) {
      print('Error getting current position: $e');
    }
  });

  // When the stream is cancelled, cancel the timer as well
  controller.onCancel = () {
    timer.cancel();
  };

  return controller.stream.listen(null);
}

class DriverRideSelecting extends StatefulWidget {
  final List<String> userIds; // List of user IDs

  DriverRideSelecting({
    this.userIds = const [],
  });

  // Named constructor accepting user IDs
  DriverRideSelecting.userid({
    required this.userIds,
  });

  @override
  _DriverRideSelectingState createState() => _DriverRideSelectingState();
}

class _DriverRideSelectingState extends State<DriverRideSelecting> {
  late final String currentUserUid;

  @override
  void initState() {
    super.initState();
    currentUserUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  Future<bool> driverCheckIfFavorite(String matchedUserId) {
    return FirebaseFirestore.instance
        .collection('All_Friends')
        .doc(currentUserUid)
        .collection('friend')
        .doc(matchedUserId)
        .get()
        .then((snapshot) => snapshot.exists);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF08B783),
        title: Row(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Text('Rides'),
            ),
          ],
        ),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('rides')
            .where('userId', isEqualTo: currentUserUid)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            final rideDocs = snapshot.data!.docs;
            return ListView.builder(
              shrinkWrap: true,
              itemCount: rideDocs.length,
              itemBuilder: (context, index) {
                final rideDoc = rideDocs[index];
                final rideId = rideDoc.id; // Get the document ID
                print("Data1");
                print('Ride ID: $rideId'); // Print the document ID
                return StreamBuilder<QuerySnapshot>(
                  stream: rideDoc.reference
                      .collection('AcceptedRides')
                      .where('rideStatus', isEqualTo: 'accepted')
                      .snapshots(),
                  builder: (context, acceptedRidesSnapshot) {
                    if (acceptedRidesSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (acceptedRidesSnapshot.hasError) {
                      return Text('Error: ${acceptedRidesSnapshot.error}');
                    } else {
                      final acceptedRidesDocs =
                          acceptedRidesSnapshot.data!.docs;
                      if (acceptedRidesDocs.isNotEmpty) {
                        return Column(
                          children: acceptedRidesDocs.map((acceptedRideDoc) {
                            final passengerId = acceptedRideDoc['passengerId'];
                            final fare = acceptedRideDoc['passengerFare'];
                            final passengerSource =
                                acceptedRideDoc['passengerSource'];
                            final passengerDestination =
                                acceptedRideDoc['passengerDestination'];
                            return FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(passengerId)
                                  .get(),
                              builder: (context, userSnapshot) {
                                if (userSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Center(
                                      child: CircularProgressIndicator());
                                } else if (userSnapshot.hasError) {
                                  return Text('Error: ${userSnapshot.error}');
                                } else {
                                  final passengerData = userSnapshot.data!
                                      .data() as Map<String, dynamic>;
                                  final passengerName =
                                      passengerData['displayName'] ?? '';
                                  final passengerImage =
                                      passengerData['image'] ?? '';
                                  return Card(
                                    margin: EdgeInsets.all(15),
                                    elevation: 5.0,
                                    color: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Stack(
                                      children: [
                                        Column(
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(12.0),
                                              child: ListTile(
                                                leading: SizedBox(
                                                  height: 50,
                                                  width: 50,
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            70),
                                                    child: Image.network(
                                                        passengerImage,
                                                        fit: BoxFit.cover),
                                                  ),
                                                ),
                                                title: Row(
                                                  children: [
                                                    FutureBuilder<bool>(
                                                      future:
                                                          driverCheckIfFavorite(
                                                              currentUserUid),
                                                      builder: (context,
                                                          AsyncSnapshot<bool>
                                                              snapshot) {
                                                        final isFavorite =
                                                            snapshot.data ??
                                                                false;
                                                        return isFavorite
                                                            ? Icon(
                                                                Icons.favorite,
                                                                size: 12,
                                                                color: Color(
                                                                    0xff52c498))
                                                            : SizedBox.shrink();
                                                      },
                                                    ),
                                                    Text(passengerName),
                                                  ],
                                                ),
                                                trailing: Text(
                                                  '${fare.toStringAsFixed(0)} PKR',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    color: Color(0xff52c498),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            ListTile(
                                              title: Text(
                                                  'PickUp: $passengerSource \nDestination: $passengerDestination'),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 30),
                                              child: ButtonBar(
                                                alignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  ElevatedButton(
                                                    style: ButtonStyle(
                                                      backgroundColor:
                                                          MaterialStateProperty
                                                              .all<Color>(Color(
                                                                  0xff52c498)),
                                                      foregroundColor:
                                                          MaterialStateProperty
                                                              .all<Color>(
                                                                  Colors.white),
                                                      minimumSize:
                                                          MaterialStateProperty
                                                              .all<Size>(Size(
                                                                  200, 40)),
                                                    ),
                                                    onPressed: () {
                                                      globalMatchedRideIds
                                                              .driverLocationUpdateSubscription =
                                                          startDriverLocationUpdates(
                                                              currentUserUid);

                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              AcceptedRideDriver(
                                                                  passengerName:
                                                                      passengerName,
                                                                  passengerImage:
                                                                      passengerImage,
                                                                  passengerUserId:
                                                                      passengerId), // replace with the actual next screen
                                                        ),
                                                      );
                                                    },
                                                    child: Text('Continue'),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              },
                            );
                          }).toList(),
                        );
                      } else {
                        return SizedBox.shrink(); // No accepted rides found
                      }
                    }
                  },
                );
              },
            );
          }
        },
      ),
    );
  }

// @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       backgroundColor: const Color(0xFF08B783),
  //       title: Row(
  //         children: [
  //           Align(
  //             alignment: Alignment.topLeft,
  //             child: Text('Rides'),
  //           ),
  //         ],
  //       ),
  //     ),
  //     body: FutureBuilder<QuerySnapshot>(
  //       future: FirebaseFirestore.instance
  //           .collection('rides')
  //           .where('driverId', isEqualTo: currentUserUid)
  //           .get(),
  //       builder: (context, snapshot) {
  //         if (snapshot.connectionState == ConnectionState.waiting) {
  //           return Center(child: CircularProgressIndicator());
  //         } else if (snapshot.hasError) {
  //           return Text('Error: ${snapshot.error}');
  //         } else {
  //           final rideDocs = snapshot.data!.docs;
  //           return ListView.builder(
  //             shrinkWrap: true,
  //             itemCount: rideDocs.length,
  //             itemBuilder: (context, index) {
  //               final rideDoc = rideDocs[index];
  //               final rideId = rideDoc.id; // Get the document ID
  //               print("Data1");
  //               print('Ride ID: $rideId'); // Print the document ID
  //               return FutureBuilder<QuerySnapshot>(
  //                 future: rideDoc.reference
  //                     .collection('AcceptedRides')
  //                     .where('rideStatus', isEqualTo: 'accepted')
  //                     .get(),
  //                 builder: (context, acceptedRidesSnapshot) {
  //                   if (acceptedRidesSnapshot.connectionState == ConnectionState.waiting) {
  //                     return Center(child: CircularProgressIndicator());
  //                   } else if (acceptedRidesSnapshot.hasError) {
  //                     return Text('Error: ${acceptedRidesSnapshot.error}');
  //                   } else {
  //                     final acceptedRidesDocs = acceptedRidesSnapshot.data!.docs;
  //                     if (acceptedRidesDocs.isNotEmpty) {
  //                       final acceptedRideDoc = acceptedRidesDocs.first;
  //                       final passengerId = acceptedRideDoc['passengerId'];
  //                       final fare = acceptedRideDoc['passengerFare'];
  //                       final passengerSource = acceptedRideDoc['passengerSource'];
  //                       final passengerDestination = acceptedRideDoc['passengerDestination'];
  //                       return FutureBuilder<DocumentSnapshot>(
  //                         future: FirebaseFirestore.instance
  //                             .collection('users')
  //                             .doc(passengerId)
  //                             .get(),
  //                         builder: (context, userSnapshot) {
  //                           if (userSnapshot.connectionState == ConnectionState.waiting) {
  //                             return Center(child: CircularProgressIndicator());
  //                           } else if (userSnapshot.hasError) {
  //                             return Text('Error: ${userSnapshot.error}');
  //                           } else {
  //                             final passengerData = userSnapshot.data!.data() as Map<String, dynamic>;
  //                             final passengerName = passengerData['displayName'] ?? '';
  //                             final passengerImage = passengerData['image'] ?? '';
  //                             return Card(
  //                               margin: EdgeInsets.all(15),
  //                               elevation: 5.0,
  //                               color: Colors.white,
  //                               shape: RoundedRectangleBorder(
  //                                 borderRadius: BorderRadius.circular(20),
  //                               ),
  //                               child: Stack(
  //                                 children: [
  //                                   Column(
  //                                     children: [
  //                                       Padding(
  //                                         padding: const EdgeInsets.all(12.0),
  //                                         child: ListTile(
  //                                           leading: SizedBox(
  //                                             height: 50,
  //                                             width: 50,
  //                                             child: ClipRRect(
  //                                               borderRadius: BorderRadius.circular(70),
  //                                               child: Image.network(passengerImage, fit: BoxFit.cover),
  //                                             ),
  //                                           ),
  //                                           title: Row(
  //                                             children: [
  //                                               FutureBuilder<bool>(
  //                                                 future: driverCheckIfFavorite(currentUserUid),
  //                                                 builder: (context, AsyncSnapshot<bool> snapshot) {
  //                                                   final isFavorite = snapshot.data ?? false;
  //                                                   return isFavorite
  //                                                       ? Icon(Icons.favorite, size: 12, color: Color(0xff52c498))
  //                                                       : SizedBox.shrink();
  //                                                 },
  //                                               ),
  //                                               Text(passengerName),
  //                                             ],
  //                                           ),
  //                                           trailing: Text(
  //                                             '${fare.toStringAsFixed(0)} PKR',
  //                                             style: TextStyle(
  //                                               fontSize: 17,
  //                                               color: Color(0xff52c498),
  //                                             ),
  //                                           ),
  //                                         ),
  //                                       ),
  //                                       ListTile(
  //                                         title: Text('PickUp: $passengerSource \nDestination: $passengerDestination'),
  //                                       ),
  //                                       Padding(
  //                                         padding: const EdgeInsets.only(left: 30),
  //                                         child: ButtonBar(
  //                                           alignment: MainAxisAlignment.center,
  //                                           children: [
  //                                             ElevatedButton(
  //                                               style: ButtonStyle(
  //                                                 backgroundColor: MaterialStateProperty.all<Color>(Color(0xff52c498)),
  //                                                 foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
  //                                                 minimumSize: MaterialStateProperty.all<Size>(Size(200, 40)),
  //                                               ),
  //                                               onPressed: () {
  //                                                 globalMatchedRideIds.driverLocationUpdateSubscription =
  //                                                     startDriverLocationUpdates(currentUserUid);
  //
  //                                                 Navigator.push(
  //                                                   context,
  //                                                   MaterialPageRoute(
  //                                                     builder: (context) => AcceptedRideDriver(
  //                                                         passengerName: passengerName,
  //                                                         passengerImage: passengerImage,
  //                                                         passengerUserId: passengerId), // replace with the actual next screen
  //                                                   ),
  //                                                 );
  //                                               },
  //                                               child: Text('Continue'),
  //                                             ),
  //                                           ],
  //                                         ),
  //                                       ),
  //                                     ],
  //                                   ),
  //                                 ],
  //                               ),
  //                             );
  //                           }
  //                         },
  //                       );
  //                     } else {
  //                       return SizedBox.shrink(); // No accepted rides found
  //                     }
  //                   }
  //                 },
  //               );
  //             },
  //           );
  //         }
  //       },
  //     ),
  //   );
  // }
}
