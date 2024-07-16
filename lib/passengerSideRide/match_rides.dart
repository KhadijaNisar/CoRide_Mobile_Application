import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geodesy/geodesy.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as loc;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as htmlParser;
import 'package:hitchify/global/map_key.dart';

import 'package:hitchify/fuelPriceCal.dart';

import 'GlobalMatchedRideIds.dart';

GlobalMatchedRideIds globalMatchedRideIds = GlobalMatchedRideIds();
FirebaseFirestore firestore = FirebaseFirestore.instance;

class PassengerRideData {
  late List<int> noOfPassengers = [];
  late List<double> rideDistanceInKm = [];
  late List<double> driverSourceLatitude = [];
  late List<double> driverSourceLongitude = [];
  late double passengerFare = 0.0;
  late double rideSourceLatitude = 0.0;
  late double rideSourceLongitude = 0.0;
  late double rideDestinationLatitude = 0.0;
  late double rideDestinationLongitude = 0.0;
  late List<double> passengerFares = [];
  late String passengerSource = '';
  late String passengerDestination = '';
}

// Use the singleton instance like this
PassengerRideData passengerRideData = PassengerRideData();

class RideDataProvider {
  final double passengerSourceLatitude;
  final double passengerSourceLongitude;
  final double passengerDestinationLatitude;
  final double passengerDestinationLongitude;
  final DateTime? dateTime;
  final String? vehicleType;
  List<String> rduid;
  List<String> rideimages;
  List<String> rideVehicleType;

  RideDataProvider(
      {required this.passengerSourceLatitude,
      required this.passengerSourceLongitude,
      this.dateTime,
      required this.vehicleType,
      required this.passengerDestinationLatitude,
      required this.passengerDestinationLongitude})
      : rduid = [],
        rideimages = [],
        rideVehicleType = [];

