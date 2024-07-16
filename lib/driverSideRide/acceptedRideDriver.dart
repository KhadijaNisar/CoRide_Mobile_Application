import 'dart:async';
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geodesy/geodesy.dart' as geodesy;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../chat/chat_page.dart';
import '../global/map_key.dart';
import '../home/driver_home.dart';
import '../passengerSideRide/match_rides.dart';

class AcceptedRideDriver extends StatefulWidget {
  final String passengerName;
  final String passengerImage;
  final String passengerUserId;

  AcceptedRideDriver({
    required this.passengerName,
    required this.passengerImage,
    required this.passengerUserId,
  });

  @override
  _AcceptedRideDriverState createState() => _AcceptedRideDriverState();
}

class _AcceptedRideDriverState extends State<AcceptedRideDriver> {
  bool _showStartRideButton = false;
  bool _showEndRideButton = false;
  bool _showRideInProgress = false;
  String statusMessage = 'Your passenger is 5 minutes away';
  LatLng driverLocation = LatLng(0, 0);
  LatLng passengerLocation = LatLng(31.400936871025376, 73.20301827950213);
  LatLng destinationLocation = LatLng(0, 0);
  StreamSubscription<Position>? _driverLocationSubscription;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  late LatLng targetLocation = LatLng(0, 0);

  String currentUserUid = '';

  Timer? _updateTimer;
  GoogleMapController? _mapController;

  String passengerPhone = '';

  String passengerImage = '';

  Future<void> fetchCurrentLocation() async {
    try {
      LatLng currentLocation = await getCurrentLocation();
      setState(() {
        targetLocation = currentLocation;
      });
    } catch (e) {
      print('Error getting current location: $e');
      // Handle error
    }
  }

