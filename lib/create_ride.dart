import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

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
  List<dynamic> sourcePlacesList = [];
  List<dynamic> destinationPlacesList = [];
  var uuid = Uuid();
  String _sessiontoken = Uuid().v4(); // Generate session token dynamically
  FirebaseFirestore firestore = FirebaseFirestore.instance; // Firebase Firestore instance
  FocusNode sourceFocus = FocusNode();
  FocusNode destinationFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    sourceController.addListener(() {
      getSuggestion(sourceController.text, isSource: true);
    });
    destinationController.addListener(() {
      getSuggestion(destinationController.text, isSource: false);
    });
  }

  void getSuggestion(String input, {required bool isSource}) async {
    try {
      String placesAPIKey = "AIzaSyAc6_eajOJbsExAPNlO2NYNhnx5z7c17hA";
      String baseURL = 'https://maps.googleapis.com/maps/api/place/autocomplete/json';
      String request = '$baseURL?input=$input&key=$placesAPIKey&sessiontoken=$_sessiontoken';
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
                validator: (value) => value == null || value.isEmpty ? 'Enter source location' : null,
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
                          sourceController.text = sourcePlacesList[index]['description'];
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
                validator: (value) => value == null || value.isEmpty ? 'Enter destination' : null,
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
                          destinationController.text = destinationPlacesList[index]['description'];
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
              TextFormField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Available Seats',
                  fillColor: Color(0xbb8dd7bc),
                  filled: true,
                  labelStyle: TextStyle(color: Colors.black),
                ),
                validator: (value) => value == null || int.tryParse(value) == null
                    ? 'Enter valid number of seats'
                    : null,
                onSaved: (value) => _availableSeats = int.tryParse(value!),
              ),
              SizedBox(height: 20),
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
              SizedBox(height: 20),
              Center(
                child: Container(
                  width: 350,
                  height: 50,
                  child: ElevatedButton(
                    style : ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(Color(0xFF008955)),
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        // Store data in Firebase Firestore
                        storeDataInFirestore();
                      }
                    },
                    child: Text('Create Ride',style: TextStyle(color: Colors.white,fontSize: 16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void storeDataInFirestore() async {
    String formattedTime = '${_time!.hour}:${_time!.minute}';
    try {
      // Add your Firebase Firestore collection reference and document creation logic here
      await firestore.collection('rides').add({
        'source': _source,
        'destination': _destination,
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





// import 'dart:convert';
//
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:uuid/uuid.dart';
// import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
//
// class CreateRideScreen extends StatefulWidget {
//   const CreateRideScreen({Key? key}) : super(key: key);
//
//   @override
//   _CreateRideScreenState createState() => _CreateRideScreenState();
// }
//
// class _CreateRideScreenState extends State<CreateRideScreen> {
//   TextEditingController sourceController = TextEditingController();
//   TextEditingController destinationController = TextEditingController();
//   TextEditingController dateController = TextEditingController();
//   TextEditingController timeController = TextEditingController();
//   List<dynamic> sourcePlacesList = [];
//   List<dynamic> destinationPlacesList = [];
//   var uuid = Uuid();
//   String _sessiontoken = Uuid().v4(); // Generate session token dynamically
//   FirebaseFirestore firestore = FirebaseFirestore.instance; // Firebase Firestore instance
//   FocusNode sourceFocus = FocusNode();
//   FocusNode destinationFocus = FocusNode();
//
//   @override
//   void initState() {
//     super.initState();
//     sourceController.addListener(() {
//       getSuggestion(sourceController.text, isSource: true);
//     });
//     destinationController.addListener(() {
//       getSuggestion(destinationController.text, isSource: false);
//     });
//   }
//
//   void getSuggestion(String input, {required bool isSource}) async {
//     try {
//       String placesAPIKey = "AIzaSyAc6_eajOJbsExAPNlO2NYNhnx5z7c17hA";
//       String baseURL = 'https://maps.googleapis.com/maps/api/place/autocomplete/json';
//       String request = '$baseURL?input=$input&key=$placesAPIKey&sessiontoken=$_sessiontoken';
//       var response = await http.get(Uri.parse(request));
//       if (response.statusCode == 200) {
//         setState(() {
//           if (isSource) {
//             sourcePlacesList = json.decode(response.body)['predictions'];
//           } else {
//             destinationPlacesList = json.decode(response.body)['predictions'];
//           }
//         });
//       } else {
//         throw Exception('Failed To Load');
//       }
//     } catch (e) {
//       print('Error fetching suggestions: $e');
//       // Handle error and provide feedback to the user
//     }
//   }
//
//   String? _source;
//   String? _destination;
//   DateTime? _date;
//   TimeOfDay? _time;
//   int? _availableSeats;
//   List<String> _travelDays = [];
//   final _formKey = GlobalKey<FormState>();
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Create Ride')),
//       body: SingleChildScrollView(
//         padding: EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               TextFormField(
//                 controller: sourceController,
//                 decoration: InputDecoration(
//                   labelText: 'Source',
//                   fillColor: Color(0xbb8dd7bc),
//                   filled: true,
//                   labelStyle: TextStyle(color: Colors.black),
//                 ),
//                 validator: (value) => value == null || value.isEmpty ? 'Enter source location' : null,
//                 onSaved: (value) => _source = value,
//                 onTap: () {
//                   setState(() {
//                     sourcePlacesList.clear();
//                   });
//                 },
//                 focusNode: sourceFocus,
//                 onEditingComplete: () {
//                   sourceFocus.unfocus();
//                 },
//               ),
//               SizedBox(height: 20),
//               Container(
//                 height: 200,
//                 child: ListView.builder(
//                   itemCount: sourcePlacesList.length,
//                   itemBuilder: (context, index) {
//                     return ListTile(
//                       title: Text(sourcePlacesList[index]['description']),
//                       onTap: () {
//                         setState(() {
//                           sourceController.text = sourcePlacesList[index]['description'];
//                           sourcePlacesList.clear();
//                         });
//                       },
//                     );
//                   },
//                 ),
//               ),
//               SizedBox(height: 20),
//               TextFormField(
//                 controller: destinationController,
//                 decoration: InputDecoration(
//                   labelText: 'Destination',
//                   fillColor: Color(0xbb8dd7bc),
//                   filled: true,
//                   labelStyle: TextStyle(color: Colors.black),
//                 ),
//                 validator: (value) => value == null || value.isEmpty ? 'Enter destination' : null,
//                 onSaved: (value) => _destination = value,
//                 onTap: () {
//                   setState(() {
//                     destinationPlacesList.clear();
//                   });
//                 },
//                 focusNode: destinationFocus,
//                 onEditingComplete: () {
//                   destinationFocus.unfocus();
//                 },
//               ),
//               SizedBox(height: 20),
//               Container(
//                 height: 200,
//                 child: ListView.builder(
//                   itemCount: destinationPlacesList.length,
//                   itemBuilder: (context, index) {
//                     return ListTile(
//                       title: Text(destinationPlacesList[index]['description']),
//                       onTap: () {
//                         setState(() {
//                           destinationController.text = destinationPlacesList[index]['description'];
//                           destinationPlacesList.clear();
//                         });
//                       },
//                     );
//                   },
//                 ),
//               ),
//               SizedBox(height: 20),
//               TextFormField(
//                 controller: dateController,
//                 decoration: InputDecoration(
//                   labelText: 'Date',
//                   fillColor: Color(0xbb8dd7bc),
//                   filled: true,
//                   labelStyle: TextStyle(color: Colors.black),
//                 ),
//                 onTap: () async {
//                   final selectedDate = await showDatePicker(
//                     context: context,
//                     initialDate: DateTime.now(),
//                     firstDate: DateTime.now(),
//                     lastDate: DateTime(DateTime.now().year + 1),
//                   );
//                   if (selectedDate != null) {
//                     setState(() {
//                       _date = selectedDate;
//                       dateController.text = _date.toString().split(' ')[0];
//                     });
//                   }
//                 },
//                 validator: (value) => _date == null ? 'Select a date' : null,
//               ),
//               SizedBox(height: 20),
//               TextFormField(
//                 controller: timeController,
//                 decoration: InputDecoration(
//                   labelText: 'Time',
//                   fillColor: Color(0xbb8dd7bc),
//                   filled: true,
//                   labelStyle: TextStyle(color: Colors.black),
//                 ),
//                 onTap: () async {
//                   final selectedTime = await showTimePicker(
//                     context: context,
//                     initialTime: TimeOfDay.now(),
//                   );
//                   if (selectedTime != null) {
//                     setState(() {
//                       _time = selectedTime;
//                       timeController.text = _time.toString();
//                     });
//                   }
//                 },
//                 validator: (value) => _time == null ? 'Select a time' : null,
//               ),
//               SizedBox(height: 20),
//               TextFormField(
//                 keyboardType: TextInputType.number,
//                 decoration: InputDecoration(
//                   labelText: 'Available Seats',
//                   fillColor: Color(0xbb8dd7bc),
//                   filled: true,
//                   labelStyle: TextStyle(color: Colors.black),
//                 ),
//                 validator: (value) => value == null || int.tryParse(value) == null
//                     ? 'Enter valid number of seats'
//                     : null,
//                 onSaved: (value) => _availableSeats = int.tryParse(value!),
//               ),
//               SizedBox(height: 20),
//               Wrap(
//                 spacing: 10,
//                 children: [
//                   for (final day in [
//                     'Monday',
//                     'Tuesday',
//                     'Wednesday',
//                     'Thursday',
//                     'Friday',
//                     'Saturday',
//                     'Sunday'
//                   ])
//                     FilterChip(
//                       label: Text(day),
//                       selected: _travelDays.contains(day),
//                       onSelected: (selected) {
//                         setState(() {
//                           if (selected) {
//                             _travelDays.add(day);
//                           } else {
//                             _travelDays.remove(day);
//                           }
//                         });
//                       },
//                     ),
//                 ],
//               ),
//               SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: () {
//                   if (_formKey.currentState!.validate()) {
//                     _formKey.currentState!.save();
//                     // Store data in Firebase Firestore
//                     storeDataInFirestore();
//                   }
//                 },
//                 child: Text('Create Ride'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   void storeDataInFirestore() async {
//     String formattedTime = '${_time!.hour}:${_time!.minute}';
//     try {
//       // Add your Firebase Firestore collection reference and document creation logic here
//       await firestore.collection('rides').add({
//         'source': _source,
//         'destination': _destination,
//         'date': _date,
//         'time': formattedTime,
//         'availableSeats': _availableSeats,
//         'travelDays': _travelDays,
//       });
//
//       // Provide feedback to the user
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//         content: Text('Ride created successfully!'),
//         duration: Duration(seconds: 2),
//       ));
//     } catch (e) {
//       print('Error storing data in Firestore: $e');
//       // Handle error and provide feedback to the user
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//         content: Text('Error creating ride. Please try again.'),
//         duration: Duration(seconds: 2),
//       ));
//     }
//   }
// }
