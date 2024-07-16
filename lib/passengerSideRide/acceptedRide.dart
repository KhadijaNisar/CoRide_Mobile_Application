import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hitchify/global/map_key.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hitchify/home/home_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../chat/chat_page.dart';
import 'GlobalMatchedRideIds.dart';
import 'match_rides.dart';

class AcceptRide extends StatefulWidget {
  final String rideId;
  final String documentName;
  final int count;
  final String driverName;
  final String vehicleColor;
  final String vehicleBrand;
  final String vehicleModel;
  final String driverUserId;

  AcceptRide({
    required this.rideId,
    required this.documentName,
    required this.count,
    required this.driverName,
    required this.vehicleColor,
    required this.vehicleBrand,
    required this.vehicleModel,
    required this.driverUserId,
  });

  @override
  _AcceptRideState createState() => _AcceptRideState();
}

class _AcceptRideState extends State<AcceptRide> {
  LatLng? driverLocation;
  LatLng? passengerLocation;
  LatLng? destinationLocation;
  String currentUserUid = FirebaseAuth.instance.currentUser!.uid;

  bool _showSafetyTools = false;
  StreamSubscription<DocumentSnapshot>? _driverLocationSubscription;
  GoogleMapController? _mapController;
  Marker? _driverMarker;
  Marker? _passengerSourceMarker;
  Marker? _passengerDestinationMarker;

  Position? _currentLocation;
  Timer? _locationUpdateTimer;
  Completer<GoogleMapController> _controller = Completer();
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();