  Future<LatLng> getCurrentLocation() async {
    // Check permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, handle accordingly.
        throw 'Location permissions are denied';
      }
    }

    // Get current position
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    // Return LatLng object
    return LatLng(position.latitude, position.longitude);
  }

  @override
  void initState() {
    super.initState();
    fetchCurrentLocation();

    _getCurrentDriverLocation();
    _getPassengerLocationAndDestination();
    showRideStartButton();
    showRideEndButton();
    currentUserUid = FirebaseAuth.instance.currentUser!.uid;

    // Start updating driver location and polylines every 20 seconds
    _updateTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      showRideStartButton();
      showRideEndButton();
      _getCurrentDriverLocation();
      _getPassengerLocationAndDestination();
    });
    // Call createPolylines after setting initial locations
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      _createPolylines();
    });
  }

  @override
  void dispose() {
    _driverLocationSubscription?.cancel();
    _updateTimer?.cancel();
    super.dispose();
  }

  void _getCurrentDriverLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        driverLocation = LatLng(position.latitude, position.longitude);
      });
      _updateMarkersAndPolylines();
    } catch (e) {
      print('Error getting driver location: $e');
    }
  }

  Future<void> _getPassengerLocationAndDestination() async {
    try {
      DocumentSnapshot passengerDoc = await FirebaseFirestore.instance
          .collection('PassengersLocations')
          .doc(widget.passengerUserId)
          .get();

      if (passengerDoc.exists) {
        GeoPoint passengerGeoPoint = passengerDoc.get('location');
        setState(() {
          passengerLocation =
              LatLng(passengerGeoPoint.latitude, passengerGeoPoint.longitude);
        });
      }

      QuerySnapshot rideQuery = await FirebaseFirestore.instance
          .collection('passengerride')
          .where('userId', isEqualTo: widget.passengerUserId)
          .get();

      if (rideQuery.docs.isNotEmpty) {
        var documentSnapshot = rideQuery.docs.first;
        setState(() {
          destinationLocation = LatLng(
            documentSnapshot.get('destinationLatitude'),
            documentSnapshot.get('destinationLongitude'),
          );
        });
      }

      _updateMarkersAndPolylines();
    } catch (e) {
      print('Error getting passenger location and destination: $e');
    }
  }

  Future<void> _createPolylines() async {
    print('Creating polylines...');

    String googleAPIKey = mapKey;

    String urlDriverToPassenger =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${driverLocation.latitude},${driverLocation.longitude}&destination=${passengerLocation.latitude},${passengerLocation.longitude}&key=$googleAPIKey';
    String urlPassengerToDestination =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${passengerLocation.latitude},${passengerLocation.longitude}&destination=${destinationLocation.latitude},${destinationLocation.longitude}&key=$googleAPIKey';

    try {
      http.Response responseDriverToPassenger =
      await http.get(Uri.parse(urlDriverToPassenger));
      http.Response responsePassengerToDestination =
      await http.get(Uri.parse(urlPassengerToDestination));

      if (responseDriverToPassenger.statusCode == 200 &&
          responsePassengerToDestination.statusCode == 200) {
        var dataDriverToPassenger = json.decode(responseDriverToPassenger.body);
        var dataPassengerToDestination =
        json.decode(responsePassengerToDestination.body);

        List<LatLng> polylineCoordinatesDriverToPassenger = _decodePoly(
            dataDriverToPassenger['routes'][0]['overview_polyline']['points']);
        List<LatLng> polylineCoordinatesPassengerToDestination = _decodePoly(
            dataPassengerToDestination['routes'][0]['overview_polyline']
            ['points']);

        setState(() {
          _polylines.clear();
          _polylines.add(Polyline(
            polylineId: PolylineId('driver_to_passenger'),
            points: polylineCoordinatesDriverToPassenger,
            color: Colors.blue,
            width: 5,
          ));

          _polylines.add(Polyline(
            polylineId: PolylineId('passenger_to_destination'),
            points: polylineCoordinatesPassengerToDestination,
            color: Colors.green,
            width: 5,
          ));
        });
      }
    } catch (e) {
      print('Error creating polylines: $e');
    }
  }

  List<LatLng> _decodePoly(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  void _updateMarkersAndPolylines() {
    _updateMarkers();
    _createPolylines();
  }

  void _updateMarkers() {
    setState(() {
      _markers.clear();
      _markers.add(Marker(
        markerId: MarkerId('driver'),
        position: driverLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ));
      _markers.add(Marker(
        markerId: MarkerId('passenger'),
        position: passengerLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
      _markers.add(Marker(
        markerId: MarkerId('destination'),
        position: destinationLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ));
    });
  }

  void startRide() {
    FirebaseFirestore.instance
        .collection('rides')
        .where('userId', isEqualTo: currentUserUid)
        .get()
        .then((querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        querySnapshot.docs.first.reference
            .collection('AcceptedRides')
            .where('driverId', isEqualTo: currentUserUid)
            .get()
            .then((querySnapshot) {
          if (querySnapshot.docs.isNotEmpty) {
            querySnapshot.docs.first.reference
                .update({'rideStatus': 'started'}).then((value) {
              setState(() {
                statusMessage = 'Your passenger has been picked';
                _showStartRideButton = false;
              });
            });
          }
        });
      }
    });
  }



  void endRide() {
    FirebaseFirestore.instance
        .collection('rides')
        .where('userId', isEqualTo: currentUserUid)
        .get()
        .then((querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        querySnapshot.docs.first.reference
            .collection('AcceptedRides')
            .where('driverId', isEqualTo: currentUserUid)
            .get()
            .then((querySnapshot) {
          if (querySnapshot.docs.isNotEmpty) {
            querySnapshot.docs.first.reference
                .update({'rideStatus': 'Ride has ended'}).then((value) {
              setState(() {
                _showRideInProgress = false;
                _showStartRideButton = false;
                _showEndRideButton = false;
              });
            });
          }
        });
      }
    });
  }

  void removeDriverToPassengerPolyline() {
    _polylines.removeWhere((polyline) => polyline.polylineId.value == 'driver_to_passenger');
  }


  bool isDriverReached() {
    geodesy.Geodesy geodest = geodesy.Geodesy();
    num distance = geodest.distanceBetweenTwoGeoPoints(
        geodesy.LatLng(driverLocation.latitude, driverLocation.longitude),
        geodesy.LatLng(
            passengerLocation.latitude, passengerLocation.longitude));
    print("Dist btwn : $distance");
    if (distance < 500) {
      print("Reached passenger loc");
      removePassengerMarker();
      removeDriverToPassengerPolyline();
      return true;
    }
    return false;
  }


  bool isDestinationReached() {
    print("Reached dest");
    geodesy.Geodesy geodest = geodesy.Geodesy();
    num distance = geodest.distanceBetweenTwoGeoPoints(
        geodesy.LatLng(driverLocation.latitude, driverLocation.longitude),
        geodesy.LatLng(
            destinationLocation.latitude, destinationLocation.longitude));
     print("Distance: $distance");
    if (distance <= 100) {
      print("Reached dest");
      return true;
    }
    return false;
  }
  void showRideEndButton() {
    if(isDestinationReached()){
      setState(() {
        _showRideInProgress = false;
        _showEndRideButton = true;
      });
    }
  }

  void removePassengerMarker() {
    _markers.removeWhere((marker) => marker.markerId.value == 'passenger');
    setState(() {}); // Trigger a rebuild to reflect the marker removal on the map
  }

  void showRideStartButton() {
    FirebaseFirestore.instance
        .collection('rides')
        .where('userId', isEqualTo: currentUserUid)
        .get()
        .then((querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        querySnapshot.docs.first.reference
            .collection('AcceptedRides')
            .where('driverId', isEqualTo: currentUserUid)
            .get()
            .then((querySnapshot) {
          if (querySnapshot.docs.isNotEmpty) {
            querySnapshot.docs.first.reference.get().then((value) {
              setState(() {
                if (value.get('rideStatus') == 'accepted' && isDriverReached()) {
                  print("Reached the passengers location");
                  _showStartRideButton = true;
                  statusMessage = 'You are at passenger Location';
                }
                if (value.get('rideStatus') == 'started') {
                  _showStartRideButton = false;
                  _showRideInProgress = true;
                }
                if (value.get('rideStatus') == 'ended') {
                  _showEndRideButton = false;
                  _showStartRideButton = false;
                  _showRideInProgress = false;
                }
              });
            });
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
        future: getPassengerImage(),
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            passengerImage = snapshot.data ?? '';

            return Scaffold(
              appBar: PreferredSize(
                preferredSize: Size.fromHeight(50),
                child: Container(
                  // extra container for custom bottom shadows
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12.withOpacity(0.5),
                        spreadRadius: 6,
                        blurRadius: 6,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  child: AppBar(
                    automaticallyImplyLeading:
                    false, // This hides the back arrow
                    backgroundColor: Color(0xFF66b899),
                    title: Align(
                      alignment: Alignment.topRight,
                      child: TextButton(
                        onPressed: () {
                          globalMatchedRideIds.driverLocationUpdateSubscription
                              ?.cancel();
                          // cancelRide();
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => driverHome()));
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
                ),
              ),
              body: targetLocation != null
                  ? Stack(
                children: [
                  GoogleMap(
                    mapType: MapType.normal,
                    initialCameraPosition: CameraPosition(
                      target: targetLocation,
                      zoom: 12,
                    ),
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    markers: _markers,
                    polylines: _polylines,
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                    },
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20.0),
                          topRight: Radius.circular(20.0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12.withOpacity(0.2),
                            // Adjust shadow color and opacity
                            spreadRadius: 1,
                            blurRadius: 2,
                            offset: Offset(
                                -2, -2), // changes position of shadow
                          ),
                        ],
                      ),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (_showStartRideButton)
                              ElevatedButton(
                                style: ButtonStyle(
                                  backgroundColor:
                                  MaterialStateProperty.all<Color>(
                                      Color(0xff52c498)),
                                  foregroundColor:
                                  MaterialStateProperty.all<Color>(
                                      Colors.white),
                                  minimumSize:
                                  MaterialStateProperty.all<Size>(
                                    Size(200,
                                        40), // Change the width (and height) as needed
                                  ),
                                ),
                                onPressed: () {
                                  startRide();
                                },
                                child: Text('Start Ride'),
                              ),
                            if (_showEndRideButton)
                              ElevatedButton(
                                style: ButtonStyle(
                                  backgroundColor:
                                  MaterialStateProperty.all<Color>(
                                      Color(0xff52c498)),
                                  foregroundColor:
                                  MaterialStateProperty.all<Color>(
                                      Colors.white),
                                  minimumSize:
                                  MaterialStateProperty.all<Size>(
                                    Size(200,
                                        40), // Change the width (and height) as needed
                                  ),
                                ),
                                onPressed: () {
                                  endRide();
                                  showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: Text(
                                              'Choose the Payment Method'),
                                          content: Text(
                                              'Select one of the options below:'),
                                          actions: <Widget>[
                                            TextButton(
                                              child: Text('Cash'),
                                              onPressed: () {
                                                Navigator.of(context)
                                                    .pop();
                                                _showSpecificDialog(
                                                    context, 'Cash');
                                              },
                                            ),
                                            TextButton(
                                              child: Text('JazzCash'),
                                              onPressed: () {
                                                Navigator.of(context)
                                                    .pop();
                                                _showSpecificDialog(
                                                    context, 'JazzCash');
                                              },
                                            ),
                                            TextButton(
                                              child:
                                              Text('Bank Transfer'),
                                              onPressed: () {
                                                Navigator.of(context)
                                                    .pop();
                                                _showSpecificDialog(
                                                    context,
                                                    'Bank Transfer');
                                              },
                                            ),
                                          ],
                                        );
                                      });
                                },
                                child: Text('End Ride'),
                              ),
                            if (_showRideInProgress)
                              ElevatedButton(
                                style: ButtonStyle(
                                  backgroundColor:
                                  MaterialStateProperty.all<Color>(
                                      Color(0xff52c498)),
                                  foregroundColor:
                                  MaterialStateProperty.all<Color>(
                                      Colors.white),
                                  minimumSize:
                                  MaterialStateProperty.all<Size>(
                                    Size(200,
                                        40), // Change the width (and height) as needed
                                  ),
                                ),
                                onPressed: () {
                                  // Navigator.push(
                                  //   context,
                                  //   MaterialPageRoute(
                                  //     builder: (context) => RateRide(),
                                  //   ),
                                  // );
                                },
                                child: Text('Ongoing Ride'),
                              ),

                            // Ride information
                            Divider(
                              color: Colors.black12,
                            ),
                            SizedBox(
                              height: 30.0,
                            ),
                            // Passenger information
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                // Passenger image
                                CircleAvatar(
                                  backgroundImage:
                                  NetworkImage(passengerImage),
                                  radius: 25.0,
                                ),
                                SizedBox(
                                  width: 10.0,
                                ),
                                // Passenger name
                                Text(
                                  widget.passengerName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.0,
                                  ),
                                ),
                                // Spacer
                                Spacer(),
                                // Chat icon
                                Container(
                                  decoration: BoxDecoration(
                                    color: Color(0xFF66b899),
                                    borderRadius:
                                    BorderRadius.circular(30.0),
                                  ),
                                  child: IconButton(
                                    icon: Icon(Icons.chat),
                                    color: Colors.white,
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => chatPage(
                                              displayName:
                                              widget.passengerName,
                                              image: passengerImage,
                                              receiverEmail:
                                              getPassengerEmail()
                                                  .toString(),
                                              receiverID:
                                              widget.passengerUserId),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(width: 10.0),
                                // Call icon
                                Container(
                                  decoration: BoxDecoration(
                                    color: Color(0xFF66b899),
                                    borderRadius:
                                    BorderRadius.circular(30.0),
                                  ),
                                  child: IconButton(
                                    icon: Icon(Icons.call),
                                    color: Colors.white,
                                    onPressed: () async {
                                      String phoneNumber =
                                      await _getPassengerPhoneNumber();
                                      launch("tel://$phoneNumber");
                                    },
                                  ),
                                ),
                              ],
                            )
                          ]),
                    ),
                  ),
                  // _showStartRideButton
                  //     ? Positioned(
                  //   bottom: 100,
                  //   right: 10,
                  //   child: ElevatedButton(
                  //     onPressed: startRide,
                  //     child: Text('Start Ride'),
                  //   ),
                  // )
                  //     : SizedBox.shrink(),
                  // _showEndRideButton
                  //     ? Positioned(
                  //   bottom: 100,
                  //   right: 10,
                  //   child: ElevatedButton(
                  //     onPressed: endRide,
                  //     child: Text('End Ride'),
                  //   ),
                  // )
                  //     : SizedBox.shrink(),
                  // _showRideInProgress
                  //     ? Positioned(
                  //   bottom: 100,
                  //   right: 10,
                  //   child: ElevatedButton(
                  //     onPressed: () {},
                  //     child: Text('Ride In Progress'),
                  //     style: ElevatedButton.styleFrom(
                  //       foregroundColor: Colors.grey,
                  //       backgroundColor: Colors.white,
                  //     ),
                  //   ),
                  // )
                  //     : SizedBox.shrink(),
                ],
              )
                  : Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          return Scaffold(
            backgroundColor:
            Colors.white, // Set the scaffold background color to white
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.green), // Set the indicator color to green
              ),
            ),
          );
        });
  }

  Future<String> getPassengerImage() async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('user_images/${widget.passengerUserId}');
    return await ref.getDownloadURL();
  }

  void _showSpecificDialog(BuildContext context, String paymentMethod) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Ride Ended Successfully'),
          content: Text('Payment method: $paymentMethod'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<String> getPassengerEmail() async {
    final docSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.passengerUserId)
        .get();
    return docSnapshot.get('email');
  }

  Future<String> _getPassengerPhoneNumber() async {
    final docSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.passengerUserId)
        .get();
    return await docSnapshot.get('phoneNumber');
  }
}