  Future<loc.BitmapDescriptor> _createCustomMarkerIcon(Color color) async {
    final iconSize = 100; // You can adjust the size of the marker icon
    final PictureRecorder pictureRecorder = PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = color;
    final Radius radius = Radius.circular(iconSize / 2);

    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(0.0, 0.0, iconSize.toDouble(), iconSize.toDouble()),
        topLeft: radius,
        topRight: radius,
        bottomLeft: radius,
        bottomRight: radius,
      ),
      paint,
    );

    final img =
        await pictureRecorder.endRecording().toImage(iconSize, iconSize);
    final data = await img.toByteData(format: ImageByteFormat.png);

    return loc.BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  Future<List<loc.LatLng>> fetchDriverRouteMainPoints(
      double sourceLatitude,
      double sourceLongitude,
      double destinationLatitude,
      double destinationLongitude) async {
    final apiKey = mapKey;
    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$sourceLatitude,$sourceLongitude&destination=$destinationLatitude,$destinationLongitude&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    final data = jsonDecode(response.body);

    if (data['status'] == 'OK') {
      final overviewPolyline = data['routes'][0]['overview_polyline']['points'];
      return _decodePolyline(overviewPolyline);
    }

    return [];
  }

  List<loc.LatLng> _decodePolyline(String polyline) {
    List<loc.LatLng> points = [];
    int index = 0, len = polyline.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(loc.LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  bool isWithinDistance(loc.LatLng checkPoint, List<loc.LatLng> routePoints,
      double distanceMeters) {
    for (loc.LatLng point in routePoints) {
      final distance = Geolocator.distanceBetween(
        point.latitude,
        point.longitude,
        checkPoint.latitude,
        checkPoint.longitude,
      );
      if (distance <= distanceMeters) {
        return true;
      }
    }
    return false;
  }

  Future<List<loc.Marker>> fetchRidesWithin3km({
    required double passengerSourceLatitude,
    required double passengerSourceLongitude,
    required double passengerDestinationLatitude,
    required double passengerDestinationLongitude,
    required DateTime? dateTime,
    required String? vehicleType,
  }) async {
    passengerRideData.rideSourceLatitude = passengerSourceLatitude;
    passengerRideData.rideSourceLongitude = passengerSourceLongitude;
    passengerRideData.rideDestinationLatitude = passengerDestinationLatitude;
    passengerRideData.rideDestinationLongitude = passengerDestinationLongitude;

    FirebaseFirestore firestore = FirebaseFirestore.instance;
    List<loc.Marker> markers = [];

    QuerySnapshot ridesQuery = await firestore.collection('rides').get();
    print("Rides fetched: ${ridesQuery.docs.length}");

    for (QueryDocumentSnapshot rideSnapshot in ridesQuery.docs) {
      double driverSourceLatitude = rideSnapshot['sourceLatitude'];
      double driverSourceLongitude = rideSnapshot['sourceLongitude'];
      double driverDestinationLatitude = rideSnapshot['destinationLatitude'];
      double driverDestinationLongitude = rideSnapshot['destinationLongitude'];
      DateTime? rideDateTime = DateTime.tryParse(rideSnapshot['time']);
      String rideUserId = rideSnapshot['userId'];
      String rideId = rideSnapshot['rideId'];

      num distanceInMeters = Geodesy().distanceBetweenTwoGeoPoints(
        LatLng(passengerSourceLatitude, passengerSourceLongitude),
        LatLng(driverSourceLatitude, driverSourceLongitude),
      );

      double distanceInKm = distanceInMeters / 1000;
      print("Distance in KM: $distanceInKm");

      bool isWithin3km = distanceInKm <= 3;
      bool isCorrectDateTime = dateTime == null ||
          (rideDateTime != null && dateTime.isAtSameMomentAs(rideDateTime));

      List<String> rideVehicleTypes = [];

      // Fetch vehicle type for the ride
      try {
        QuerySnapshot userQuery = await firestore
            .collection('vehicle_data')
            .where('userId', whereIn: [rideUserId])
            .get();

        for (QueryDocumentSnapshot userSnapshot in userQuery.docs) {
          String driverVehicleType = userSnapshot['vehicleType'];
          print("DriverVehicleType: $driverVehicleType");

          if (driverVehicleType == vehicleType) {
            rideVehicleTypes.add(driverVehicleType);
            print('RideVehicles: ${rideVehicleTypes}');
          } else {
            print('Vehicle Type does not match');
          }
        }
      } catch (e) {
        print('Error fetching vehicle data: $e');
        continue; // Skip to the next ride if there's an error
      }

      bool isCorrectVehicleType = rideVehicleTypes.contains(vehicleType);
      print("isCorrectVehicleType: $isCorrectVehicleType");

      List<loc.LatLng> driverRouteMainPoints = await fetchDriverRouteMainPoints(
        driverSourceLatitude,
        driverSourceLongitude,
        driverDestinationLatitude,
        driverDestinationLongitude,
      );
      print("Driver route points: ${driverRouteMainPoints}");
      bool isPassengerDestinationWithinRoute = isWithinDistance(
        loc.LatLng(passengerDestinationLatitude, passengerDestinationLongitude),
        driverRouteMainPoints,
        700,
      );
      print(
          "isPassengerDestinationWithinRoute: ${isPassengerDestinationWithinRoute}");

      if (isWithin3km && isCorrectVehicleType || isPassengerDestinationWithinRoute) {
        if (!globalMatchedRideIds.matchedRideIds.contains(rideId)) {
          globalMatchedRideIds.matchedRideIds.add(rideId);
          globalMatchedRideIds.rideIndex =
              globalMatchedRideIds.matchedRideIds.indexOf(rideId);

          globalMatchedRideIds.matchedUserIds.add(rideUserId);
        }

        print("GlobalMatchedRideID: ${globalMatchedRideIds.matchedRideIds}");
        print("GlobalMatchedUserID: ${globalMatchedRideIds.matchedUserIds}");
      }

      if (isWithin3km &&
          isCorrectVehicleType &&
          isPassengerDestinationWithinRoute &&
          isCorrectDateTime) {
        loc.BitmapDescriptor markerIcon =
        await _createCustomMarkerIcon(Colors.blue);
        loc.Marker marker = loc.Marker(
          markerId: loc.MarkerId(rideSnapshot.id),
          position: loc.LatLng(driverSourceLatitude, driverSourceLongitude),
          infoWindow: loc.InfoWindow(
            title: rideSnapshot['source'],
            snippet: 'Distance: $distanceInKm km',
          ),
          icon: markerIcon,
        );
        markers.add(marker);
      }
    }

    if (globalMatchedRideIds.matchedRideIds.isEmpty) {
      print("No Rides Found");
    } else {
      print("MatchedRidesIds: ${globalMatchedRideIds.matchedRideIds}");
      print("RideIndex: ${globalMatchedRideIds.rideIndex}");
    }
    print("Matched Users: ${globalMatchedRideIds.matchedUserIds}");
    print("Function End");

    return markers;
  }


  // Future<List<loc.Marker>> fetchRidesWithin3km({
  //   required double passengerSourceLatitude,
  //   required double passengerSourceLongitude,
  //   required double passengerDestinationLatitude,
  //   required double passengerDestinationLongitude,
  //   required DateTime? dateTime,
  //   required String? vehicleType,
  // }) async {
  //   passengerRideData.rideSourceLatitude = passengerSourceLatitude;
  //   passengerRideData.rideSourceLongitude = passengerSourceLongitude;
  //   passengerRideData.rideDestinationLatitude = passengerDestinationLatitude;
  //   passengerRideData.rideDestinationLongitude = passengerDestinationLongitude;
  //
  //   FirebaseFirestore firestore = FirebaseFirestore.instance;
  //   List<loc.Marker> markers = [];
  //
  //   QuerySnapshot ridesQuery = await firestore.collection('rides').get();
  //   print("Rides fetched: ${ridesQuery.docs.length}");
  //
  //   for (QueryDocumentSnapshot rideSnapshot in ridesQuery.docs) {
  //     double driverSourceLatitude = rideSnapshot['sourceLatitude'];
  //     double driverSourceLongitude = rideSnapshot['sourceLongitude'];
  //     double driverDestinationLatitude = rideSnapshot['destinationLatitude'];
  //     double driverDestinationLongitude = rideSnapshot['destinationLongitude'];
  //     DateTime? rideDateTime = DateTime.tryParse(rideSnapshot['time']);
  //     String rideVehicleType = rideSnapshot['VehicleType'];
  //     String rideUserId = rideSnapshot['userId'];
  //     String rideId = rideSnapshot['rideId'];
  //
  //     num distanceInMeters = Geodesy().distanceBetweenTwoGeoPoints(
  //       LatLng(passengerSourceLatitude, passengerSourceLongitude),
  //       LatLng(driverSourceLatitude, driverSourceLongitude),
  //     );
  //
  //     double distanceInKm = distanceInMeters / 1000;
  //     print("Distance in KM: $distanceInKm");
  //
  //     bool isWithin3km = distanceInKm <= 3;
  //     bool isCorrectDateTime = dateTime == null ||
  //         (rideDateTime != null && dateTime.isAtSameMomentAs(rideDateTime));
  //     bool isCorrectVehicleType = vehicleType == rideVehicleType;
  //     print("isCorrectVehicleType: $isCorrectVehicleType");
  //
  //
  //     List<loc.LatLng> driverRouteMainPoints = await fetchDriverRouteMainPoints(
  //         driverSourceLatitude,
  //         driverSourceLongitude,
  //         driverDestinationLatitude,
  //         driverDestinationLongitude);
  //     print("Driver route points: ${driverRouteMainPoints}");
  //     bool isPassengerDestinationWithinRoute = isWithinDistance(
  //       loc.LatLng(passengerDestinationLatitude, passengerDestinationLongitude),
  //       driverRouteMainPoints,
  //       700,
  //     );
  //     print(
  //         "isPassengerDestinationWithinRoute: ${isPassengerDestinationWithinRoute}");
  //     if (isWithin3km &&
  //         isCorrectVehicleType ||
  //         isPassengerDestinationWithinRoute) {
  //       // if (isWithin3km && isCorrectVehicleType ) {
  //       if (!globalMatchedRideIds.matchedRideIds.contains(rideId)) {
  //         globalMatchedRideIds.matchedRideIds.add(rideId);
  //         globalMatchedRideIds.rideIndex =
  //             globalMatchedRideIds.matchedRideIds.indexOf(rideId);
  //
  //         globalMatchedRideIds.matchedUserIds.add(rideUserId);
  //       }
  //
  //       print("GlobalMatchedRideID: ${globalMatchedRideIds.matchedRideIds}");
  //       print("GlobalMatchedUserID: ${globalMatchedRideIds.matchedUserIds}");
  //     }
  //
  //     if (isWithin3km &&
  //         isCorrectVehicleType &&
  //         isPassengerDestinationWithinRoute &&
  //         isCorrectDateTime) {
  //       loc.BitmapDescriptor markerIcon =
  //           await _createCustomMarkerIcon(Colors.blue);
  //       loc.Marker marker = loc.Marker(
  //         markerId: loc.MarkerId(rideSnapshot.id),
  //         position: loc.LatLng(driverSourceLatitude, driverSourceLongitude),
  //         infoWindow: loc.InfoWindow(
  //           title: rideSnapshot['source'],
  //           snippet: 'Distance: $distanceInKm km',
  //         ),
  //         icon: markerIcon,
  //       );
  //       markers.add(marker);
  //     }
  //   }
  //
  //   if (globalMatchedRideIds.matchedRideIds.isEmpty) {
  //     print("No Rides Found");
  //   } else {
  //     print("MatchedRidesIds: ${globalMatchedRideIds.matchedRideIds}");
  //     print("RideIndex: ${globalMatchedRideIds.rideIndex}");
  //   }
  //   print("Matched Users: ${globalMatchedRideIds.matchedUserIds}");
  //   print("Function End");
  //
  //   return markers;
  // }

  Future<List<double>> fareEstimation(
      List<String> userIds,
      List<String> matchedRideIds,
      DocumentReference docRef,
      String passengerVehicleType) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    Map<String, dynamic>? passRideData;
    List<String> rideVehicleTypes = [];
    print("RideVehicleTypes: $rideVehicleTypes");
    print("Abc");
    print("Document Ref: ${docRef.id}");
    try {
      QuerySnapshot userQuery = await firestore
          .collection('vehicle_data')
          .where('userId', whereIn: userIds)
          .get();

      for (QueryDocumentSnapshot userSnapshot in userQuery.docs) {
        String drivervehicleType = userSnapshot['vehicleType'];
        print("DriverVehicleType: $drivervehicleType");

        print("PassengerVehicleType: $passengerVehicleType");
        if (drivervehicleType == passengerVehicleType) {
          rideVehicleTypes.add(drivervehicleType);
          print('RideVehicles: ${rideVehicleTypes}');
        } else {
          print('Vehicle Type does not match');
        }
      }
    } catch (e) {
      print('Error fetching vehicle data: $e');
      // Handle the error appropriately (e.g., throw or return default value)
      return [];
    }
    print("Abc");
    print("Document Ref: ${docRef.id}");
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
      }
    } catch (e) {
      print('Error fetching vehicle data: $e');
      // Handle the error appropriately (e.g., throw or return default value)
      return [];
    }

    String date = passRideData!['date'];
    double sourceLatitude = passRideData!['sourceLatitude'];
    double sourceLongitude = passRideData!['sourceLongitude'];
    String source = passRideData!['source'];
    String destination = passRideData['destination'];
    double destinationLatitude = passRideData['destinationLatitude'];
    double destinationLongitude = passRideData['destinationLongitude'];
    String time = passRideData['time'];
    // List<int> persons = passRideData['persons'];
    int persons = int.parse(passRideData['persons']);
    String vehicle = passRideData['vehicle'];
    String userId = passRideData['userId'];
    final response = await http.get(
        Uri.parse('https://www.pakwheels.com/petroleum-prices-in-pakistan'));

    if (response.statusCode == 200) {
      final document = htmlParser.parse(response.body);

      String rowData = document
          .querySelector('div:nth-child(1) > table > tbody > tr:nth-child(1)')!
          .text;

      List<String> lines = rowData.split('\n');

      String petrolPriceStr = lines[8].trim();
      double petrolPrice =
          double.tryParse(petrolPriceStr.replaceAll('PKR ', '')) ?? 0.0;
      print("Petrol Price: $petrolPriceStr");
      print("Global : $matchedRideIds");
      QuerySnapshot ridesQuery = await firestore
          .collection('rides')
          .where('rideId', whereIn: matchedRideIds)
          .get();

      List<double> rideDistancesInKm = [];
      passengerRideData.driverSourceLatitude = []; // Initialize as empty list
      passengerRideData.driverSourceLongitude = []; // Initialize as empty list

      for (QueryDocumentSnapshot rideSnapshot in ridesQuery.docs) {
        double driverSourceLatitude = rideSnapshot['sourceLatitude'];
        double driverSourceLongitude = rideSnapshot['sourceLongitude'];

        passengerRideData.driverSourceLatitude.add(driverSourceLatitude);
        passengerRideData.driverSourceLongitude.add(driverSourceLongitude);
        print("DriverSourceCoordinates ");
        print(passengerRideData.driverSourceLatitude);
        print(passengerRideData.driverSourceLongitude);
      }
      rideDistancesInKm.clear();

      for (int i = 0; i < passengerRideData.driverSourceLatitude.length; i++) {
        double driverSourceLatitude = passengerRideData.driverSourceLatitude[i];
        double driverSourceLongitude =
            passengerRideData.driverSourceLongitude[i];

        num driverSourceToPassengerSourceDistance = 0;

        driverSourceToPassengerSourceDistance =
            Geodesy().distanceBetweenTwoGeoPoints(
          LatLng(sourceLatitude, sourceLongitude),
          LatLng(driverSourceLatitude, driverSourceLongitude),
        );
        print("Abc");
        print("passrclatitude:");
        print(passengerRideData.rideSourceLatitude);
        print("passrclongitude:");
        print(passengerRideData.rideSourceLongitude);
        print("pasdeslatitude:");
        print(passengerRideData.rideDestinationLatitude);
        print("pasdeslongitude:");
        print(passengerRideData.rideDestinationLongitude);

        num passengerSourceToDestinationDistance = 0;
        passengerSourceToDestinationDistance =
            Geodesy().distanceBetweenTwoGeoPoints(
          LatLng(sourceLatitude, sourceLongitude),
          LatLng(destinationLatitude, destinationLongitude),
        );
        print("passsss Distance: $driverSourceToPassengerSourceDistance");

        print("pass Distance: $passengerSourceToDestinationDistance");

        double rideDistance = (driverSourceToPassengerSourceDistance +
                passengerSourceToDestinationDistance) /
            1000.0; // Divided by 1000 to convert meters to kilometers

        rideDistancesInKm.add(rideDistance);

        print("Ride Distance: ${rideDistancesInKm[i]} km");
      }

// You can access the ride distances using the rideDistancesInKm list.
      print("Number of Passengers: ${persons}");

      List<double> estimatedFares =
          await RideFareCalculator.calculateEstimatedFare(
        rideDistancesInKm, // Make sure calculateEstimatedFare accepts List<double> as the first argument
        petrolPrice,
        rideVehicleTypes,
      );
      passengerRideData.passengerFares =
          await RideFareCalculator.calculatePassengerFares(
        [persons],
        estimatedFares,
      );

      print(
          'Estimated Fare: ${estimatedFares.map((fare) => fare.toStringAsFixed(2)).toList()} PKR');
      print(
          'Passenger Fare: ${passengerRideData.passengerFares.map((fare) => fare.toStringAsFixed(2)).toList()} PKR');

      return passengerRideData.passengerFares;
    } else {
      print('Failed to load data. Status Code: ${response.statusCode}');
      // Return an empty list or handle the error appropriately
      return [];
    }

    // Handle any unexpected error by returning an empty list or handle it appropriately
    return [];
  }

  Future<List<Map<String, dynamic>>> joinRidesAndDriversData(
    List<String> userIds,
  ) async {
    List<Map<String, dynamic>> result = [];

    // Fetch all rides.
    CollectionReference usersCollection = firestore.collection('vehicle_data');

    QuerySnapshot querySnapshot =
        await usersCollection.where("userId", whereIn: userIds).get();
    List<Map<String, dynamic>> vehicleData = [];

    querySnapshot.docs.forEach((doc) {
      Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
      if (data != null) {
        vehicleData.add(data);
      }
    });

    // Fetch all drivers.
    QuerySnapshot driversSnapshot = await FirebaseFirestore.instance
        .collection("users")
        .where("uid", whereIn: userIds)
        .get();
    List<Map<String, dynamic>> usersData = driversSnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();

    // Create a JSON list with joined data based on the common "phoneNumber" field.
    for (var vehicle in vehicleData) {
      for (var users in usersData) {
        if (vehicle['userId'] == users['uid']) {
          Map<String, dynamic> joinedData = {
            "vehicle": vehicle,
            "users": users,
          };
          result.add(joinedData);
        }
      }
    }

    print(result);

    return result;
  }
}