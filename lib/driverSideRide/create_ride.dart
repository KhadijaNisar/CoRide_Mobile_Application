import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hitchify/global/map_key.dart';
import 'package:hitchify/home/home_screen.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:geocoding/geocoding.dart';

class CreateRideScreen extends StatefulWidget {
  const CreateRideScreen({Key? key}) : super(key: key);

  @override
  _CreateRideScreenState createState() => _CreateRideScreenState();
}

class _CreateRideScreenState extends State<CreateRideScreen> {
  TextEditingController sourceController = TextEditingController();
  TextEditingController destinationController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController timeController = TextEditingController();
  Map<String, double>? sourceLocationCoordinates;
  Map<String, double>? destinationLocationCoordinates;
  List<dynamic> sourcePlacesList = [];
  List<dynamic> destinationPlacesList = [];
  var uuid = Uuid();
  String _sessiontoken = Uuid().v4(); // Generate session token dynamically
  FirebaseFirestore firestore =
      FirebaseFirestore.instance; // Firebase Firestore instance
  FocusNode sourceFocus = FocusNode();
  FocusNode destinationFocus = FocusNode();

  Future<Map<String, double>> getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      Location location = locations.first;
      return {
        'latitude': location.latitude,
        'longitude': location.longitude,
      };
    } catch (e) {
      print("Error getting location from address: $e");
      throw e;
    }
  }

  @override
  void initState() {
    super.initState();
    sourceController.addListener(() {
      getSuggestion(sourceController.text, isSource: true);
    });
    destinationController.addListener(() {
      getSuggestion(destinationController.text, isSource: false);
    });
    sourceController.addListener(() {
      if (sourceController.text.isNotEmpty) {
        getCoordinatesFromAddress(sourceController.text).then((coordinates) {
          setState(() {
            sourceLocationCoordinates = coordinates;
          });
        }).catchError((error) {
          print('Error getting source coordinates: $error');
        });
      }
    });

    destinationController.addListener(() {
      if (destinationController.text.isNotEmpty) {
        getCoordinatesFromAddress(destinationController.text)
            .then((coordinates) {
          setState(() {
            destinationLocationCoordinates = coordinates;
          });
        }).catchError((error) {
          print('Error getting destination coordinates: $error');
        });
      }
    });
  }

  @override
  void dispose() {
    sourceController.dispose();
    destinationController.dispose();
    dateController.dispose();
    timeController.dispose();
    super.dispose();
  }

  void getSuggestion(String input, {required bool isSource}) async {
    try {
      String placesAPIKey = mapKey;
      String baseURL =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json';
      String request =
          '$baseURL?input=$input&key=$placesAPIKey&sessiontoken=$_sessiontoken';
      var response = await http.get(Uri.parse(request));
      if (response.statusCode == 200) {
        setState(() {
          if (isSource) {
            sourcePlacesList = json.decode(response.body)['predictions'];
          } else {
            destinationPlacesList = json.decode(response.body)['predictions'];
          }
        });
      } else {
        throw Exception('Failed To Load');
      }
    } catch (e) {
      print('Error fetching suggestions: $e');
      // Handle error and provide feedback to the user
    }
  }

  String? _source;
  String? _destination;
  DateTime? _date;
  TimeOfDay? _time;
  int? _availableSeats;
  List<String> _travelDays = [];
  final _formKey = GlobalKey<FormState>();
  bool sourceSelected = true;
  bool destinationSelected = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Ride')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: sourceController,
                decoration: InputDecoration(
                  labelText: 'Source',
                  fillColor: Color(0xbb8dd7bc),
                  filled: true,
                  labelStyle: TextStyle(color: Colors.black),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Enter source location'
                    : null,
                onSaved: (value) => _source = value,
                onTap: () {
                  setState(() {
                    sourcePlacesList.clear();
                    sourceSelected = false;
                  });
                },
                focusNode: sourceFocus,
                onEditingComplete: () {
                  sourceFocus.unfocus();
                },
              ),
              SizedBox(height: 20),
              Container(
                height: sourceSelected ? 0 : 200,
                child: ListView.builder(
                  itemCount: sourcePlacesList.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(sourcePlacesList[index]['description']),
                      onTap: () {
                        setState(() {
                          sourceController.text =
                              sourcePlacesList[index]['description'];
                          sourcePlacesList.clear();
                          sourceSelected = true;
                        });
                      },
                    );
                  },
                ),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: destinationController,
                decoration: InputDecoration(
                  labelText: 'Destination',
                  fillColor: Color(0xbb8dd7bc),
                  filled: true,
                  labelStyle: TextStyle(color: Colors.black),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter destination' : null,
                onSaved: (value) => _destination = value,
                onTap: () {
                  setState(() {
                    destinationPlacesList.clear();
                    destinationSelected = false;
                  });
                },
                focusNode: destinationFocus,
                onEditingComplete: () {
                  destinationFocus.unfocus();
                },
              ),
              SizedBox(height: 20),
              Container(
                height: destinationSelected ? 0 : 200,
                child: ListView.builder(
                  itemCount: destinationPlacesList.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(destinationPlacesList[index]['description']),
                      onTap: () {
                        setState(() {
                          destinationController.text =
                              destinationPlacesList[index]['description'];
                          destinationPlacesList.clear();
                          destinationSelected = true;
                        });
                      },
                    );
                  },
                ),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: dateController,
                decoration: InputDecoration(
                  labelText: 'Date',
                  fillColor: Color(0xbb8dd7bc),
                  filled: true,
                  labelStyle: TextStyle(color: Colors.black),
                ),
                onTap: () async {
                  final selectedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(DateTime.now().year + 1),
                  );
                  if (selectedDate != null) {
                    setState(() {
                      _date = selectedDate;
                      dateController.text = _date.toString().split(' ')[0];
                    });
                  }
                },
                validator: (value) => _date == null ? 'Select a date' : null,
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: timeController,
                decoration: InputDecoration(
                  labelText: 'Time',
                  fillColor: Color(0xbb8dd7bc),
                  filled: true,
                  labelStyle: TextStyle(color: Colors.black),
                ),
                onTap: () async {
                  final selectedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (selectedTime != null) {
                    setState(() {
                      _time = selectedTime;
                      timeController.text = _time.toString();
                    });
                  }
                },
                validator: (value) => _time == null ? 'Select a time' : null,
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<int>(
                value: _availableSeats,
                onChanged: (value) {
                  setState(() {
                    _availableSeats = value!;
                  });
                },
                items: [1, 2, 3, 4].map((seats) {
                  return DropdownMenuItem<int>(
                    value: seats,
                    child: Text('$seats'),
                  );
                }).toList(),
                decoration: InputDecoration(
                  labelText: 'Available Seats',
                  fillColor: Color(0xbb8dd7bc),
                  filled: true,
                  labelStyle: TextStyle(color: Colors.black),
                ),
                validator: (value) {
                  if (value == null) {
                    return 'Please select number of seats';
                  }
                  return null;
                },
                onSaved: (value) {
                  _availableSeats = value!;
                },
              ),
              SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 10,
                    children: [
                      for (final day in [
                        'Monday',
                        'Tuesday',
                        'Wednesday',
                        'Thursday',
                        'Friday',
                        'Saturday',
                        'Sunday'
                      ])
                        FilterChip(
                          label: Text(day),
                          selected: _travelDays.contains(day),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _travelDays.add(day);
                              } else {
                                _travelDays.remove(day);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                  if (_travelDays.isEmpty)
                    Text(
                      'Please select at least one day',
                      style: TextStyle(color: Colors.red),
                    ),
                ],
              ),
              SizedBox(height: 20),
              Center(
                child: Container(
                  width: 350,
                  height: 50,
                  child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Color(0xFF008955)),
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        // Store data in Firebase Firestore
                        // storeDataToFirestore();
                        saveDataToFirestore(
                          sourceController: sourceController,
                          destinationController: destinationController,
                          sourceLocationCoordinates: sourceLocationCoordinates,
                          destinationLocationCoordinates:
                              destinationLocationCoordinates,
                          date: _date,
                          time: _time,
                          availableSeats: _availableSeats,
                          travelDays: _travelDays,
                          context: context, // Pass the context parameter
                        );
                        // storeLocationInFirestore(sourceController: sourceController, destinationController: destinationController);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => HomeScreen()),
                        );
                      }
                    },
                    child: Text('Create Ride',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void saveDataToFirestore({
    required TextEditingController sourceController,
    required TextEditingController destinationController,
    Map<String, double>? sourceLocationCoordinates,
    Map<String, double>? destinationLocationCoordinates,
    DateTime? date,
    TimeOfDay? time,
    int? availableSeats,
    List<String>? travelDays,
    BuildContext? context,
  }) async {
    try {
      // Check if the user is authenticated
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User is not authenticated');
      }

      // Ensure date, time, and other required fields are not null
      if (date == null ||
          time == null ||
          availableSeats == null ||
          travelDays == null) {
        throw Exception('Required fields are null');
      }

      // Format time
      String formattedTime = '${time.hour}:${time.minute}';

      // Construct data to be stored in Firestore
      Map<String, dynamic> data = {
        'userId': currentUser.uid,
        'source': sourceController.text,
        'destination': destinationController.text,
        'date': date.toIso8601String(), // Convert DateTime to string
        'time': formattedTime,
        'availableSeats': availableSeats,
        'travelDays': travelDays,
      };

      // Include source location coordinates if available
      if (sourceLocationCoordinates != null) {
        data['sourceLatitude'] = sourceLocationCoordinates['latitude'];
        data['sourceLongitude'] = sourceLocationCoordinates['longitude'];
      }

      // Include destination location coordinates if available
      if (destinationLocationCoordinates != null) {
        data['destinationLatitude'] =
            destinationLocationCoordinates['latitude'];
        data['destinationLongitude'] =
            destinationLocationCoordinates['longitude'];
      }

      // Store data in Firestore
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      await firestore.collection('rides').add(data);

      // Show success message
      ScaffoldMessenger.of(context!).showSnackBar(
        SnackBar(
          content: Text('Ride created successfully!'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (error) {
      // Show error message
      print('Error storing data in Firestore: $error');
      ScaffoldMessenger.of(context!).showSnackBar(
        SnackBar(
          content: Text('Error creating ride. Please try again.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void storeLocationInFirestore({
    required TextEditingController sourceController,
    required TextEditingController destinationController,
    Map<String, double>? sourceLocationCoordinates,
    Map<String, double>? destinationLocationCoordinates,
  }) async {
    try {
      // Access Firebase Firestore instance
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Create a map to hold the data to be stored in Firestore
      Map<String, dynamic> data = {
        'source': sourceController.text,
        'destination': destinationController.text,
      };

      // Include source location coordinates if available
      if (sourceLocationCoordinates != null) {
        data['sourceLatitude'] = sourceLocationCoordinates['latitude'];
        data['sourceLongitude'] = sourceLocationCoordinates['longitude'];
      }

      // Include destination location coordinates if available
      if (destinationLocationCoordinates != null) {
        data['destinationLatitude'] =
            destinationLocationCoordinates['latitude'];
        data['destinationLongitude'] =
            destinationLocationCoordinates['longitude'];
      }

      // Add data to Firestore collection
      await firestore.collection('rides').add(data);

      // Show success message
      print('Data stored successfully in Firestore!');
    } catch (error) {
      // Show error message
      print('Error storing data in Firestore: $error');
    }
  }

  void storeDataInFirestore() async {
    String formattedTime = '${_time!.hour}:${_time!.minute}';

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      String? userId = currentUser?.uid;

      if (userId != null) {
        // Add your Firebase Firestore collection reference and document creation logic here
        await firestore.collection('rides').add({
          'userId': userId, // Adding current user's ID as a foreign key
          'date': _date,
          'time': formattedTime,
          'availableSeats': _availableSeats,
          'travelDays': _travelDays,
        });

        // Provide feedback to the user
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Ride created successfully!'),
          duration: Duration(seconds: 2),
        ));
      }
    } catch (e) {
      print('Error storing data in Firestore: $e');
      // Handle error and provide feedback to the user
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error creating ride. Please try again.'),
        duration: Duration(seconds: 2),
      ));
    }
  }
}
