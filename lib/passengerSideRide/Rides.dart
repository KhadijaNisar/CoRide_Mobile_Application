import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as loc;
import 'package:hitchify/passengerSideRide/acceptedRide.dart';
import 'package:hitchify/home/home_screen.dart';

import 'GlobalMatchedRideIds.dart';
import 'match_rides.dart';

class AvailableRides extends StatefulWidget {
  final List<loc.Marker> availableRides;
  final List<String> userIds;
  final List<String> matchedRideIds;
  DocumentReference documentName;
  final String vehicleType;

  AvailableRides(
      {required this.availableRides,
      required this.matchedRideIds,
      required this.userIds,
      required this.documentName,
      required this.vehicleType});

  AvailableRides.userid({
    required this.userIds,
    this.availableRides = const [],
    this.matchedRideIds = const [],
    required this.documentName,
    required this.vehicleType,
  });

  @override
  _AvailableRidesState createState() => _AvailableRidesState();
}

class _AvailableRidesState extends State<AvailableRides> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  StreamSubscription<Position> startPassengerLocationUpdates(
      String passengerId) {
    StreamController<Position> controller = StreamController();

    Timer timer = Timer.periodic(Duration(seconds: 20), (Timer t) async {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        print('Current position: $position');

        await FirebaseFirestore.instance
            .collection('PassengersLocations')
            .doc(passengerId)
            .set({
          'location': GeoPoint(position.latitude, position.longitude),
          'passengerId': passengerId,
        });

        controller.add(position);
      } catch (e) {
        print('Error getting current position: $e');
      }
    });

    controller.onCancel = () {
      timer.cancel();
    };

    return controller.stream.listen(null);
  }

  Future<List<dynamic>> fetchingPassengerRideData(
      DocumentReference docRef) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    Map<String, dynamic>? passRideData;
    try {
      DocumentSnapshot passengerRidedocSnapshot =
          await firestore.collection('passengerride').doc(docRef.id).get();

      if (passengerRidedocSnapshot.exists) {
        // Extract data from the document
        passRideData = passengerRidedocSnapshot.data() as Map<String, dynamic>;
        print('Document data: $passRideData');
        print('Document data: ${passRideData['sourceLatitude']}');
      } else {
        print('Document does not exist!');
        return []; // Return an empty list if the document doesn't exist
      }
    } catch (e) {
      print('Error fetching vehicle data: $e');
      // Handle the error appropriately (e.g., throw or return default value)
      return [];
    }

    // Create a list to store the extracted values
    List<dynamic> rideDataList = [];

    // Add each value to the list
    rideDataList.add(passRideData!['date']);
    rideDataList.add(passRideData!['sourceLatitude']);
    rideDataList.add(passRideData!['sourceLongitude']);
    rideDataList.add(passRideData!['source']);
    rideDataList.add(passRideData['destination']);
    rideDataList.add(passRideData['destinationLatitude']);
    rideDataList.add(passRideData['destinationLongitude']);
    rideDataList.add(passRideData['time']);
    // Convert 'persons' string to int and add to the list
    rideDataList.add(int.parse(passRideData['persons']));
    rideDataList.add(passRideData['vehicle']);
    rideDataList.add(passRideData['userId']);

    // Return the list containing extracted values
    return rideDataList;
  }

  Future<void> rideStatusUpdate(int count) async {
    try {
      final driverId = widget.userIds[count];
      final rideId = widget.matchedRideIds[count];
      final fare = passengerRideData.passengerFares[count];
      globalMatchedRideIds.driverId = driverId;
      globalMatchedRideIds.rideId = rideId;
      globalMatchedRideIds.fare = fare;
      print("Ride Id : $rideId");
      print("Count$count");
      print("DriverIDd$driverId");
      List<dynamic> rideDataList =
          await fetchingPassengerRideData(widget.documentName);

      if (rideDataList.isEmpty) {
        print("Failed to fetch ride data.");
        return;
      }
      print("Ride Id : $rideId");
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('rides')
          .where('rideId', isEqualTo: rideId)
          .get();

      print("Pass Ride Data $rideDataList");

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot documentSnapshot = querySnapshot.docs.first;
        String source = rideDataList[3];
        String destination = rideDataList[4];

        DocumentReference newDocRef =
            await documentSnapshot.reference.collection('AcceptedRides').add({
          'rideStatus': 'accepted',
          'passengerId': currentUser?.uid,
          'driverId': driverId,
          'passengerFare': fare,
          'passengerSource': source,
          'passengerDestination': destination,
        });

        print("Ride status updated successfully. Document ID: ${newDocRef.id}");
      } else {
        print('No document found with the rideId: $rideId');
      }
    } catch (e) {
      print('Error in rideStatusUpdate: $e');
    }
  }

  // Future<void> rideStatusUpdate(int count) async {
  //   try {
  //     final driverId = widget.userIds[count];
  //     final rideId = widget.matchedRideIds[count];
  //     final fare = passengerRideData.passengerFares[count];
  //     globalMatchedRideIds.driverId = driverId;
  //     globalMatchedRideIds.rideId = rideId;
  //     globalMatchedRideIds.fare = fare;
  //     print("Ride Id : $rideId");
  //     List<dynamic> rideDataList = await fetchingPassengerRideData(widget.documentName);
  //
  //     if (rideDataList.isEmpty) {
  //       print("Failed to fetch ride data.");
  //       return;
  //     }
  //     print("Ride Id : $rideId");
  //     QuerySnapshot querySnapshot = await FirebaseFirestore.instance
  //         .collection('rides')
  //         .where('rideId', isEqualTo: rideId)
  //         .get();
  //
  //     print("Pass Ride Data $rideDataList");
  //
  //     if (querySnapshot.docs.isNotEmpty) {
  //       DocumentSnapshot documentSnapshot = querySnapshot.docs.first;
  //       String source = rideDataList[3];
  //       String destination = rideDataList[4];
  //
  //       await documentSnapshot.reference.collection('AcceptedRides').add({
  //         'rideStatus': 'accepted',
  //         'passengerId': currentUser?.uid,
  //         'driverId': driverId,
  //         'passengerFare': fare,
  //         'passengerSource': source,
  //         'passengerDestination': destination,
  //       });
  //
  //       print("Ride status updated successfully.");
  //     } else {
  //       print('No document found with the rideId: $rideId');
  //     }
  //   } catch (e) {
  //     print('Error in rideStatusUpdate: $e');
  //   }
  // }

