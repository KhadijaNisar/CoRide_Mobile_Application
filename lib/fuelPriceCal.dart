import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:geodesy/geodesy.dart';
import 'package:html/parser.dart' as htmlParser;

class RideFareCalculator {
  static const Map<String, double> baseFares = {
    'Bike': 50.0,
    'Rickshaw': 100.0,
    'Car': 200.0,
  };

  static Future<double> calculateRatePerUnitDistance(
      double petrolPrice, String vehicleType) async {
    Map<String, double> consumptionFactors = {
      'bike': 0.05, // Liters per km
      'rickshaw': 0.08, // Liters per km
      'Car': 0.1, // Liters per km (fixed typo)
    };

    double ratePerUnitDistance = petrolPrice * consumptionFactors[vehicleType]!;
    return ratePerUnitDistance;
  }

  static Future<List<double>> calculateEstimatedFare(List<double> distances,
      double petrolPrice, List<String> vehicleTypes) async {
    double baseFare = 0.0;
    for (String vehicleType in vehicleTypes) {
      baseFare += baseFares[vehicleType] ?? 0.0;
    }

    double totalRatePerUnitDistance = 0.0;
    for (String vehicleType in vehicleTypes) {
      totalRatePerUnitDistance +=
          await calculateRatePerUnitDistance(petrolPrice, vehicleType);
    }
    List<double> estimatedFares = [];
    for (double distance in distances) {
      double sum = distance * totalRatePerUnitDistance;
      estimatedFares.add(baseFare + sum);
    }

    return estimatedFares;
  }

  static Future<List<double>> calculatePassengerFares(
      List<int> passengersCounts, List<double> estimatedFare) async {
    Map<int, Map<String, double>> fareRatios = {
      0: {'passenger': 0.0, 'driver': 1.0},
      1: {'passenger': 0.6, 'driver': 0.4},
      2: {'passenger': 0.7, 'driver': 0.3},
      3: {'passenger': 0.8, 'driver': 0.2},
      4: {'passenger': 0.9, 'driver': 0.1},
    };

    List<double> passengerFares = [];
    for (int i = 0; i < estimatedFare.length; i++) {
      int passcount = passengersCounts[0];

      double? fareRatio = fareRatios[passcount]?['passenger'];
      double passengerFare = estimatedFare[i] * fareRatio!;
      passengerFares.add(passengerFare);
    }
    print("PassengerFares ");
    print(estimatedFare);
    print("Passengercount");
    print(passengersCounts);
    return passengerFares;
  }
}