    _fetchLocation();
    _createPolylines();
    _fetchDriverLocationPoints();
    _fetchPassengerLocationPoints();
    _driverLocationSubscription = FirebaseFirestore.instance
        .collection('driversLocations')
        .doc(widget.driverUserId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final locationData = snapshot.data()!['location'];
        setState(() {
          driverLocation =
              LatLng(locationData.latitude, locationData.longitude);
          _updateDriverMarker(
              driverLocation!.latitude, driverLocation!.longitude);
        });
      }
      _addMarker(passengerLocation!.latitude, passengerLocation!.longitude,
          'source', 'source'); // San Francisco
      _addMarker(destinationLocation!.latitude, destinationLocation!.longitude,
          'destination', 'destination');
    });

    _locationUpdateTimer = Timer.periodic(Duration(seconds: 20), (timer) {
      _fetchDriverLocation();
      _createPolylines();
    });

    // Call createPolylines after setting initial locations
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      _createPolylines();
    });
  }

  void _addMarker(double lat, double lng, String markerId, String color) {
    final marker = Marker(
      markerId: MarkerId(markerId),
      position: LatLng(lat, lng),
      infoWindow: InfoWindow(title: 'Marker $markerId'),
      icon: BitmapDescriptor.defaultMarkerWithHue(color == 'source'
          ? BitmapDescriptor.hueGreen
          : BitmapDescriptor.hueRed),
    );
    setState(() {
      _markers.add(marker);
    });
  }

  Future<void> _fetchDriverLocationPoints() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('rides')
        .where('rideId', isEqualTo: widget.rideId)
        .get();

    for (var docSnapshot in querySnapshot.docs) {
      if (docSnapshot.exists) {
        LatLng driverLocationData = LatLng(docSnapshot.data()['sourceLatitude'],
            docSnapshot.data()['sourceLongitude']);

        setState(() {
          driverLocation = driverLocationData;
        });
      }
    }
  }

  Future<void> _fetchPassengerLocationPoints() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('passengerride')
        .doc(widget.documentName)
        .get();

    if (querySnapshot.exists) {
      passengerLocation = LatLng(
          querySnapshot['sourceLatitude'], querySnapshot['sourceLongitude']);
      destinationLocation = LatLng(querySnapshot['destinationLatitude'],
          querySnapshot['destinationLongitude']);

      setState(() {
        passengerLocation = passengerLocation;
        destinationLocation = destinationLocation;
      });
    }
  }

  Future<void> _fetchDriverLocation() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('driversLocations')
        .doc(widget.driverUserId)
        .get();
    if (snapshot.exists) {
      LatLng locationData = snapshot.data()!['location'];
      _updateDriverMarker(locationData.latitude, locationData.longitude);
      print(
          "Updating Driver Location to (${locationData.latitude}, ${locationData.longitude})");
    }
    print("Driver1111 ${widget.driverUserId}");
  }

  @override
  void dispose() {
    super.dispose();
    _driverLocationSubscription?.cancel();
    _locationUpdateTimer?.cancel();
  }

  Future<void> _fetchLocation() async {
    try {
      final status = await Permission.location.request();
      if (status.isGranted) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
        );
        setState(() {
          _currentLocation = position;
        });
      } else {
        print('Permission not granted');
      }
    } catch (e) {
      print('Error fetching location: $e');
    }
  }

  void _updateDriverMarker(double latitude, double longitude) {
    LatLng newDriverPosition = LatLng(latitude, longitude);
    print("Updating marker position to $newDriverPosition");

    setState(() {
      _driverMarker = Marker(
        markerId: MarkerId('driver'),
        position: newDriverPosition,
      );
      _markers.add(_driverMarker!);
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLng(newDriverPosition),
    );
  }

  Future<void> _createPolylines() async {
    String googleAPIKey = mapKey; // Replace with your Google Maps API key

    if (driverLocation == null || passengerLocation == null) {
      print("Driver or passenger location is null");
      return;
    }

    print("Creating polylines from $driverLocation to $passengerLocation");

    String urlDriverToPassenger =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${driverLocation!.latitude},${driverLocation!.longitude}&destination=${passengerLocation!.latitude},${passengerLocation!.longitude}&key=$googleAPIKey';
    http.Response responseDriverToPassenger =
        await http.get(Uri.parse(urlDriverToPassenger));
    Map valuesDriverToPassenger = jsonDecode(responseDriverToPassenger.body);

    String urlPassengerToDestination =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${passengerLocation!.latitude},${passengerLocation!.longitude}&destination=${destinationLocation?.latitude},${destinationLocation?.longitude}&key=$googleAPIKey';
    http.Response responsePassengerToDestination =
        await http.get(Uri.parse(urlPassengerToDestination));
    Map valuesPassengerToDestination =
        jsonDecode(responsePassengerToDestination.body);

    if (valuesDriverToPassenger['routes'].isEmpty ||
        valuesPassengerToDestination['routes'].isEmpty) {
      print("No routes found");
      return;
    }

    String polylinePointsDriverToPassenger =
        valuesDriverToPassenger['routes'][0]['overview_polyline']['points'];
    String polylinePointsPassengerToDestination =
        valuesPassengerToDestination['routes'][0]['overview_polyline']
            ['points'];
    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> resultDriverToPassenger =
        polylinePoints.decodePolyline(polylinePointsDriverToPassenger);
    List<PointLatLng> resultPassengerToDestination =
        polylinePoints.decodePolyline(polylinePointsPassengerToDestination);

    List<LatLng> polylineCoordinatesDriverToPassenger = resultDriverToPassenger
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList();
    List<LatLng> polylineCoordinatesPassengerToDestination =
        resultPassengerToDestination
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();

    Polyline polylineDriverToPassenger = Polyline(
      polylineId: PolylineId('driver_passenger'),
      visible: true,
      points: polylineCoordinatesDriverToPassenger,
      color: Colors.blue,
      width: 4,
    );
    Polyline polylinePassengerToDestination = Polyline(
      polylineId: PolylineId('passenger_destination'),
      visible: true,
      points: polylineCoordinatesPassengerToDestination,
      color: Colors.red,
      width: 4,
    );

    setState(() {
      _polylines.add(polylineDriverToPassenger);
      _polylines.add(polylinePassengerToDestination);
    });

    print("Polylines created and added to map");
  }

  Future<String> getDriverPhoneNumber() async {
    final docSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.driverUserId)
        .get();
    return docSnapshot.get('phoneNumber');
  }

  Future<String> getDriverEmail() async {
    final docSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.driverUserId)
        .get();
    return docSnapshot.get('email');
  }

  Future<String> getDriverImage() async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('user_images/${widget.driverUserId}');
    return await ref.getDownloadURL();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([getDriverPhoneNumber(), getDriverImage()]),
      builder: (context, AsyncSnapshot<List<String>> snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          final driverPhone = snapshot.data![0];
          final driverImage = snapshot.data![1];
          return Stack(
            children: [
              SafeArea(
                child: Scaffold(
                  appBar: PreferredSize(
                    preferredSize: Size.fromHeight(60),
                    child: Container(
                      // extra container for custom bottom shadows
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12.withOpacity(0.5),
                            spreadRadius: 10,
                            blurRadius: 6,
                            offset: Offset(0, -4),
                          ),
                        ],
                      ),
                      child: AppBar(
                        automaticallyImplyLeading:
                            false, // This hides the back arrow
                        backgroundColor: Color(0xff247758),
                        title: Align(
                          alignment: Alignment.topRight,
                          child: TextButton(
                            onPressed: () {
                              globalMatchedRideIds
                                  .driverLocationUpdateSubscription
                                  ?.cancel();
                              // cancelRide();
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => HomeScreen()));
                            },
                            child: Text(
                              "Cancel",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  body: Stack(
                    children: [
                      if (_currentLocation != null)
                        GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: passengerLocation!,
                            zoom: 14.0,
                          ),
                          polylines: _polylines,
                          markers: _markers,
                          onMapCreated: (GoogleMapController controller) {
                            _mapController = controller;
                          },
                        ),

                      // GoogleMap(
                      //   initialCameraPosition: CameraPosition(
                      //     target: LatLng(_currentLocation!.latitude,
                      //         _currentLocation!.longitude),
                      //     zoom: 14,
                      //   ),
                      //   markers: _driverMarker != null
                      //       ? {_driverMarker!}
                      //       : Set<Marker>(),
                      //   polylines: _polylines,
                      //   onMapCreated: (GoogleMapController controller) {
                      //     _controller.complete(controller);
                      //     _mapController = controller;
                      //   },
                      // ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: DraggableScrollableSheet(
                          initialChildSize: 0.3,
                          minChildSize: 0.3,
                          maxChildSize: 0.85,
                          builder: (context, scrollController) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Color(0xff247758),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                              ),
                              child: SingleChildScrollView(
                                controller: scrollController,
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ListTile(
                                        leading: CircleAvatar(
                                          backgroundImage:
                                              NetworkImage(driverImage),
                                        ),
                                        title: Text(
                                          widget.driverName,
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Text(
                                          '${widget.vehicleColor} ${widget.vehicleBrand} ${widget.vehicleModel}',
                                          style:
                                              TextStyle(color: Colors.white70),
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: Icon(Icons.phone,
                                                  color: Colors.white),
                                              onPressed: () async {
                                                String phoneNumber =
                                                    await getDriverPhoneNumber();
                                                launch("tel://$phoneNumber");
                                              },
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.mail,
                                                  color: Colors.white),
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        chatPage(
                                                            displayName: widget
                                                                .driverName,
                                                            image: driverImage,
                                                            receiverEmail:
                                                                getDriverEmail()
                                                                    .toString(),
                                                            receiverID: widget
                                                                .driverUserId),
                                                  ),
                                                );
                                              },
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.share,
                                                  color: Colors.white),
                                              onPressed: () {
                                                shareLiveLocation(
                                                    _currentLocation!);
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      ListTile(
                                        title: Text(
                                          'Safety Tools',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        trailing: IconButton(
                                          icon: Icon(
                                            _showSafetyTools
                                                ? Icons.arrow_drop_up
                                                : Icons.arrow_drop_down,
                                            color: Colors.white,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _showSafetyTools =
                                                  !_showSafetyTools;
                                            });
                                          },
                                        ),
                                      ),
                                      if (_showSafetyTools)
                                        Column(
                                          children: [
                                            ListTile(
                                              title: Text(
                                                'Call Police',
                                                style: TextStyle(
                                                    color: Colors.white),
                                              ),
                                              trailing: Icon(
                                                Icons.local_police,
                                                color: Colors.white,
                                              ),
                                              onTap: () {
                                                launch("tel://15");
                                              },
                                            ),
                                            ListTile(
                                                title: Text(
                                                  'Call Ambulance',
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                                trailing: Icon(
                                                  Icons.local_hospital,
                                                  color: Colors.white,
                                                ),
                                                onTap: () {
                                                  launch("tel://1122");
                                                }),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        } else {
          return Scaffold(
            appBar: AppBar(
              title: Text('Ride Details'),
            ),
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
    );
  }

  void shareLiveLocation(Position currentLocation) {
    double latitude = currentLocation.latitude;
    double longitude = currentLocation.longitude;

    String googleMapsUrl = 'https://www.google.com/maps?q=$latitude,$longitude';
    Share.share(googleMapsUrl);
  }
}

// import 'dart:async';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:hitchify/global/map_key.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:hitchify/home/home_screen.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'dart:convert';
// import 'package:flutter_polyline_points/flutter_polyline_points.dart';
// import 'package:http/http.dart' as http;
// import 'package:permission_handler/permission_handler.dart';
// import 'package:share_plus/share_plus.dart';
//
// import '../chat/chat_page.dart';
// import 'GlobalMatchedRideIds.dart';
// import 'match_rides.dart';
//
// class AcceptRide extends StatefulWidget {
//   final int count;
//   final String driverName;
//   final String vehicleColor;
//   final String vehicleBrand;
//   final String vehicleModel;
//   final String driverUserId;
//
//   AcceptRide({
//     required this.count,
//     required this.driverName,
//     required this.vehicleColor,
//     required this.vehicleBrand,
//     required this.vehicleModel,
//     required this.driverUserId,
//   });
//
//   @override
//   _AcceptRideState createState() => _AcceptRideState();
// }
//
// class _AcceptRideState extends State<AcceptRide> {
//   LatLng? driverLocation;
//   LatLng? passengerLocation;
//   String currentUserUid = FirebaseAuth.instance.currentUser!.uid ?? '';
//
//   bool _showSafetyTools = false;
//   StreamSubscription<DocumentSnapshot>? _driverLocationSubscription;
//   GoogleMapController? _mapController;
//   Marker? _driverMarker;
//
//   Position? _currentLocation;
//   Timer? _locationUpdateTimer;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchLocation();
//     driverLocation = LatLng(
//         passengerRideData.driverSourceLatitude[widget.count],
//         passengerRideData.driverSourceLongitude[widget.count]);
//     print("DriverLocation: $driverLocation");
//     passengerLocation = LatLng(sourceLocation.latitude,
//         sourceLocation.longitude);
//     print("passengerLocation: $passengerLocation");
//
//     _driverLocationSubscription = FirebaseFirestore.instance
//         .collection('driversLocations')
//         .doc(widget.driverUserId)
//         .snapshots()
//         .listen((snapshot) {
//       if (snapshot.exists) {
//         final locationData = snapshot.data()!['location'];
//         setState(() {
//           driverLocation =
//               LatLng(locationData.latitude, locationData.longitude);
//           _updateDriverMarker(
//               driverLocation!.latitude, driverLocation!.longitude);
//         });
//       }
//     });
//
//     _locationUpdateTimer = Timer.periodic(Duration(seconds: 20), (timer) {
//       _fetchDriverLocation();
//     });
//   }
//
//   Future<void> _fetchDriverLocation() async {
//     final snapshot = await FirebaseFirestore.instance
//         .collection('driversLocations')
//         .doc(widget.driverUserId)
//         .get();
//     if (snapshot.exists) {
//       LatLng locationData = snapshot.data()!['location'];
//       _updateDriverMarker(locationData.latitude, locationData.longitude);
//       print(
//           "Updating Driver Location to (${locationData.latitude}, ${locationData.longitude})");
//     }
//   }
//
//   @override
//   void dispose() {
//     super.dispose();
//     _driverLocationSubscription?.cancel();
//     _locationUpdateTimer?.cancel();
//   }
//
//   Future<void> _fetchLocation() async {
//     try {
//       final status = await Permission.location.request();
//       if (status.isGranted) {
//         Position position = await Geolocator.getCurrentPosition(
//           desiredAccuracy: LocationAccuracy.best,
//         );
//         setState(() {
//           _currentLocation = position;
//         });
//       } else {
//         print('Permission not granted');
//       }
//     } catch (e) {
//       print('Error fetching location: $e');
//     }
//   }
//
//   void _updateDriverMarker(double latitude, double longitude) {
//     LatLng newDriverPosition = LatLng(latitude, longitude);
//
//     if (_driverMarker != null) {
//       setState(() {
//         _driverMarker = _driverMarker!.copyWith(
//           positionParam: newDriverPosition,
//         );
//       });
//     } else {
//       setState(() {
//         _driverMarker = Marker(
//           markerId: MarkerId('driver'),
//           position: newDriverPosition,
//         );
//       });
//     }
//
//     _mapController?.animateCamera(
//       CameraUpdate.newLatLng(newDriverPosition),
//     );
//   }
//
//   Future<void> _createPolylines() async {
//     String googleAPIKey = mapKey; // Replace with your Google Maps API key
//
//     if (driverLocation == null || passengerLocation == null) {
//       print("Driver or passenger location is null");
//       return;
//     }
//
//     String urlDriverToPassenger =
//         'https://maps.googleapis.com/maps/api/directions/json?origin=${driverLocation!.latitude},${driverLocation!.longitude}&destination=${passengerLocation!.latitude},${passengerLocation!.longitude}&key=$googleAPIKey';
//     http.Response responseDriverToPassenger =
//         await http.get(Uri.parse(urlDriverToPassenger));
//     Map valuesDriverToPassenger = jsonDecode(responseDriverToPassenger.body);
//
//     String urlPassengerToDestination =
//         'https://maps.googleapis.com/maps/api/directions/json?origin=${passengerLocation!.latitude},${passengerLocation!.longitude}&destination=${destinationLocation.latitude},${destinationLocation.longitude}&key=$googleAPIKey';
//     http.Response responsePassengerToDestination =
//         await http.get(Uri.parse(urlPassengerToDestination));
//     Map valuesPassengerToDestination =
//         jsonDecode(responsePassengerToDestination.body);
//
//     if (valuesDriverToPassenger['routes'].isEmpty ||
//         valuesPassengerToDestination['routes'].isEmpty) {
//       print("No routes found");
//       return;
//     }
//
//     String polylinePointsDriverToPassenger =
//         valuesDriverToPassenger['routes'][0]['overview_polyline']['points'];
//     String polylinePointsPassengerToDestination =
//         valuesPassengerToDestination['routes'][0]['overview_polyline']
//             ['points'];
//     PolylinePoints polylinePoints = PolylinePoints();
//     List<PointLatLng> resultDriverToPassenger =
//         polylinePoints.decodePolyline(polylinePointsDriverToPassenger);
//     List<PointLatLng> resultPassengerToDestination =
//         polylinePoints.decodePolyline(polylinePointsPassengerToDestination);
//
//     List<LatLng> polylineCoordinatesDriverToPassenger = resultDriverToPassenger
//         .map((point) => LatLng(point.latitude, point.longitude))
//         .toList();
//     List<LatLng> polylineCoordinatesPassengerToDestination =
//         resultPassengerToDestination
//             .map((point) => LatLng(point.latitude, point.longitude))
//             .toList();
//
//     Polyline polylineDriverToPassenger = Polyline(
//       polylineId: PolylineId('driver_passenger'),
//       visible: true,
//       points: polylineCoordinatesDriverToPassenger,
//       color: Colors.blue,
//       width: 4,
//     );
//     Polyline polylinePassengerToDestination = Polyline(
//       polylineId: PolylineId('passenger_destination'),
//       visible: true,
//       points: polylineCoordinatesPassengerToDestination,
//       color: Colors.red,
//       width: 4,
//     );
//
//     setState(() {
//       _polylines.add(polylineDriverToPassenger);
//       _polylines.add(polylinePassengerToDestination);
//     });
//   }
//
//   Future<String> getDriverPhoneNumber() async {
//     final docSnapshot = await FirebaseFirestore.instance
//         .collection('users')
//         .doc(widget.driverUserId)
//         .get();
//     return docSnapshot.get('phoneNumber');
//   }
//
//   Future<String> getDriverEmail() async {
//     final docSnapshot = await FirebaseFirestore.instance
//         .collection('users')
//         .doc(widget.driverUserId)
//         .get();
//     return docSnapshot.get('email');
//   }
//
//   Future<String> getDriverImage() async {
//     final ref = FirebaseStorage.instance
//         .ref()
//         .child('user_images/${widget.driverUserId}');
//     return await ref.getDownloadURL();
//   }
//
//   Completer<GoogleMapController> _controller = Completer();
//   Set<Polyline> _polylines = {};
//
//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder(
//       future: Future.wait([getDriverPhoneNumber(), getDriverImage()]),
//       builder: (context, AsyncSnapshot<List<String>> snapshot) {
//         if (snapshot.hasData && snapshot.data != null) {
//           final driverPhone = snapshot.data![0];
//           final driverImage = snapshot.data![1];
//           return Stack(
//             children: [
//               Scaffold(
//                 appBar: PreferredSize(
//                   preferredSize: Size.fromHeight(50),
//                   child: Container(
//                     // extra container for custom bottom shadows
//                     decoration: BoxDecoration(
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black12.withOpacity(0.5),
//                           spreadRadius: 6,
//                           blurRadius: 6,
//                           offset: Offset(0, -4),
//                         ),
//                       ],
//                     ),
//                     child: AppBar(
//                       automaticallyImplyLeading:
//                           false, // This hides the back arrow
//                       backgroundColor: Color(0xFF66b899),
//                       title: Align(
//                         alignment: Alignment.topRight,
//                         child: TextButton(
//                           onPressed: () {
//                             globalMatchedRideIds
//                                 .passengerLocationUpdateSubscription
//                                 ?.cancel();
//                             Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                     builder: (context) => HomeScreen()));
//                           },
//                           child: Text(
//                             "Cancel",
//                             style: TextStyle(
//                               color: Colors.black,
//                               fontSize: 20,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//                 body: Stack(
//                   children: [
//                     if (_currentLocation != null)
//                       GoogleMap(
//                         initialCameraPosition: CameraPosition(
//                           target: LatLng(_currentLocation!.latitude,
//                               _currentLocation!.longitude),
//                           zoom: 14,
//                         ),
//                         markers: _driverMarker != null
//                             ? {_driverMarker!}
//                             : Set<Marker>(),
//                         polylines: _polylines,
//                         onMapCreated: (GoogleMapController controller) {
//                           _controller.complete(controller);
//                           _mapController = controller;
//                         },
//                       ),
//                     Align(
//                       alignment: Alignment.bottomCenter,
//                       child: DraggableScrollableSheet(
//                         initialChildSize: 0.3,
//                         minChildSize: 0.3,
//                         maxChildSize: 0.85,
//                         builder: (context, scrollController) {
//                           return Container(
//                             decoration: BoxDecoration(
//                               color: Color(0xff247758),
//                               borderRadius: BorderRadius.only(
//                                 topLeft: Radius.circular(20),
//                                 topRight: Radius.circular(20),
//                               ),
//                             ),
//                             child: SingleChildScrollView(
//                               controller: scrollController,
//                               child: Padding(
//                                 padding: const EdgeInsets.all(10.0),
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     ListTile(
//                                       leading: CircleAvatar(
//                                         backgroundImage:
//                                             NetworkImage(driverImage),
//                                       ),
//                                       title: Text(
//                                         widget.driverName,
//                                         style: TextStyle(
//                                             color: Colors.white,
//                                             fontWeight: FontWeight.bold),
//                                       ),
//                                       subtitle: Text(
//                                         '${widget.vehicleColor} ${widget.vehicleBrand} ${widget.vehicleModel}',
//                                         style: TextStyle(color: Colors.white70),
//                                       ),
//                                       trailing: Row(
//                                         mainAxisSize: MainAxisSize.min,
//                                         children: [
//                                           IconButton(
//                                             icon: Icon(Icons.phone,
//                                                 color: Colors.white),
//                                             onPressed: () async {
//                                               String phoneNumber =
//                                                   await getDriverPhoneNumber();
//                                               launch("tel://$phoneNumber");
//                                             },
//                                           ),
//                                           IconButton(
//                                             icon: Icon(Icons.mail,
//                                                 color: Colors.white),
//                                             onPressed: () {
//                                               Navigator.push(
//                                                 context,
//                                                 MaterialPageRoute(
//                                                   builder: (context) =>
//                                                       chatPage(
//                                                           displayName:
//                                                               widget.driverName,
//                                                           image: driverImage,
//                                                           receiverEmail:
//                                                               getDriverEmail()
//                                                                   .toString(),
//                                                           receiverID: widget
//                                                               .driverUserId),
//                                                 ),
//                                               );
//                                             },
//                                           ),
//                                           IconButton(
//                                             icon: Icon(Icons.share,
//                                                 color: Colors.white),
//                                             onPressed: () {
//                                               shareLiveLocation(
//                                                   _currentLocation!);
//                                             },
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                     ListTile(
//                                       title: Text(
//                                         'Safety Tools',
//                                         style: TextStyle(
//                                             color: Colors.white,
//                                             fontWeight: FontWeight.bold),
//                                       ),
//                                       trailing: IconButton(
//                                         icon: Icon(
//                                           _showSafetyTools
//                                               ? Icons.arrow_drop_up
//                                               : Icons.arrow_drop_down,
//                                           color: Colors.white,
//                                         ),
//                                         onPressed: () {
//                                           setState(() {
//                                             _showSafetyTools =
//                                                 !_showSafetyTools;
//                                           });
//                                         },
//                                       ),
//                                     ),
//                                     if (_showSafetyTools)
//                                       Column(
//                                         children: [
//                                           ListTile(
//                                             title: Text(
//                                               'Call Police',
//                                               style: TextStyle(
//                                                   color: Colors.white),
//                                             ),
//                                             trailing: Icon(
//                                               Icons.local_police,
//                                               color: Colors.white,
//                                             ),
//                                             onTap: () {
//                                               launch("tel://15");
//                                             },
//                                           ),
//                                           ListTile(
//                                               title: Text(
//                                                 'Call Ambulance',
//                                                 style: TextStyle(
//                                                     color: Colors.white),
//                                               ),
//                                               trailing: Icon(
//                                                 Icons.local_hospital,
//                                                 color: Colors.white,
//                                               ),
//                                               onTap: () {
//                                                 launch("tel://1122");
//                                               }),
//                                         ],
//                                       ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           );
//         } else {
//           return Center(child: CircularProgressIndicator());
//         }
//       },
//     );
//   }
//
//   void shareLiveLocation(Position currentLocation) {
//     double latitude = currentLocation.latitude;
//     double longitude = currentLocation.longitude;
//
//     String googleMapsUrl = 'https://www.google.com/maps?q=$latitude,$longitude';
//     Share.share(googleMapsUrl);
//
//     // launch(googleMapsUrl);
//   }
// }
//
// // import 'dart:async';
// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:flutter/material.dart';
// // import 'package:geolocator/geolocator.dart';
// // import 'package:google_maps_flutter/google_maps_flutter.dart';
// // import 'package:hitchify/global/map_key.dart';
// // import 'package:hitchify/passengerSideRide/match_rides.dart';
// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:firebase_storage/firebase_storage.dart';
// // import 'package:url_launcher/url_launcher.dart';
// // import 'dart:convert';
// // import 'package:flutter_polyline_points/flutter_polyline_points.dart';
// // import 'package:http/http.dart' as http;
// // import 'package:hitchify/passengerSideRide/Rides.dart';
// // import '../chat/chat_page.dart';
// // import '../home/home_screen.dart';
// // import 'package:permission_handler/permission_handler.dart';
// // import 'package:share_plus/share_plus.dart';
// // import 'package:hitchify/passengerSideRide/match_rides.dart';
// //
// // import 'GlobalMatchedRideIds.dart';
// //
// // class AcceptRide extends StatefulWidget {
// //   final int count;
// //   final String driverName;
// //   final String vehicleColor;
// //   final String vehicleBrand;
// //   final String vehicleModel;
// //   final String driverUserId;
// //
// //   AcceptRide({
// //     required this.count,
// //     required this.driverName,
// //     required this.vehicleColor,
// //     required this.vehicleBrand,
// //     required this.vehicleModel,
// //     required this.driverUserId,
// //   });
// //
// //   @override
// //   _AcceptRideState createState() => _AcceptRideState();
// // }
// //
// // class _AcceptRideState extends State<AcceptRide> {
// //   LatLng? driverLocation;
// //   LatLng? passengerLocation;
// //   String currentUserUid = FirebaseAuth.instance.currentUser!.uid ?? '';
// //
// //   bool _showSafetyTools = false;
// //   StreamSubscription<DocumentSnapshot>? _driverLocationSubscription;
// //   GoogleMapController? _mapController;
// //   Marker? _driverMarker;
// //
// //   Position? _currentLocation;
// //   Timer? _locationUpdateTimer;
// //   @override
// //   void initState() {
// //     super.initState();
// //     _fetchLocation();
// //     driverLocation = LatLng(
// //         passengerRideData.driverSourceLatitude[widget.count],
// //         passengerRideData.driverSourceLongitude[widget.count]);
// //     passengerLocation = LatLng(sourceLocation.latitude,
// //         sourceLocation.longitude);
// //     print("passengerLocation: $passengerLocation");
// //     _driverLocationSubscription = FirebaseFirestore.instance
// //         .collection('driversLocations')
// //         .doc(widget.driverUserId)
// //         .snapshots()
// //         .listen((snapshot) {
// //       if (snapshot.exists) {
// //         setState(() {
// //           driverLocation = snapshot.data()!['location'];
// //           _updateDriverMarker(
// //               driverLocation!.latitude, driverLocation!.longitude);
// //         });
// //       }
// //     });
// //     _locationUpdateTimer = Timer.periodic(Duration(seconds: 2), (timer) {
// //       print("Updating driver location111");
// //       _fetchDriverLocation();
// //     });
// //   }
// //
// //   Future<void> _fetchDriverLocation() async {
// //     final snapshot = await FirebaseFirestore.instance
// //         .collection('driversLocations')
// //         .doc(widget.driverUserId)
// //         .get();
// //     if (snapshot.exists) {
// //       var locationData = snapshot.data()!['location'];
// //       print("Location Data: $locationData");
// //       _updateDriverMarker(locationData.latitude, locationData.longitude);
// //       print("Updating Driver Location");
// //     } else {
// //       print("Driver location not found");
// //     }
// //   }
// //
// //   @override
// //   void dispose() {
// //     super.dispose();
// //     _driverLocationSubscription?.cancel();
// //     _locationUpdateTimer?.cancel();
// //   }
// //
// // //function to fetch ridestatus from firebase and update the UI
// //   void fetchRideStatus() {
// //     FirebaseFirestore.instance
// //         .collection('rides')
// //         .where('userId',
// //             isEqualTo: globalMatchedRideIds
// //                 .driverId) // Use the rideId to get the specific ride document
// //         .get()
// //         .then((querySnapshot) {
// //       if (querySnapshot.docs.isNotEmpty) {
// //         // If a document is found, update the status to 'in_progress'
// //         querySnapshot.docs.first.reference
// //             .collection('AcceptedRides')
// //             .where('driverId',
// //                 isEqualTo: globalMatchedRideIds.driverId) // Match the driverId
// //             .where('passengerId',
// //                 isEqualTo: currentUserUid) // Match the passengerId
// //             .get()
// //             .then((acceptedRidesSnapshot) {
// //           if (acceptedRidesSnapshot.docs.isNotEmpty) {
// //             acceptedRidesSnapshot.docs.forEach((doc) {
// //               if (doc['rideStatus'] == 'in_progress') {
// //                 // Update the UI
// //                 setState(() {
// //                   _showSafetyTools = true;
// //                 });
// //               }
// //             });
// //           }
// //         });
// //       }
// //     });
// //   }
// //
// //   Future<void> _fetchLocation() async {
// //     try {
// //       // LocationPermission permission = await Geolocator.requestPermission();
// //       final status = await Permission.location.request();
// //       if (status.isGranted) {
// //         Position position = await Geolocator.getCurrentPosition(
// //           desiredAccuracy: LocationAccuracy.best,
// //         );
// //         setState(() {
// //           _currentLocation = position;
// //         });
// //       } else {
// //         print('Permission not granted');
// //       }
// //     } catch (e) {
// //       print('Error fetching location: $e');
// //     }
// //   }
// //
// //   void _updateDriverMarker(double latitude, double longitude) {
// //     LatLng newDriverPosition = LatLng(latitude, longitude);
// //
// //     if (_driverMarker != null) {
// //       // Update the marker position if it already exists
// //       setState(() {
// //         _driverMarker = _driverMarker!.copyWith(
// //           positionParam: newDriverPosition,
// //         );
// //       });
// //     } else {
// //       // Create a new marker if it doesn't exist
// //       setState(() {
// //         _driverMarker = Marker(
// //           markerId: MarkerId('driver'),
// //           position: newDriverPosition,
// //         );
// //       });
// //     }
// //
// //     // Move the camera to the new driver position
// //     _mapController?.animateCamera(
// //       CameraUpdate.newLatLng(newDriverPosition),
// //     );
// //   }
// //
// //   Future<String> getDriverPhoneNumber() async {
// //     final docSnapshot = await FirebaseFirestore.instance
// //         .collection('users')
// //         .doc(widget.driverUserId)
// //         .get();
// //     return docSnapshot.get('phoneNumber');
// //   }
// //
// //   Future<String> getDriverEmail() async {
// //     final docSnapshot = await FirebaseFirestore.instance
// //         .collection('users')
// //         .doc(widget.driverUserId)
// //         .get();
// //     return docSnapshot.get('email');
// //   }
// //
// //   Future<String> getDriverImage() async {
// //     final ref = FirebaseStorage.instance
// //         .ref()
// //         .child('user_images/${widget.driverUserId}');
// //     return await ref.getDownloadURL();
// //   }
// //
// //   // Add a Completer for GoogleMapController
// //   Completer<GoogleMapController> _controller = Completer();
// //
// //   // Add a Set for polylines
// //   Set<Polyline> _polylines = {};
// //
// //   // Add a method to create polylines
// //
// //   Future<void> _createPolylines() async {
// //     String googleAPIKey = mapKey; // Replace with your Google Maps API key
// //
// //     // Get the directions from driver to passenger
// //     String urlDriverToPassenger =
// //         'https://maps.googleapis.com/maps/api/directions/json?origin=${driverLocation!.latitude},${driverLocation!.longitude}&destination=${passengerLocation!.latitude},${passengerLocation!.longitude}&key=$googleAPIKey';
// //     http.Response responseDriverToPassenger =
// //         await http.get(Uri.parse(urlDriverToPassenger));
// //     Map valuesDriverToPassenger = jsonDecode(responseDriverToPassenger.body);
// //
// //     // Get the directions from passenger to destination
// //     String urlPassengerToDestination =
// //         'https://maps.googleapis.com/maps/api/directions/json?origin=${passengerLocation!.latitude},${passengerLocation!.longitude}&destination=${destinationLocation.latitude},${destinationLocation.longitude}&key=$googleAPIKey';
// //     http.Response responsePassengerToDestination =
// //         await http.get(Uri.parse(urlPassengerToDestination));
// //     Map valuesPassengerToDestination =
// //         jsonDecode(responsePassengerToDestination.body);
// //
// //     // Get the polyline points
// //     String polylinePointsDriverToPassenger =
// //         valuesDriverToPassenger['routes'][0]['overview_polyline']['points'];
// //     String polylinePointsPassengerToDestination =
// //         valuesPassengerToDestination['routes'][0]['overview_polyline']
// //             ['points'];
// //     PolylinePoints polylinePoints = PolylinePoints();
// //     List<PointLatLng> resultDriverToPassenger =
// //         polylinePoints.decodePolyline(polylinePointsDriverToPassenger);
// //     List<PointLatLng> resultPassengerToDestination =
// //         polylinePoints.decodePolyline(polylinePointsPassengerToDestination);
// //
// //     // Convert the points to LatLng
// //     List<LatLng> polylineCoordinatesDriverToPassenger = resultDriverToPassenger
// //         .map((point) => LatLng(point.latitude, point.longitude))
// //         .toList();
// //     List<LatLng> polylineCoordinatesPassengerToDestination =
// //         resultPassengerToDestination
// //             .map((point) => LatLng(point.latitude, point.longitude))
// //             .toList();
// //
// //     // Create the polylines
// //     Polyline polylineDriverToPassenger = Polyline(
// //       polylineId: PolylineId('driver_passenger'),
// //       visible: true,
// //       points: polylineCoordinatesDriverToPassenger,
// //       color: Colors.blue,
// //       width: 4,
// //     );
// //     Polyline polylinePassengerToDestination = Polyline(
// //       polylineId: PolylineId('passenger_destination'),
// //       visible: true,
// //       points: polylineCoordinatesPassengerToDestination,
// //       color: Colors.red,
// //       width: 4,
// //     );
// //
// //     // Add the polylines to the set
// //     setState(() {
// //       _polylines.add(polylineDriverToPassenger);
// //       _polylines.add(polylinePassengerToDestination);
// //     });
// //   }
// //
// //   void _updateDriverLocation(LatLng newLocation) {
// //     setState(() {
// //       driverLocation = newLocation;
// //     });
// //     _createPolylines();
// //     Future.delayed(Duration(seconds: 5), () {
// //       _updateDriverLocation(LatLng(
// //           passengerRideData.driverSourceLatitude[widget.count],
// //           passengerRideData.driverSourceLongitude[widget.count]));
// //     });
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return FutureBuilder(
// //       future: Future.wait([getDriverPhoneNumber(), getDriverImage()]),
// //       builder: (context, AsyncSnapshot<List<String>> snapshot) {
// //         if (snapshot.hasData && snapshot.data != null) {
// //           final driverPhone = snapshot.data![0];
// //           final driverImage = snapshot.data![1];
// //           // Add GoogleMap widget to the Stack
// //           return Stack(
// //             children: [
// //               Scaffold(
// //                 appBar: PreferredSize(
// //                   preferredSize: Size.fromHeight(50),
// //                   child: Container(
// //                     // extra container for custom bottom shadows
// //                     decoration: BoxDecoration(
// //                       boxShadow: [
// //                         BoxShadow(
// //                           color: Colors.black12.withOpacity(0.5),
// //                           spreadRadius: 6,
// //                           blurRadius: 6,
// //                           offset: Offset(0, -4),
// //                         ),
// //                       ],
// //                     ),
// //                     child: AppBar(
// //                       backgroundColor: Color(0xFF66b899),
// //                       title: Align(
// //                         alignment: Alignment.topRight,
// //                         child: TextButton(
// //                           onPressed: () {
// //                             globalMatchedRideIds
// //                                 .passengerLocationUpdateSubscription
// //                                 ?.cancel();
// //                             Navigator.push(
// //                                 context,
// //                                 MaterialPageRoute(
// //                                     builder: (context) => HomeScreen()));
// //                           },
// //                           child: Text(
// //                             "Cancel",
// //                             style: TextStyle(
// //                               color: Colors.black,
// //                               fontSize: 20,
// //                             ),
// //                           ),
// //                         ),
// //                       ),
// //                     ),
// //                   ),
// //                 ),
// //                 body: Stack(
// //                   children: [
// //                     // Google map
// //                     GoogleMap(
// //                       initialCameraPosition: CameraPosition(
// //                         target: driverLocation!,
// //                         zoom: 15,
// //                       ),
// //                       onMapCreated: (GoogleMapController controller) {
// //                         _controller.complete(controller);
// //                         _createPolylines();
// //                       },
// //                       polylines: _polylines,
// //                       markers: {
// //                         Marker(
// //                           markerId: MarkerId('driver'),
// //                           position: driverLocation!,
// //                           icon: BitmapDescriptor.defaultMarkerWithHue(
// //                               BitmapDescriptor.hueGreen),
// //                         ),
// //                         Marker(
// //                           markerId: MarkerId('passenger'),
// //                           position: passengerLocation!,
// //                           icon: BitmapDescriptor.defaultMarkerWithHue(
// //                               BitmapDescriptor.hueRed),
// //                         ),
// //                         Marker(
// //                           markerId: MarkerId('destination'),
// //                           position: LatLng(
// //                               destinationLocation.latitude,
// //                               destinationLocation.longitude),
// //                           icon: BitmapDescriptor.defaultMarkerWithHue(
// //                               BitmapDescriptor.hueGreen),
// //                         ),
// //                       },
// //                     ),
// //
// //                     Positioned(
// //                       left: 10.0,
// //                       right: 10.0,
// //                       top: 16.0,
// //                       child: Card(
// //                         elevation: 4, // Add a bottom box shadow to the card
// //                         shape: RoundedRectangleBorder(
// //                           borderRadius: BorderRadius.circular(8.0),
// //                         ),
// //                         child: Padding(
// //                           padding: const EdgeInsets.all(8.0),
// //                           child: Text(
// //                             'Your driver is on the way\n5 minutes away',
// //                             textAlign: TextAlign.center,
// //                             style: TextStyle(
// //                               fontWeight: FontWeight.bold,
// //                               fontSize: 16.0,
// //                               color: Color(0xFF66b899),
// //                             ),
// //                           ),
// //                         ),
// //                       ),
// //                     ),
// //                     // Fixed bottom sheet
// //                     Positioned(
// //                       left: 0,
// //                       right: 0,
// //                       bottom: 0,
// //                       child: Container(
// //                         padding: EdgeInsets.all(16.0),
// //                         decoration: BoxDecoration(
// //                           color: Colors.white,
// //                           borderRadius: BorderRadius.only(
// //                             topLeft: Radius.circular(20.0),
// //                             topRight: Radius.circular(20.0),
// //                           ),
// //                           boxShadow: [
// //                             BoxShadow(
// //                               color: Colors.black12.withOpacity(
// //                                   0.2), // Adjust shadow color and opacity
// //                               spreadRadius: 1,
// //                               blurRadius: 2,
// //                               offset:
// //                                   Offset(-2, -2), // changes position of shadow
// //                             ),
// //                           ],
// //                         ),
// //                         child: Column(
// //                             crossAxisAlignment: CrossAxisAlignment.center,
// //                             children: [
// //                               // Ride information
// //                               Row(
// //                                 mainAxisAlignment: MainAxisAlignment.center,
// //                                 children: [
// //                                   Text(
// //                                     widget.vehicleColor +
// //                                         ' ' +
// //                                         widget.vehicleBrand +
// //                                         ' ' +
// //                                         widget.vehicleModel,
// //                                     style: TextStyle(
// //                                       fontWeight: FontWeight.bold,
// //                                       fontSize: 18.0,
// //                                     ),
// //                                   ),
// //                                   SizedBox(
// //                                     width: 20,
// //                                   ),
// //                                   if (_showSafetyTools)
// //                                     IconButton(
// //                                       icon: Icon(
// //                                         Icons.security,
// //                                         size: 36,
// //                                         color: Colors.green,
// //                                       ),
// //                                       onPressed: () {
// //                                         showDialog(
// //                                           context: context,
// //                                           builder: (BuildContext context) {
// //                                             return AlertDialog(
// //                                               title: Text(
// //                                                 'Safety Tools',
// //                                                 textAlign: TextAlign.center,
// //                                                 style: TextStyle(
// //                                                     color: Colors.black),
// //                                               ),
// //                                               content: Column(
// //                                                 mainAxisSize: MainAxisSize.min,
// //                                                 children: [
// //                                                   buildOption(
// //                                                     context,
// //                                                     'Share Location',
// //                                                     Icons.location_on,
// //                                                     () {
// //                                                       // Call function to share live location through dynamic links
// //                                                       shareLiveLocation(
// //                                                           _currentLocation!);
// //                                                       Navigator.pop(context);
// //                                                     },
// //                                                   ),
// //                                                   buildOption(
// //                                                     context,
// //                                                     'Call Police',
// //                                                     Icons.local_police,
// //                                                     () {
// //                                                       // Call function to call the police
// //                                                       callPolice();
// //                                                       Navigator.pop(context);
// //                                                     },
// //                                                   ),
// //                                                   buildOption(
// //                                                     context,
// //                                                     'Call Ambulance',
// //                                                     Icons.local_hospital,
// //                                                     () {
// //                                                       // Call function to call an ambulance
// //                                                       callAmbulance();
// //                                                       Navigator.pop(context);
// //                                                     },
// //                                                   ),
// //                                                 ],
// //                                               ),
// //                                             );
// //                                           },
// //                                         );
// //                                       },
// //                                     ),
// //                                 ],
// //                               ),
// //                               Divider(
// //                                 color: Colors.black12,
// //                               ),
// //                               SizedBox(
// //                                 height: 30.0,
// //                               ),
// //
// //                               // Driver information
// //                               Row(
// //                                 mainAxisAlignment:
// //                                     MainAxisAlignment.spaceBetween,
// //                                 children: [
// //                                   // Driver image
// //                                   CircleAvatar(
// //                                     backgroundImage: NetworkImage(driverImage),
// //                                     radius: 25.0,
// //                                   ),
// //                                   SizedBox(
// //                                     width: 10.0,
// //                                   ),
// //                                   // Driver name
// //                                   Text(
// //                                     widget.driverName,
// //                                     style: TextStyle(
// //                                       fontWeight: FontWeight.bold,
// //                                       fontSize: 16.0,
// //                                     ),
// //                                   ),
// //                                   // Spacer
// //                                   Spacer(),
// //                                   // Chat icon
// //                                   Container(
// //                                     decoration: BoxDecoration(
// //                                       color: Color(0xFF66b899),
// //                                       borderRadius: BorderRadius.circular(30.0),
// //                                     ),
// //                                     child: IconButton(
// //                                       icon: Icon(Icons.chat),
// //                                       color: Colors.white,
// //                                       onPressed: () {
// //                                         Navigator.push(
// //                                           context,
// //                                           MaterialPageRoute(
// //                                             builder: (context) => chatPage(
// //                                                 displayName: widget.driverName,
// //                                                 image: driverImage,
// //                                                 receiverEmail:
// //                                                     getDriverEmail().toString(),
// //                                                 receiverID:
// //                                                     widget.driverUserId),
// //                                           ),
// //                                         );
// //                                       },
// //                                     ),
// //                                   ),
// //                                   SizedBox(width: 10.0),
// //                                   // Call icon
// //                                   Container(
// //                                     decoration: BoxDecoration(
// //                                       color: Color(0xFF66b899),
// //                                       borderRadius: BorderRadius.circular(30.0),
// //                                     ),
// //                                     child: IconButton(
// //                                       icon: Icon(Icons.call),
// //                                       color: Colors.white,
// //                                       onPressed: () {
// //                                         launch('tel:$driverPhone');
// //                                       },
// //                                     ),
// //                                   ),
// //                                 ],
// //                               )
// //                             ]),
// //                         // child: Column(
// //                         //     crossAxisAlignment: CrossAxisAlignment.center,
// //                         //     children: [
// //                         //       // Ride information
// //                         //       Text(
// //                         //         widget.vehicleColor +
// //                         //             ' ' +
// //                         //             widget.vehicleBrand +
// //                         //             ' ' +
// //                         //             widget.vehicleModel,
// //                         //         style: TextStyle(
// //                         //           fontWeight: FontWeight.bold,
// //                         //           fontSize: 18.0,
// //                         //         ),
// //                         //       ),
// //                         //       Divider(
// //                         //         color: Colors.black12,
// //                         //       ),
// //                         //       SizedBox(
// //                         //         height: 30.0,
// //                         //       ),
// //                         //
// //                         //       // Driver information
// //                         //       Row(
// //                         //         mainAxisAlignment:
// //                         //             MainAxisAlignment.spaceBetween,
// //                         //         children: [
// //                         //           // Driver image
// //                         //           CircleAvatar(
// //                         //             backgroundImage: NetworkImage(driverImage),
// //                         //             radius: 25.0,
// //                         //           ),
// //                         //           SizedBox(
// //                         //             width: 10.0,
// //                         //           ),
// //                         //           // Driver name
// //                         //           Text(
// //                         //             widget.driverName,
// //                         //             style: TextStyle(
// //                         //               fontWeight: FontWeight.bold,
// //                         //               fontSize: 16.0,
// //                         //             ),
// //                         //           ),
// //                         //           // Spacer
// //                         //           Spacer(),
// //                         //           // Chat icon
// //                         //           Container(
// //                         //             decoration: BoxDecoration(
// //                         //               color: Color(0xFF66b899),
// //                         //               borderRadius: BorderRadius.circular(30.0),
// //                         //             ),
// //                         //             child: IconButton(
// //                         //               icon: Icon(Icons.chat),
// //                         //               color: Colors.white,
// //                         //               onPressed: () {
// //                         //                 Navigator.push(
// //                         //                   context,
// //                         //                   MaterialPageRoute(
// //                         //                     builder: (context) => chatPage(
// //                         //                         displayName: widget.driverName,
// //                         //                         image: driverImage,
// //                         //                         receiverEmail:
// //                         //                             getDriverEmail().toString(),
// //                         //                         receiverID:
// //                         //                             widget.driverUserId),
// //                         //                   ),
// //                         //                 );
// //                         //               },
// //                         //             ),
// //                         //           ),
// //                         //           SizedBox(width: 10.0),
// //                         //           // Call icon
// //                         //           Container(
// //                         //             decoration: BoxDecoration(
// //                         //               color: Color(0xFF66b899),
// //                         //               borderRadius: BorderRadius.circular(30.0),
// //                         //             ),
// //                         //             child: IconButton(
// //                         //               icon: Icon(Icons.call),
// //                         //               color: Colors.white,
// //                         //               onPressed: () {
// //                         //                 launch('tel:$driverPhone');
// //                         //               },
// //                         //             ),
// //                         //           ),
// //                         //         ],
// //                         //       )
// //                         //     ]),
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             ],
// //           );
// //         } else {
// //           return Scaffold(
// //             body: Center(
// //               child: CircularProgressIndicator(),
// //             ),
// //           );
// //         }
// //       },
// //     );
// //   }
// //
// //   Widget buildOption(
// //     BuildContext context,
// //     String title,
// //     IconData icon,
// //     VoidCallback onPressed,
// //   ) {
// //     return ListTile(
// //       leading: Icon(
// //         icon,
// //         color: Colors.green,
// //       ),
// //       title: Text(
// //         title,
// //         style: TextStyle(
// //           color: Colors.black,
// //           // fontWeight: FontWeight.bold,
// //         ),
// //       ),
// //       onTap: onPressed,
// //     );
// //   }
// //
// //   void shareLiveLocation(Position currentLocation) {
// //     double latitude = currentLocation.latitude;
// //     double longitude = currentLocation.longitude;
// //
// //     String googleMapsUrl = 'https://www.google.com/maps?q=$latitude,$longitude';
// //     Share.share(googleMapsUrl);
// //
// //     // launch(googleMapsUrl);
// //   }
// //
// //   void callPolice() {
// //     final phoneNumber = '911';
// //     launch('tel:$phoneNumber');
// //   }
// //
// //   void callAmbulance() {
// //     final phoneNumber = '1122';
// //     launch('tel:$phoneNumber');
// //   }
// // }