//   Future<void> rideStatusUpdate(int count) async {
//     globalMatchedRideIds.driverId = widget.userIds[count];
//     globalMatchedRideIds.rideId = widget.matchedRideIds[count];
//     globalMatchedRideIds.fare = passengerRideData.passengerFares[count];
//     // Future<List<dynamic>> passRideData= fetchingPassengerRideData(widget.documentName);
//     List<dynamic> rideDataList = await fetchingPassengerRideData(widget.documentName);
//     QuerySnapshot querySnapshot = await FirebaseFirestore.instance
//         .collection('rides')
//         .where('rideId', isEqualTo: widget.matchedRideIds[count])
//         .get();
// print("Pass Ride Data $rideDataList");
//     if (querySnapshot.docs.isNotEmpty) {
//       DocumentSnapshot documentSnapshot = querySnapshot.docs.first;
//       String source = rideDataList[3];
//       String destination = rideDataList[4];
//       await documentSnapshot.reference.collection('AcceptedRides').add({
//         'rideStatus': 'accepted',
//         'passengerId': currentUser?.uid,
//         'driverId': globalMatchedRideIds.driverId,
//         'passengerFare': globalMatchedRideIds.fare,
//         'passengerSource': source,
//         'passengerDestination': destination,
//       });
//     } else {
//       print(
//           'No document found with the rideId: ${globalMatchedRideIds.rideId}');
//     }
//   }

  Future<bool> checkIfFavorite(String matchedUserId) {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    print("Matched User Ids1: ${widget.userIds}");
    return FirebaseFirestore.instance
        .collection('All_Friends')
        .doc(currentUserUid)
        .collection('friend')
        .doc(matchedUserId)
        .get()
        .then((snapshot) => snapshot.exists);
  }

  // Future<Map<String, dynamic>> getRideData(String matchedUserId) async {
  //   print("UserIDSss ${widget.userIds}");
  //   // Call all the necessary methods to fetch ride data
  //   List<String> rideImages = await RideDataProvider(
  //           passengerSourceLatitude: 0.0,
  //           passengerSourceLongitude: 0.0,
  //           vehicleType: '',
  //           passengerDestinationLatitude: 0.0,
  //           passengerDestinationLongitude: 0.0)
  //       .getUsersImages(widget.userIds);
  //   List<String> rideDriverNames = await RideDataProvider(
  //           passengerSourceLatitude: 0.0,
  //           passengerSourceLongitude: 0.0,
  //           vehicleType: '',
  //           passengerDestinationLatitude: 0.0,
  //           passengerDestinationLongitude: 0.0)
  //       .ridedriverName(widget.userIds);
  //   Map<String, List<String>> vehicleDataMap = await RideDataProvider(
  //           passengerSourceLatitude: 0.0,
  //           passengerSourceLongitude: 0.0,
  //           vehicleType: '',
  //           passengerDestinationLatitude: 0.0,
  //           passengerDestinationLongitude: 0.0)
  //       .vehicleData(widget.userIds);
  //   List<double> passengerFares = await RideDataProvider(
  //           passengerSourceLatitude: 0.0,
  //           passengerSourceLongitude: 0.0,
  //           vehicleType: '',
  //           passengerDestinationLatitude: 0.0,
  //           passengerDestinationLongitude: 0.0)
  //       .fareEstimation(widget.userIds);
  //
  //   // Construct a map to hold all the data
  //   Map<String, dynamic> rideData = {
  //     'rideImages': rideImages,
  //     'rideDriverNames': rideDriverNames,
  //     'vehicleData': vehicleDataMap,
  //     'passengerFares': passengerFares,
  //   };
  //
  //   // Return the map containing all the ride data
  //   return rideData;
  // }

  Future<List<Map<String, dynamic>>> getData() async {
    final data = await RideDataProvider(
            passengerSourceLatitude: 0.0,
            passengerSourceLongitude: 0.0,
            vehicleType: '',
            passengerDestinationLatitude: 0.0,
            passengerDestinationLongitude: 0.0)
        .joinRidesAndDriversData(widget.userIds);
    await RideDataProvider(
            passengerSourceLatitude: 0.0,
            passengerSourceLongitude: 0.0,
            vehicleType: '',
            passengerDestinationLatitude: 0.0,
            passengerDestinationLongitude: 0.0)
        .fareEstimation(widget.userIds, widget.matchedRideIds,
            widget.documentName, widget.vehicleType);
    print("Data1 ${data.length}");
    print("UserIDSss ${widget.userIds.length}");
    print("RideIds ${widget.matchedRideIds.length}");

    return data;
  }

  @override
  void initState() {
    super.initState();
    // RideDataProvider(
    //     passengerSourceLatitude: 0.0,
    //     passengerSourceLongitude: 0.0,
    //     vehicleType: '',
    //     passengerDestinationLatitude: 0.0,
    //     passengerDestinationLongitude: 0.0)
    //     .fareEstimation(widget.userIds,widget.matchedRideIds,widget.documentName);
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
            Expanded(
              child: Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HomeScreen()),
                    );
                  },
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: getData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading data'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No Ride Found'));
          } else {
            List<Map<String, dynamic>> dataList = snapshot.data!;
            print(dataList);
            return ListView.builder(
              itemCount: dataList.length,
              itemBuilder: (context, index) {
                var userId = widget.userIds[index];

                return Card(
                  margin: EdgeInsets.all(10), // Add margin around the card
                  elevation:
                      4, // Add shadow to the card for better visual effect
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        10), // Rounded corners for the card
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(10), // Add padding inside the card
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal:
                                  5), // Add padding to the ListTile content
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(
                                dataList[index]['users']['image'].toString()),
                          ),
                          subtitle: Text(
                            '${dataList[index]['vehicle']['color']} ${dataList[index]['vehicle']['brand']} ${dataList[index]['vehicle']['model']}',
                            style: TextStyle(
                                fontSize: 14), // Bold text for the title
                          ), // Vehicle data
                          title: Row(
                            children: [
                              Text(
                                "${dataList[index]['users']['displayName']}",
                                style: TextStyle(
                                    fontSize:
                                        17), // Customize subtitle text style
                              ),
                              FutureBuilder<bool>(
                                future: checkIfFavorite(widget.userIds[index]),
                                builder:
                                    (context, AsyncSnapshot<bool> snapshot) {
                                  final isFavorite = snapshot.data ?? false;
                                  return isFavorite
                                      ? Icon(Icons.favorite,
                                          size: 16, color: Color(0xff52c498))
                                      : SizedBox.shrink();
                                },
                              ),
                            ],
                          ),
                          trailing: Text(
                            'Pkr ${passengerRideData.passengerFares[index].toStringAsFixed(0)}',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xff008955),
                                fontSize:
                                    17), // Bold text for the trailing text
                          ),
                        ),
                        SizedBox(
                            height: 8), // Add space between ListTile and button
                        ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all<Color>(
                                Color(0xff008955)), // Button color
                            foregroundColor:
                                MaterialStateProperty.all<Color>(Colors.white),
                            padding: MaterialStateProperty.all<EdgeInsets>(
                                EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 40)), // Button padding
                            shape: MaterialStateProperty.all<
                                RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    20), // Rounded corners for the button
                              ),
                            ),
                          ),
                          onPressed: () {
                            // Get the index of the clicked ride
                            int selectedIndex = index;
                            rideStatusUpdate(selectedIndex);
                            globalMatchedRideIds
                                    .passengerLocationUpdateSubscription =
                                startPassengerLocationUpdates(currentUser!.uid);
                            if (selectedIndex < dataList.length &&
                                selectedIndex <
                                    dataList[index]['users'].length &&
                                selectedIndex <
                                    dataList[index]['vehicle'].length) {
                              // Navigate to AcceptRide widget
                              Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AcceptRide(
                                      rideId:
                                          widget.matchedRideIds[selectedIndex],
                                      documentName: widget.documentName.id,
                                      count: selectedIndex,
                                      driverName: dataList[selectedIndex]
                                              ['users']['displayName']
                                          .toString(),
                                      vehicleColor: dataList[selectedIndex]
                                              ['vehicle']['color']
                                          .toString(),
                                      vehicleBrand: dataList[selectedIndex]
                                              ['vehicle']['brand']
                                          .toString(),
                                      vehicleModel: dataList[selectedIndex]
                                              ['vehicle']['model']
                                          .toString(),
                                      driverUserId: dataList[selectedIndex]
                                              ['users']['uid']
                                          .toString(),
                                    ),
                                  ),
                                  (route) => false);
                              print("Count $selectedIndex");
                            } else {
                              print(dataList[selectedIndex]['users']
                                      ['displayName']
                                  .toString());
                              print(dataList[selectedIndex]['vehicle']['color']
                                  .toString());
                              print(dataList[selectedIndex]['vehicle']['brand']
                                  .toString());
                              print(dataList[selectedIndex]['vehicle']['model']
                                  .toString());
                              print(dataList[selectedIndex]['users']['uid']
                                  .toString());

                              print("Invalid index: $selectedIndex");
                            }
                          },
                          child: const Text(
                            'Accept',
                            style: TextStyle(fontSize: 17),
                          ),
                        ),
                      ],
                    ),
                  ),
                );

                // return Card(
                //   child: Column(
                //     children: [
                //       ListTile(
                //         leading: CircleAvatar(
                //           backgroundImage: NetworkImage(dataList[index]['users']
                //           ['image']
                //               .toString()), // User image
                //         ),
                //         title: Text(
                //             '${dataList[index]['vehicle']['color']} ${dataList[index]['vehicle']['brand']} ${dataList[index]['vehicle']['model']}'), // Vehicle data
                //         subtitle: Row(
                //           children: [
                //             Text("${dataList[index]['users']['displayName']}"),
                //             FutureBuilder<bool>(
                //               future: checkIfFavorite(widget.userIds[index]),
                //               builder: (context, AsyncSnapshot<bool> snapshot) {
                //                 final isFavorite = snapshot.data ?? false;
                //                 return isFavorite
                //                     ? Icon(Icons.favorite,
                //                     size: 12, color: Color(0xff52c498))
                //                     : SizedBox.shrink();
                //               },
                //             ),
                //           ],
                //         ),
                //         trailing: Text(
                //           'Pkr ${passengerRideData.passengerFares[index].toStringAsFixed(0)}',
                //         ),
                //       ),
                //       ElevatedButton(
                //         style: ButtonStyle(
                //           backgroundColor: MaterialStateProperty.all<Color>(
                //               Color(0xff52c498)),
                //           foregroundColor:
                //           MaterialStateProperty.all<Color>(Colors.white),
                //           minimumSize: MaterialStateProperty.all<Size>(
                //             Size(160,
                //                 40), // Change the width (and height) as needed
                //           ),
                //         ),
                //         onPressed: () {
                //           // Get the index of the clicked ride
                //           int selectedIndex = index;
                //           rideStatusUpdate(selectedIndex);
                //           globalMatchedRideIds
                //               .passengerLocationUpdateSubscription =
                //               startPassengerLocationUpdates(currentUser!.uid);
                //           if (selectedIndex < dataList.length &&
                //               selectedIndex < dataList[index]['users'].length &&
                //               selectedIndex <
                //                   dataList[index]['vehicle'].length) {
                //             // Navigate to AcceptRide widget
                //             Navigator.push(
                //               context,
                //               MaterialPageRoute(
                //                 builder: (context) => AcceptRide(
                //                   count: selectedIndex,
                //                   driverName: dataList[selectedIndex]['users']
                //                   ['displayName']
                //                       .toString(),
                //                   vehicleColor: dataList[selectedIndex]
                //                   ['vehicle']['color']
                //                       .toString(),
                //                   vehicleBrand: dataList[selectedIndex]
                //                   ['vehicle']['brand']
                //                       .toString(),
                //                   vehicleModel: dataList[selectedIndex]
                //                   ['vehicle']['model']
                //                       .toString(),
                //                   driverUserId: dataList[selectedIndex]['users']
                //                   ['uid']
                //                       .toString(),
                //                 ),
                //               ),
                //             );
                //             print("Count $selectedIndex");
                //           } else {
                //             print(dataList[selectedIndex]['users']
                //             ['displayName']
                //                 .toString());
                //             print(dataList[selectedIndex]['vehicle']['color']
                //                 .toString());
                //             print(dataList[selectedIndex]['vehicle']['brand']
                //                 .toString());
                //             print(dataList[selectedIndex]['vehicle']['model']
                //                 .toString());
                //             print(dataList[selectedIndex]['users']['uid']
                //                 .toString());
                //
                //             print("Invalid index: $selectedIndex");
                //           }
                //         },
                //         child: const Text(
                //           'Accept',
                //           style: TextStyle(fontSize: 17),
                //         ),
                //       ),
                //     ],
                //   ),
                // );
              },
            );
          }
        },
      ),
    );
  }
}
// import 'dart:async';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart' as loc;
// import 'package:hitchify/passengerSideRide/acceptedRide.dart';
// import 'package:hitchify/home/home_screen.dart';
//
// import 'GlobalMatchedRideIds.dart';
// import 'match_rides.dart';
//
// class AvailableRides extends StatefulWidget {
//   final List<loc.Marker> availableRides;
//   final List<String> userIds;
//   final List<String> matchedRideIds;
//   DocumentReference documentName;
//
//   AvailableRides({
//     required this.availableRides,
//     required this.matchedRideIds,
//     required this.userIds,
//     required this.documentName
//   });
//
//   AvailableRides.userid({
//     required this.userIds,
//     this.availableRides = const [],
//     this.matchedRideIds = const [],
//     required this.documentName
//   });
//
//   @override
//   _AvailableRidesState createState() => _AvailableRidesState();
// }
//
// class _AvailableRidesState extends State<AvailableRides> {
//   final User? currentUser = FirebaseAuth.instance.currentUser;
//
//   StreamSubscription<Position> startPassengerLocationUpdates(
//       String passengerId) {
//     StreamController<Position> controller = StreamController();
//
//     Timer timer = Timer.periodic(Duration(seconds: 20), (Timer t) async {
//       try {
//         Position position = await Geolocator.getCurrentPosition(
//           desiredAccuracy: LocationAccuracy.high,
//         );
//
//         print('Current position: $position');
//
//         await FirebaseFirestore.instance
//             .collection('PassengersLocations')
//             .doc(passengerId)
//             .set({
//           'location': GeoPoint(position.latitude, position.longitude),
//           'passengerId': passengerId,
//         });
//
//         controller.add(position);
//       } catch (e) {
//         print('Error getting current position: $e');
//       }
//     });
//
//     controller.onCancel = () {
//       timer.cancel();
//     };
//
//     return controller.stream.listen(null);
//   }
//
//   Future<List<dynamic>> fetchingPassengerRideData(DocumentReference docRef) async {
//     FirebaseFirestore firestore = FirebaseFirestore.instance;
//     Map<String, dynamic>? passRideData;
//     try {
//       DocumentSnapshot passengerRidedocSnapshot =
//       await firestore.collection('passengerride').doc(docRef.id).get();
//
//       if (passengerRidedocSnapshot.exists) {
//         // Extract data from the document
//         passRideData = passengerRidedocSnapshot.data() as Map<String, dynamic>;
//         print('Document data: $passRideData');
//         print('Document data: ${passRideData['sourceLatitude']}');
//       } else {
//         print('Document does not exist!');
//         return []; // Return an empty list if the document doesn't exist
//       }
//     } catch (e) {
//       print('Error fetching vehicle data: $e');
//       // Handle the error appropriately (e.g., throw or return default value)
//       return [];
//     }
//
//     // Create a list to store the extracted values
//     List<dynamic> rideDataList = [];
//
//     // Add each value to the list
//     rideDataList.add(passRideData!['date']);
//     rideDataList.add(passRideData!['sourceLatitude']);
//     rideDataList.add(passRideData!['sourceLongitude']);
//     rideDataList.add(passRideData!['source']);
//     rideDataList.add(passRideData['destination']);
//     rideDataList.add(passRideData['destinationLatitude']);
//     rideDataList.add(passRideData['destinationLongitude']);
//     rideDataList.add(passRideData['time']);
//     // Convert 'persons' string to int and add to the list
//     rideDataList.add(int.parse(passRideData['persons']));
//     rideDataList.add(passRideData['vehicle']);
//     rideDataList.add(passRideData['userId']);
//
//     // Return the list containing extracted values
//     return rideDataList;
//   }
//
//   Future<void> rideStatusUpdate(int count) async {
//     globalMatchedRideIds.driverId = widget.userIds[count];
//     globalMatchedRideIds.rideId = widget.matchedRideIds[count];
//     globalMatchedRideIds.fare = passengerRideData.passengerFares[count];
//     // Future<List<dynamic>> passRideData= fetchingPassengerRideData(widget.documentName);
//     List<dynamic> rideDataList = await fetchingPassengerRideData(widget.documentName);
//     QuerySnapshot querySnapshot = await FirebaseFirestore.instance
//         .collection('rides')
//         .where('rideId', isEqualTo: globalMatchedRideIds.rideId)
//         .get();
//     print("Pass Ride Data $rideDataList");
//     if (querySnapshot.docs.isNotEmpty) {
//       DocumentSnapshot documentSnapshot = querySnapshot.docs.first;
//       String source = rideDataList[3];
//       String destination = rideDataList[4];
//       await documentSnapshot.reference.collection('AcceptedRides').add({
//         'rideStatus': 'accepted',
//         'passengerId': currentUser?.uid,
//         'driverId': globalMatchedRideIds.driverId,
//         'passengerFare': globalMatchedRideIds.fare,
//         'passengerSource': source,
//         'passengerDestination': destination,
//       });
//     } else {
//       print(
//           'No document found with the rideId: ${globalMatchedRideIds.rideId}');
//     }
//   }
//
//   Future<bool> checkIfFavorite(String matchedUserId) {
//     final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
//     return FirebaseFirestore.instance
//         .collection('All_Friends')
//         .doc(currentUserUid)
//         .collection('friend')
//         .doc(matchedUserId)
//         .get()
//         .then((snapshot) => snapshot.exists);
//   }
//
//   Future<List<Map<String, dynamic>>> getData() async {
//     final data = await RideDataProvider(
//         passengerSourceLatitude: 0.0,
//         passengerSourceLongitude: 0.0,
//         vehicleType: '',
//         passengerDestinationLatitude: 0.0,
//         passengerDestinationLongitude: 0.0)
//         .joinRidesAndDriversData(widget.userIds);
//     RideDataProvider(
//         passengerSourceLatitude: 0.0,
//         passengerSourceLongitude: 0.0,
//         vehicleType: '',
//         passengerDestinationLatitude: 0.0,
//         passengerDestinationLongitude: 0.0)
//         .fareEstimation(widget.userIds,widget.matchedRideIds,widget.documentName);
//     print("Data1 ${data.length}");
//     print("UserIDSss ${widget.userIds.length}");
//     print("RideIds ${widget.matchedRideIds.length}");
//
//     return data;
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     RideDataProvider(
//         passengerSourceLatitude: 0.0,
//         passengerSourceLongitude: 0.0,
//         vehicleType: '',
//         passengerDestinationLatitude: 0.0,
//         passengerDestinationLongitude: 0.0)
//         .fareEstimation(widget.userIds,widget.matchedRideIds,widget.documentName);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF08B783),
//         title: Row(
//           children: [
//             Align(
//               alignment: Alignment.topLeft,
//               child: Text('Rides'),
//             ),
//             Expanded(
//               child: Align(
//                 alignment: Alignment.topRight,
//                 child: TextButton(
//                   onPressed: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(builder: (context) => HomeScreen()),
//                     );
//                   },
//                   child: Text(
//                     "Cancel",
//                     style: TextStyle(
//                       color: Colors.black,
//                       fontSize: 20,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//       body: FutureBuilder<List<Map<String, dynamic>>>(
//         future: getData(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return Center(
//               child: CircularProgressIndicator(),
//             );
//           } else if (snapshot.hasError) {
//             return const Center(child: Text('Error loading data'));
//           } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//             return const Center(child: Text('No Ride Found'));
//           } else {
//             List<Map<String, dynamic>> dataList = snapshot.data!;
//             print(dataList);
//             return ListView.builder(
//               itemCount: dataList.length,
//               itemBuilder: (context, index) {
//                 var userId = widget.userIds[index];
//
//                 return Card(
//                   child: Column(
//                     children: [
//                       ListTile(
//                         leading: CircleAvatar(
//                           backgroundImage: NetworkImage(dataList[index]['users']
//                           ['image']
//                               .toString()), // User image
//                         ),
//                         title: Text(
//                             '${dataList[index]['vehicle']['color']} ${dataList[index]['vehicle']['brand']} ${dataList[index]['vehicle']['model']}'), // Vehicle data
//                         subtitle: Row(
//                           children: [
//                             Text("${dataList[index]['users']['displayName']}"),
//                             FutureBuilder<bool>(
//                               future: checkIfFavorite(widget.userIds[index]),
//                               builder: (context, AsyncSnapshot<bool> snapshot) {
//                                 final isFavorite = snapshot.data ?? false;
//                                 return isFavorite
//                                     ? Icon(Icons.favorite,
//                                     size: 12, color: Color(0xff52c498))
//                                     : SizedBox.shrink();
//                               },
//                             ),
//                           ],
//                         ),
//                         trailing: Text(
//                           'Pkr ${passengerRideData.passengerFares[index].toStringAsFixed(0)}',
//                         ),
//                       ),
//                       ElevatedButton(
//                         style: ButtonStyle(
//                           backgroundColor:
//                           MaterialStateProperty.all<Color>(Color(0xff52c498)),
//                           foregroundColor:
//                           MaterialStateProperty.all<Color>(Colors.white),
//                           minimumSize: MaterialStateProperty.all<Size>(
//                             Size(160,
//                                 40), // Change the width (and height) as needed
//                           ),
//                         ),
//                         onPressed: () {
//                           // Get the index of the clicked ride
//                           int selectedIndex = index;
//                           rideStatusUpdate(selectedIndex);
//                           globalMatchedRideIds
//                               .passengerLocationUpdateSubscription =
//                               startPassengerLocationUpdates(currentUser!.uid);
//                           if (selectedIndex < dataList.length &&
//                               selectedIndex < dataList[index]['users'].length &&
//                               selectedIndex <
//                                   dataList[index]['vehicle'].length) {
//                             // Navigate to AcceptRide widget
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => AcceptRide(
//                                   count: selectedIndex,
//                                   driverName: dataList[selectedIndex]['users']
//                                   ['displayName']
//                                       .toString(),
//                                   vehicleColor: dataList[selectedIndex]
//                                   ['vehicle']['color']
//                                       .toString(),
//                                   vehicleBrand: dataList[selectedIndex]
//                                   ['vehicle']['brand']
//                                       .toString(),
//                                   vehicleModel: dataList[selectedIndex]
//                                   ['vehicle']['model']
//                                       .toString(),
//                                   driverUserId: dataList[selectedIndex]['users']
//                                   ['uid']
//                                       .toString(),
//                                 ),
//                               ),
//                             );
//                             print("Count $selectedIndex");
//                           } else {
//                             print(dataList[selectedIndex]['users']
//                             ['displayName']
//                                 .toString());
//                             print(dataList[selectedIndex]['vehicle']['color']
//                                 .toString());
//                             print(dataList[selectedIndex]['vehicle']['brand']
//                                 .toString());
//                             print(dataList[selectedIndex]['vehicle']['model']
//                                 .toString());
//                             print(dataList[selectedIndex]['users']['uid']
//                                 .toString());
//
//                             print("Invalid index: $selectedIndex");
//                           }
//                         },
//                         child: const Text(
//                           'Accept',
//                           style: TextStyle(fontSize: 17),
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             );
//           }
//         },
//       ),
//     );
//   }
// }

// import 'dart:async';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart' as loc;
// import 'package:hitchify/passengerSideRide/acceptedRide.dart';
// import 'package:hitchify/home/home_screen.dart';
//
// import 'GlobalMatchedRideIds.dart';
// import 'match_rides.dart';
//
// class AvailableRides extends StatefulWidget {
//   final List<loc.Marker> availableRides;
//   final List<String> userIds;
//   final List<String> matchedRideIds;
//   DocumentReference documentName;
//
//   AvailableRides(
//       {required this.availableRides,
//       required this.matchedRideIds,
//       required this.userIds,
//       required this.documentName});
//
//   AvailableRides.userid(
//       {required this.userIds,
//       this.availableRides = const [],
//       this.matchedRideIds = const [],
//       required this.documentName});
//
//   @override
//   _AvailableRidesState createState() => _AvailableRidesState();
// }
//
// class _AvailableRidesState extends State<AvailableRides> {
//   final User? currentUser = FirebaseAuth.instance.currentUser;
//
//   StreamSubscription<Position> startPassengerLocationUpdates(
//       String passengerId) {
//     StreamController<Position> controller = StreamController();
//
//     Timer timer = Timer.periodic(Duration(seconds: 20), (Timer t) async {
//       try {
//         Position position = await Geolocator.getCurrentPosition(
//           desiredAccuracy: LocationAccuracy.high,
//         );
//
//         print('Current position: $position');
//
//         await FirebaseFirestore.instance
//             .collection('PassengersLocations')
//             .doc(passengerId)
//             .set({
//           'location': GeoPoint(position.latitude, position.longitude),
//           'passengerId': passengerId,
//         });
//
//         controller.add(position);
//       } catch (e) {
//         print('Error getting current position: $e');
//       }
//     });
//
//     controller.onCancel = () {
//       timer.cancel();
//     };
//
//     return controller.stream.listen(null);
//   }
//
//   Future<List<dynamic>> fetchingPassengerRideData(
//       DocumentReference docRef) async {
//     FirebaseFirestore firestore = FirebaseFirestore.instance;
//     Map<String, dynamic>? passRideData;
//     try {
//       DocumentSnapshot passengerRidedocSnapshot =
//           await firestore.collection('passengerride').doc(docRef.id).get();
//
//       if (passengerRidedocSnapshot.exists) {
//         // Extract data from the document
//         passRideData = passengerRidedocSnapshot.data() as Map<String, dynamic>;
//         print('Document data: $passRideData');
//         print('Document data: ${passRideData['sourceLatitude']}');
//       } else {
//         print('Document does not exist!');
//         return []; // Return an empty list if the document doesn't exist
//       }
//     } catch (e) {
//       print('Error fetching vehicle data: $e');
//       // Handle the error appropriately (e.g., throw or return default value)
//       return [];
//     }
//
//     // Create a list to store the extracted values
//     List<dynamic> rideDataList = [];
//
//     // Add each value to the list
//     rideDataList.add(passRideData!['date']);
//     rideDataList.add(passRideData!['sourceLatitude']);
//     rideDataList.add(passRideData!['sourceLongitude']);
//     rideDataList.add(passRideData!['source']);
//     rideDataList.add(passRideData['destination']);
//     rideDataList.add(passRideData['destinationLatitude']);
//     rideDataList.add(passRideData['destinationLongitude']);
//     rideDataList.add(passRideData['time']);
//     // Convert 'persons' string to int and add to the list
//     rideDataList.add(int.parse(passRideData['persons']));
//     rideDataList.add(passRideData['vehicle']);
//     rideDataList.add(passRideData['userId']);
//
//     // Return the list containing extracted values
//     return rideDataList;
//   }
//
//   Future<void> rideStatusUpdate(int count) async {
//     try {
//       final driverId = widget.userIds[count];
//       final rideId = widget.matchedRideIds[count];
//       final fare = passengerRideData.passengerFares[count];
//       globalMatchedRideIds.driverId = driverId;
//       globalMatchedRideIds.rideId = rideId;
//       globalMatchedRideIds.fare = fare;
//       print("Ride Id : $rideId");
//       print("Count$count");
//       print("DriverIDd$driverId");
//       List<dynamic> rideDataList =
//           await fetchingPassengerRideData(widget.documentName);
//
//       if (rideDataList.isEmpty) {
//         print("Failed to fetch ride data.");
//         return;
//       }
//       print("Ride Id : $rideId");
//       QuerySnapshot querySnapshot = await FirebaseFirestore.instance
//           .collection('rides')
//           .where('rideId', isEqualTo: rideId)
//           .get();
//
//       print("Pass Ride Data $rideDataList");
//
//       if (querySnapshot.docs.isNotEmpty) {
//         DocumentSnapshot documentSnapshot = querySnapshot.docs.first;
//         String source = rideDataList[3];
//         String destination = rideDataList[4];
//
//         DocumentReference newDocRef =
//             await documentSnapshot.reference.collection('AcceptedRides').add({
//           'rideStatus': 'accepted',
//           'passengerId': currentUser?.uid,
//           'driverId': driverId,
//           'passengerFare': fare,
//           'passengerSource': source,
//           'passengerDestination': destination,
//         });
//
//         print("Ride status updated successfully. Document ID: ${newDocRef.id}");
//       } else {
//         print('No document found with the rideId: $rideId');
//       }
//     } catch (e) {
//       print('Error in rideStatusUpdate: $e');
//     }
//   }
//
//   // Future<void> rideStatusUpdate(int count) async {
//   //   try {
//   //     final driverId = widget.userIds[count];
//   //     final rideId = widget.matchedRideIds[count];
//   //     final fare = passengerRideData.passengerFares[count];
//   //     globalMatchedRideIds.driverId = driverId;
//   //     globalMatchedRideIds.rideId = rideId;
//   //     globalMatchedRideIds.fare = fare;
//   //     print("Ride Id : $rideId");
//   //     List<dynamic> rideDataList = await fetchingPassengerRideData(widget.documentName);
//   //
//   //     if (rideDataList.isEmpty) {
//   //       print("Failed to fetch ride data.");
//   //       return;
//   //     }
//   //     print("Ride Id : $rideId");
//   //     QuerySnapshot querySnapshot = await FirebaseFirestore.instance
//   //         .collection('rides')
//   //         .where('rideId', isEqualTo: rideId)
//   //         .get();
//   //
//   //     print("Pass Ride Data $rideDataList");
//   //
//   //     if (querySnapshot.docs.isNotEmpty) {
//   //       DocumentSnapshot documentSnapshot = querySnapshot.docs.first;
//   //       String source = rideDataList[3];
//   //       String destination = rideDataList[4];
//   //
//   //       await documentSnapshot.reference.collection('AcceptedRides').add({
//   //         'rideStatus': 'accepted',
//   //         'passengerId': currentUser?.uid,
//   //         'driverId': driverId,
//   //         'passengerFare': fare,
//   //         'passengerSource': source,
//   //         'passengerDestination': destination,
//   //       });
//   //
//   //       print("Ride status updated successfully.");
//   //     } else {
//   //       print('No document found with the rideId: $rideId');
//   //     }
//   //   } catch (e) {
//   //     print('Error in rideStatusUpdate: $e');
//   //   }
//   // }
//
// //   Future<void> rideStatusUpdate(int count) async {
// //     globalMatchedRideIds.driverId = widget.userIds[count];
// //     globalMatchedRideIds.rideId = widget.matchedRideIds[count];
// //     globalMatchedRideIds.fare = passengerRideData.passengerFares[count];
// //     // Future<List<dynamic>> passRideData= fetchingPassengerRideData(widget.documentName);
// //     List<dynamic> rideDataList = await fetchingPassengerRideData(widget.documentName);
// //     QuerySnapshot querySnapshot = await FirebaseFirestore.instance
// //         .collection('rides')
// //         .where('rideId', isEqualTo: widget.matchedRideIds[count])
// //         .get();
// // print("Pass Ride Data $rideDataList");
// //     if (querySnapshot.docs.isNotEmpty) {
// //       DocumentSnapshot documentSnapshot = querySnapshot.docs.first;
// //       String source = rideDataList[3];
// //       String destination = rideDataList[4];
// //       await documentSnapshot.reference.collection('AcceptedRides').add({
// //         'rideStatus': 'accepted',
// //         'passengerId': currentUser?.uid,
// //         'driverId': globalMatchedRideIds.driverId,
// //         'passengerFare': globalMatchedRideIds.fare,
// //         'passengerSource': source,
// //         'passengerDestination': destination,
// //       });
// //     } else {
// //       print(
// //           'No document found with the rideId: ${globalMatchedRideIds.rideId}');
// //     }
// //   }
//
//   Future<bool> checkIfFavorite(String matchedUserId) {
//     final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
//     print("Matched User Ids1: ${widget.userIds}");
//     return FirebaseFirestore.instance
//         .collection('All_Friends')
//         .doc(currentUserUid)
//         .collection('friend')
//         .doc(matchedUserId)
//         .get()
//         .then((snapshot) => snapshot.exists);
//   }
//
//   // Future<Map<String, dynamic>> getRideData(String matchedUserId) async {
//   //   print("UserIDSss ${widget.userIds}");
//   //   // Call all the necessary methods to fetch ride data
//   //   List<String> rideImages = await RideDataProvider(
//   //           passengerSourceLatitude: 0.0,
//   //           passengerSourceLongitude: 0.0,
//   //           vehicleType: '',
//   //           passengerDestinationLatitude: 0.0,
//   //           passengerDestinationLongitude: 0.0)
//   //       .getUsersImages(widget.userIds);
//   //   List<String> rideDriverNames = await RideDataProvider(
//   //           passengerSourceLatitude: 0.0,
//   //           passengerSourceLongitude: 0.0,
//   //           vehicleType: '',
//   //           passengerDestinationLatitude: 0.0,
//   //           passengerDestinationLongitude: 0.0)
//   //       .ridedriverName(widget.userIds);
//   //   Map<String, List<String>> vehicleDataMap = await RideDataProvider(
//   //           passengerSourceLatitude: 0.0,
//   //           passengerSourceLongitude: 0.0,
//   //           vehicleType: '',
//   //           passengerDestinationLatitude: 0.0,
//   //           passengerDestinationLongitude: 0.0)
//   //       .vehicleData(widget.userIds);
//   //   List<double> passengerFares = await RideDataProvider(
//   //           passengerSourceLatitude: 0.0,
//   //           passengerSourceLongitude: 0.0,
//   //           vehicleType: '',
//   //           passengerDestinationLatitude: 0.0,
//   //           passengerDestinationLongitude: 0.0)
//   //       .fareEstimation(widget.userIds);
//   //
//   //   // Construct a map to hold all the data
//   //   Map<String, dynamic> rideData = {
//   //     'rideImages': rideImages,
//   //     'rideDriverNames': rideDriverNames,
//   //     'vehicleData': vehicleDataMap,
//   //     'passengerFares': passengerFares,
//   //   };
//   //
//   //   // Return the map containing all the ride data
//   //   return rideData;
//   // }
//
//   Future<List<Map<String, dynamic>>> getData() async {
//     final data = await RideDataProvider(
//             passengerSourceLatitude: 0.0,
//             passengerSourceLongitude: 0.0,
//             vehicleType: '',
//             passengerDestinationLatitude: 0.0,
//             passengerDestinationLongitude: 0.0)
//         .joinRidesAndDriversData(widget.userIds);
//     await RideDataProvider(
//             passengerSourceLatitude: 0.0,
//             passengerSourceLongitude: 0.0,
//             vehicleType: '',
//             passengerDestinationLatitude: 0.0,
//             passengerDestinationLongitude: 0.0)
//         .fareEstimation(
//             widget.userIds, widget.matchedRideIds, widget.documentName);
//     print("Data1 ${data.length}");
//     print("UserIDSss ${widget.userIds.length}");
//     print("RideIds ${widget.matchedRideIds.length}");
//
//     return data;
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     // RideDataProvider(
//     //     passengerSourceLatitude: 0.0,
//     //     passengerSourceLongitude: 0.0,
//     //     vehicleType: '',
//     //     passengerDestinationLatitude: 0.0,
//     //     passengerDestinationLongitude: 0.0)
//     //     .fareEstimation(widget.userIds,widget.matchedRideIds,widget.documentName);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF08B783),
//         title: Row(
//           children: [
//             Align(
//               alignment: Alignment.topLeft,
//               child: Text('Rides'),
//             ),
//             Expanded(
//               child: Align(
//                 alignment: Alignment.topRight,
//                 child: TextButton(
//                   onPressed: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(builder: (context) => HomeScreen()),
//                     );
//                   },
//                   child: Text(
//                     "Cancel",
//                     style: TextStyle(
//                       color: Colors.black,
//                       fontSize: 20,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//       body: FutureBuilder<List<Map<String, dynamic>>>(
//         future: getData(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return Center(
//               child: CircularProgressIndicator(),
//             );
//           } else if (snapshot.hasError) {
//             return const Center(child: Text('Error loading data'));
//           } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//             return const Center(child: Text('No Ride Found'));
//           } else {
//             List<Map<String, dynamic>> dataList = snapshot.data!;
//             print(dataList);
//             return ListView.builder(
//               itemCount: dataList.length,
//               itemBuilder: (context, index) {
//                 var userId = widget.userIds[index];
//
//                 return Card(
//                   child: Column(
//                     children: [
//                       ListTile(
//                         leading: CircleAvatar(
//                           backgroundImage: NetworkImage(dataList[index]['users']
//                                   ['image']
//                               .toString()), // User image
//                         ),
//                         title: Text(
//                             '${dataList[index]['vehicle']['color']} ${dataList[index]['vehicle']['brand']} ${dataList[index]['vehicle']['model']}'), // Vehicle data
//                         subtitle: Row(
//                           children: [
//                             Text("${dataList[index]['users']['displayName']}"),
//                             FutureBuilder<bool>(
//                               future: checkIfFavorite(widget.userIds[index]),
//                               builder: (context, AsyncSnapshot<bool> snapshot) {
//                                 final isFavorite = snapshot.data ?? false;
//                                 return isFavorite
//                                     ? Icon(Icons.favorite,
//                                         size: 12, color: Color(0xff52c498))
//                                     : SizedBox.shrink();
//                               },
//                             ),
//                           ],
//                         ),
//                         trailing: Text(
//                           'Pkr ${passengerRideData.passengerFares[index].toStringAsFixed(0)}',
//                         ),
//                       ),
//                       ElevatedButton(
//                         style: ButtonStyle(
//                           backgroundColor: MaterialStateProperty.all<Color>(
//                               Color(0xff52c498)),
//                           foregroundColor:
//                               MaterialStateProperty.all<Color>(Colors.white),
//                           minimumSize: MaterialStateProperty.all<Size>(
//                             Size(160,
//                                 40), // Change the width (and height) as needed
//                           ),
//                         ),
//                         onPressed: () {
//                           // Get the index of the clicked ride
//                           int selectedIndex = index;
//                           rideStatusUpdate(selectedIndex);
//                           globalMatchedRideIds
//                                   .passengerLocationUpdateSubscription =
//                               startPassengerLocationUpdates(currentUser!.uid);
//                           if (selectedIndex < dataList.length &&
//                               selectedIndex < dataList[index]['users'].length &&
//                               selectedIndex <
//                                   dataList[index]['vehicle'].length) {
//                             // Navigate to AcceptRide widget
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => AcceptRide(
//                                   count: selectedIndex,
//                                   driverName: dataList[selectedIndex]['users']
//                                           ['displayName']
//                                       .toString(),
//                                   vehicleColor: dataList[selectedIndex]
//                                           ['vehicle']['color']
//                                       .toString(),
//                                   vehicleBrand: dataList[selectedIndex]
//                                           ['vehicle']['brand']
//                                       .toString(),
//                                   vehicleModel: dataList[selectedIndex]
//                                           ['vehicle']['model']
//                                       .toString(),
//                                   driverUserId: dataList[selectedIndex]['users']
//                                           ['uid']
//                                       .toString(),
//                                 ),
//                               ),
//                             );
//                             print("Count $selectedIndex");
//                           } else {
//                             print(dataList[selectedIndex]['users']
//                                     ['displayName']
//                                 .toString());
//                             print(dataList[selectedIndex]['vehicle']['color']
//                                 .toString());
//                             print(dataList[selectedIndex]['vehicle']['brand']
//                                 .toString());
//                             print(dataList[selectedIndex]['vehicle']['model']
//                                 .toString());
//                             print(dataList[selectedIndex]['users']['uid']
//                                 .toString());
//
//                             print("Invalid index: $selectedIndex");
//                           }
//                         },
//                         child: const Text(
//                           'Accept',
//                           style: TextStyle(fontSize: 17),
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             );
//           }
//         },
//       ),
//     );
//   }
// }
