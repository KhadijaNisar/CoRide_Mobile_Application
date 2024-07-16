import 'dart:async';

import 'package:geolocator/geolocator.dart';

class GlobalMatchedRideIds {
  List<String> matchedRideIds = [];
  List<String> matchedUserIds = [];
  List<String> driverNames = [];
  List<String> rideVehicleBrands = [];
  List<String> rideVehicleModels = [];
  List<String> rideVehicleColor = [];
  int rideIndex = 0;
  String driverId = '';
  String rideId = '';
  double fare = 0.0;
  StreamSubscription<Position>? passengerLocationUpdateSubscription;
  StreamSubscription<Position>? driverLocationUpdateSubscription;
}
