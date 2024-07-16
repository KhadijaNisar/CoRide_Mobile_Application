import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import 'package:hitchify/passengerSideRide/Rides.dart';
import 'package:hitchify/home/vehicleselection.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hitchify/home/nav_bar.dart';
import 'package:action_slider/action_slider.dart';
import 'package:hitchify/home/animated_downbar.dart';
import 'package:hitchify/home/bookingPerson.dart';
import 'package:hitchify/driverAndVehicleRegistration/vehicle.dart';
import 'package:location/location.dart' as loc;
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:hitchify/global/map_key.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart' as loc;

import 'package:hitchify/home/toggle_selection.dart';

import 'package:hitchify/passengerSideRide//match_rides.dart';
import '../passengerSideRide/GlobalMatchedRideIds.dart';
import 'driver_home.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  //Controllers
  TextEditingController sourceController = TextEditingController();
  TextEditingController destinationController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController timeController = TextEditingController();
  TextEditingController personsController = TextEditingController();
  TextEditingController vehicleSelectController = TextEditingController();
  late DocumentReference docRef;
  int selectedNumberOfPersons = 1;
  String? selectedDateText;
  String? selectedVehicleText;
  Map<String, double>? sourceLocationCoordinates;
  Map<String, double>? destinationLocationCoordinates;
  List<dynamic> sourcePlacesList = [];
  List<dynamic> destinationPlacesList = [];

  void _onTextChanged(String input, {bool isSource = false}) {
    // Perform the necessary logic to update the suggestions based on the input
    // and populate the destinationPlacesList with the updated suggestions.

    // Then, call setState to rebuild the ListView.builder with the updated suggestions.
    setState(() {});
  }

  var uuid = Uuid();
  String _sessiontoken = Uuid().v4(); // Generate session token dynamically
  FirebaseFirestore firestore =
      FirebaseFirestore.instance; // Firebase Firestore instance
  FocusNode sourceFocus = FocusNode();
  FocusNode destinationFocus = FocusNode();
  final Completer<GoogleMapController> _controller = Completer();

  static const LatLng srcLocation =
      LatLng(31.45725697261883, 73.15453226904458);
  static const LatLng destLocation =
      LatLng(31.376427711911038, 73.06324943511385);

  List<LatLng> polylineCoordinates = [];
  loc.LocationData? currentLocation;

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

  loc.Location location = loc.Location();

  Future<void> _initMap() async {
    try {
      currentLocation = await location.getLocation();
    } catch (e) {
      print("Error getting location: $e");
    }

    if (mounted) {
      setState(() {});
    }

    if (currentLocation != null) {
      _setUpMap();
      getPolyPoints(); // Call getPolyPoints here to fetch polyline coordinates
    }
  }

  void _setUpMap() async {
    GoogleMapController googleMapController = await _controller.future;

    googleMapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          zoom: 13.5,
          target:
              LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
        ),
      ),
    );
  }

  void getPolyPoints() async {
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      mapKey,
      PointLatLng(srcLocation.latitude, srcLocation.longitude),
      PointLatLng(currentLocation!.latitude!, currentLocation!.longitude!),
    );

    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) =>
          polylineCoordinates.add(LatLng(point.latitude, point.longitude)));
      if (mounted) {
        setState(() {});
      }
    }
  }

  late AnimationController _animationController;
  bool _isDriverMode = false;
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    _initializeCameraPosition();
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _initMap();
    _selectedTime = TimeOfDay.now();
    sourceController.addListener(() {
      getSuggestion(sourceController.text, isSource: true);
    });
    destinationController.addListener(() {
      getSuggestion(destinationController.text, isSource: false);
    });
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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMode(BuildContext context) {
    ModeToggle modeToggle = Provider.of<ModeToggle>(context, listen: false);
    modeToggle.toggleMode();

    if (modeToggle.isDriverMode) {
      fetchDataAndNavigate(context);
      _animationController.reverse();
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
      _animationController.forward();
    }
  }

  Color _toggleColor(BuildContext context) {
    ModeToggle modeToggle = Provider.of<ModeToggle>(context);
    return modeToggle.isDriverMode ? Color(0xff52c498) : Color(0x7744C393);
    // return _isDriverMode ? Color(0xff52c498) : Color(0x7744C393);
  }

  void _openModal(BuildContext context, String title, String content) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (pickedTime != null && pickedTime != _selectedTime) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  late CameraPosition _cameraPosition;
  void _initializeCameraPosition() {
    _cameraPosition = CameraPosition(
      target: LatLng(
        currentLocation?.latitude ?? 0,
        currentLocation?.longitude ?? 0,
      ),
      zoom: 14.5,
    );
  }

  // Method to update the camera position based on the source location
  void _updateCameraPosition() {
    LatLng target = LatLng(
      sourceLocationCoordinates?['latitude'] ?? currentLocation!.latitude!,
      sourceLocationCoordinates?['longitude'] ?? currentLocation!.longitude!,
    );
    _cameraPosition = CameraPosition(
      target: target,
      zoom: 14.5,
    );
    _goToNewLocation(_cameraPosition);
  }

// Method to move the camera to a new location
  Future<void> _goToNewLocation(CameraPosition newCameraPosition) async {
    try {
      final GoogleMapController controller = await _controller.future;
      await controller
          .animateCamera(CameraUpdate.newCameraPosition(newCameraPosition));
    } catch (e) {
      print("Error updating camera position: $e");
    }
  }

  // Method to update the map markers
  void updateMarkers() {
    setState(() {
      markers.clear();
      polylines.clear();
      _buildMarkers();
      _buildPolyline();

      _updateCameraPosition();
    });
  }

  // Method to build markers
  void _buildMarkers() {
    // Add current location marker
    if (currentLocation != null) {
      markers.add(
        Marker(
          markerId: MarkerId("Current Location"),
          position: LatLng(
            currentLocation!.latitude!,
            currentLocation!.longitude!,
          ),
        ),
      );
    }

    // Add destination location marker
    if (destinationLocationCoordinates != null) {
      markers.add(
        Marker(
          markerId: MarkerId("Destination"),
          position: LatLng(
            destinationLocationCoordinates!['latitude']!,
            destinationLocationCoordinates!['longitude']!,
          ),
        ),
      );
    }

    // Add source location marker
    if (sourceLocationCoordinates != null) {
      markers.add(
        Marker(
          markerId: MarkerId("Source"),
          position: LatLng(
            sourceLocationCoordinates!['latitude']!,
            sourceLocationCoordinates!['longitude']!,
          ),
        ),
      );
    }
  }

  // Method to build polyline
  Future<void> _buildPolyline() async {
    if (sourceLocationCoordinates != null &&
        destinationLocationCoordinates != null) {
      String googleMapsDirectionsAPIKey = mapKey;

      // Construct the URL for the Google Maps Directions API request
      String url =
          'https://maps.googleapis.com/maps/api/directions/json?origin=${sourceLocationCoordinates!['latitude']},${sourceLocationCoordinates!['longitude']}&destination=${destinationLocationCoordinates!['latitude']},${destinationLocationCoordinates!['longitude']}&key=$googleMapsDirectionsAPIKey';

      // Send the request
      http.Response response = await http.get(Uri.parse(url));

      // If the request was successful
      if (response.statusCode == 200) {
        // Parse the response body
        Map<String, dynamic> responseBody = jsonDecode(response.body);

        // Get the encoded polyline points from the response
        String encodedPolylinePoints =
            responseBody['routes'][0]['overview_polyline']['points'];

        // Decode the polyline points
        List<LatLng> polylinePoints = PolylinePoints()
            .decodePolyline(encodedPolylinePoints)
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();

        // Add the polyline to the map
        setState(() {
          polylines.add(Polyline(
            polylineId: PolylineId("route"),
            points: polylinePoints,
            color: Colors.green,
            width: 6,
          ));
        });
      } else {
        print(
            'Request to Google Maps Directions API failed with status code: ${response.statusCode}');
      }
    }
  }

  //To Store the fields values
  String? _source;
  String? _destination;
  DateTime? _date;
  TimeOfDay? _time;
  int? _availableSeats;
  List<String> _travelDays = [];
  final _formKey = GlobalKey<FormState>();
  bool sourceSelected = true;
  bool destinationSelected = true;
  DateTime? currentBackPressTime;
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: WillPopScope(
          onWillPop: () async {
            bool exit = await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  backgroundColor: const Color(0xff52c498),
                  // Colors.green, // Set background color
                  title: Text(
                    'Exit App',
                    style: TextStyle(color: Colors.white), // Set title color
                  ),
                  content: Text(
                    'Are you sure you want to exit?',
                    style: TextStyle(color: Colors.white), // Set content color
                  ),
                  actions: <Widget>[
                    TextButton(
                      child: Text(
                        'No',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18), // Set button text color
                      ),
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      },
                    ),
                    TextButton(
                      child: Text(
                        'Yes',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18), // Set button text color
                      ),
                      onPressed: () {
                        SystemChannels.platform
                            .invokeMethod('SystemNavigator.pop');
                      },
                    ),
                  ],
                );
              },
            );
            return exit ?? false;
          },
          child: SafeArea(
              child: Scaffold(
            extendBodyBehindAppBar: true,
            key: _scaffoldKey,
            drawer: NavBar(
              userType: 'passenger',
              passenger: '',
            ),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Builder(
                  builder: (context) {
                    return Container(
                      height: 100,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ActionSlider.standard(
                            sliderBehavior: SliderBehavior.stretch,
                            height: 45,
                            width: 200.0,
                            backgroundColor: Colors.white,
                            toggleColor: _toggleColor(context),
                            action: (controller) {
                              _toggleMode(context);
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: Text(
                                _isDriverMode
                                    ? 'Driver Mode'
                                    : 'Passenger Mode',
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              actions: [
                // Move the actions property inside the AppBar widget
                IconButton(
                  icon: Icon(Icons.notifications),
                  onPressed: () {
                    // Handle notification button press
                  },
                ),
              ],
            ),
            body: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: _cameraPosition,
                  markers: markers,
                  polylines: polylines,
                  onMapCreated: (mapController) {
                    // Any map controller initialization if needed
                    _controller.complete(mapController);
                  },
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: 
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 50, 8, 0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 200,
                          ),
                          Container(
                            width: double.infinity,
                            height: 250,
                            margin: EdgeInsets.symmetric(horizontal: 15),
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 20,
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xffb2dbcc),
                              // Set the background color
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Color(0xff52c498),
                                // Set the border color
                                width: 2, // Set the border width
                              ),
                            ),
                            child: Flexible(
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  // mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment:
                                  CrossAxisAlignment.stretch,
                                  children: [
                                    //1st modal
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        showModalBottomSheet(
                                          scrollControlDisabledMaxHeightRatio:
                                              10,
                                          context: context,
                                          builder: (BuildContext context) {
                                            return SingleChildScrollView(
                                              child: Container(
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                    0.8,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.only(
                                                    topLeft:
                                                        Radius.circular(30),
                                                    topRight:
                                                        Radius.circular(30),
                                                  ),
                                                ),
                                                child: Column(
                                                  children: [
                                                    Align(
                                                      alignment:
                                                          Alignment.topRight,
                                                      child: IconButton(
                                                        icon: Icon(
                                                          Icons
                                                              .keyboard_arrow_down_outlined,
                                                          color: Colors.black,
                                                        ),
                                                        onPressed: () {
                                                          Navigator.of(context)
                                                              .pop();
                                                        },
                                                      ),
                                                    ),
                                                    Container(
                                                      width: double.infinity,
                                                      alignment:
                                                          Alignment.center,
                                                      child: Column(
                                                        children: [
                                                          Divider(
                                                            color: Colors.grey,
                                                            thickness: 4.0,
                                                            height: 0.0,
                                                            indent: 85.0,
                                                            endIndent: 85.0,
                                                          ),
                                                          SizedBox(height: 10),
                                                          Text(
                                                            'Select PickUp Location',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.black,
                                                              fontFamily:
                                                                  'Poppins',
                                                              fontSize: 18,
                                                            ),
                                                          ),
                                                          SizedBox(height: 12),
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        8.0),
                                                            child: Container(
                                                              decoration:
                                                                  BoxDecoration(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            10),
                                                                border:
                                                                    Border.all(
                                                                  color: Colors
                                                                      .grey,
                                                                  width: 1.0,
                                                                ),
                                                              ),
                                                              child: Row(
                                                                children: [
                                                                  Padding(
                                                                    padding:
                                                                        EdgeInsets.all(
                                                                            8.0),
                                                                    child: Icon(
                                                                      Icons
                                                                          .my_location_sharp,
                                                                      color: Colors
                                                                          .grey,
                                                                    ),
                                                                  ),
                                                                  Flexible(
                                                                    child:
                                                                        TextFormField(
                                                                      focusNode:
                                                                          sourceFocus,
                                                                      onChanged:
                                                                          (input) {
                                                                        getSuggestion(
                                                                            input,
                                                                            isSource:
                                                                                true); // Call getSuggestion when text changes
                                                                        _onTextChanged(
                                                                            input,
                                                                            isSource:
                                                                                false);
                                                                      },
                                                                      onEditingComplete:
                                                                          () {
                                                                        sourceFocus
                                                                            .unfocus();
                                                                      },
                                                                      controller:
                                                                          sourceController,
                                                                      validator: (value) => value == null ||
                                                                              value.isEmpty
                                                                          ? 'Enter source location'
                                                                          : null,
                                                                      onSaved: (value) =>
                                                                          _source =
                                                                              value,
                                                                      onTap:
                                                                          () {
                                                                        setState(
                                                                            () {
                                                                          sourcePlacesList
                                                                              .clear();
                                                                          sourceSelected =
                                                                              false;
                                                                        });
                                                                      },
                                                                      decoration:
                                                                          InputDecoration(
                                                                        border:
                                                                            InputBorder.none,
                                                                        hintText:
                                                                            'Enter your Source Location',
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                          SizedBox(height: 20),
                                                          Container(
                                                            height:
                                                                sourceSelected
                                                                    ? 0
                                                                    : 300,
                                                            child: ListView
                                                                .builder(
                                                              itemCount:
                                                                  sourcePlacesList
                                                                      .length,
                                                              itemBuilder:
                                                                  (context,
                                                                      index) {
                                                                return ListTile(
                                                                  title: Text(sourcePlacesList[
                                                                          index]
                                                                      [
                                                                      'description']),
                                                                  onTap: () {
                                                                    setState(
                                                                        () {
                                                                      sourceController
                                                                          .text = sourcePlacesList[
                                                                              index]
                                                                          [
                                                                          'description'];
                                                                      sourcePlacesList
                                                                          .clear();
                                                                      sourceSelected =
                                                                          true;
                                                                    });
                                                                  },
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                          SizedBox(height: 20),
                                                          ElevatedButton(
                                                            onPressed:
                                                                () async {
                                                              if (_formKey
                                                                  .currentState!
                                                                  .validate()) {
                                                                _formKey
                                                                    .currentState!
                                                                    .save();
                                                                String address =
                                                                    sourceController
                                                                        .text;
                                                                sourceLocationCoordinates =
                                                                    await getCoordinatesFromAddress(
                                                                        address);
                                                                print(
                                                                    'Latitude: ${sourceLocationCoordinates?['latitude']}, Longitude: ${sourceLocationCoordinates?['longitude']}');
                                                                await Future.delayed(
                                                                    Duration(
                                                                        milliseconds:
                                                                            500)); // Add a delay here
                                                                updateMarkers();
                                                                Navigator.of(
                                                                        context)
                                                                    .pop(); // Close the modal bottom sheet
                                                              }
                                                            },
                                                            style:
                                                            ButtonStyle(
                                                              backgroundColor:
                                                              MaterialStateProperty.all<
                                                                  Color>(
                                                                  Color(
                                                                      0xFF008955)),
                                                              minimumSize:
                                                              MaterialStateProperty
                                                                  .all<
                                                                  Size>(
                                                                Size(250,
                                                                    40), // Change the width (and height) as needed
                                                              ),
                                                            ),                                                          child: Text(
                                                              'Add',
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontFamily:
                                                                    'Poppins',
                                                                fontSize: 14,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                        passengerRideData.passengerSource =
                                            sourceController.text;
                                        sourceLocationCoordinates =
                                            await getCoordinatesFromAddress(
                                                passengerRideData
                                                    .passengerSource);
                                        print(
                                            'Latitude: ${sourceLocationCoordinates?['latitude']}, Longitude: ${sourceLocationCoordinates?['longitude']}');
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xffe2f5ed),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 50),
                                      ),
                                      icon: Icon(
                                        Icons.search,
                                        color: Colors.grey,
                                      ),
                                      label: Text(
                                        'Pick Up Location',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontFamily: 'Poppins',
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    //Second Modal
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        showModalBottomSheet(
                                          scrollControlDisabledMaxHeightRatio:
                                              10,
                                          backgroundColor:
                                              Color.fromARGB(0, 255, 255, 255),
                                          context: context,
                                          builder: (BuildContext Context) {
                                            return SingleChildScrollView(
                                              child: Container(
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                    0.8,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.only(
                                                    topLeft: Radius.circular(30),
                                                    topRight: Radius.circular(30),
                                                  ),
                                                ),
                                                child: Column(
                                                  children: [
                                                    Align(
                                                      alignment:
                                                          Alignment.topRight,
                                                      child: IconButton(
                                                        icon: Icon(
                                                          Icons
                                                              .keyboard_arrow_down_outlined,
                                                          color: Colors.black,
                                                        ),
                                                        onPressed: () {
                                                          Navigator.of(Context)
                                                              .pop();
                                                        },
                                                      ),
                                                    ),
                                                    Container(
                                                      width: double.infinity,
                                                      alignment: Alignment.center,
                                                      child: Column(
                                                        children: [
                                                          Divider(
                                                            color: Colors.grey,
                                                            thickness: 4.0,
                                                            height: 0.0,
                                                            indent: 85.0,
                                                            endIndent: 85.0,
                                                          ),
                                                          SizedBox(
                                                            height: 8,
                                                          ),
                                                          Text(
                                                            'Select Destination',
                                                            style: TextStyle(
                                                              color: Colors.black,
                                                              fontFamily:
                                                                  'Poppins',
                                                              fontSize:
                                                                  18, // Set the text color
                                                            ),
                                                          ),
                                                          Divider(
                                                            color: Colors.grey,
                                                            thickness: 1.0,
                                                            height: 12.0,
                                                            indent: 0.0,
                                                            endIndent: 0.0,
                                                          ),
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        8.0),
                                                            child: Container(
                                                              decoration:
                                                                  BoxDecoration(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            10),
                                                                border:
                                                                    Border.all(
                                                                  color:
                                                                      Colors.grey,
                                                                  width: 1.0,
                                                                ),
                                                              ),
                                                              child: Row(
                                                                children: [
                                                                  Padding(
                                                                    padding:
                                                                        EdgeInsets
                                                                            .all(
                                                                                8.0),
                                                                    child: Icon(
                                                                      Icons
                                                                          .my_location_sharp,
                                                                      color: Colors
                                                                          .grey,
                                                                    ),
                                                                  ),
                                                                  Expanded(
                                                                    child:
                                                                        TextFormField(
                                                                      controller:
                                                                          destinationController,
                                                                      validator: (value) => value ==
                                                                                  null ||
                                                                              value.isEmpty
                                                                          ? 'Enter destination location'
                                                                          : null,
                                                                      onSaved: (value) =>
                                                                          _destination =
                                                                              value,
                                                                      onTap: () {
                                                                        setState(
                                                                            () {
                                                                          destinationPlacesList
                                                                              .clear();
                                                                          destinationSelected =
                                                                              false;
                                                                        });
                                                                      },
                                                                      decoration:
                                                                          InputDecoration(
                                                                        border: InputBorder
                                                                            .none,
                                                                        hintText:
                                                                            'Enter your Destination Location',
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            height: 20,
                                                          ),
                                                          Container(
                                                            height:
                                                                destinationSelected
                                                                    ? 0
                                                                    : 200,
                                                            child:
                                                                ListView.builder(
                                                              itemCount:
                                                                  destinationPlacesList
                                                                      .length,
                                                              itemBuilder:
                                                                  (context,
                                                                      index) {
                                                                return ListTile(
                                                                  title: Text(
                                                                      destinationPlacesList[
                                                                              index]
                                                                          [
                                                                          'description']),
                                                                  onTap: () {
                                                                    setState(() {
                                                                      destinationController
                                                                          .text = destinationPlacesList[
                                                                              index]
                                                                          [
                                                                          'description'];
                                                                      destinationPlacesList
                                                                          .clear();
                                                                      destinationSelected =
                                                                          true;
                                                                    });
                                                                  },
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            height: 20,
                                                          ),
                                                          ElevatedButton(
                                                            onPressed: () async {
                                                              if (_formKey
                                                                  .currentState!
                                                                  .validate()) {
                                                                _formKey
                                                                    .currentState!
                                                                    .save();
                                                                passengerRideData
                                                                        .passengerDestination =
                                                                    destinationController
                                                                        .text;
                                                                destinationLocationCoordinates =
                                                                    await getCoordinatesFromAddress(
                                                                        passengerRideData
                                                                            .passengerDestination);
                                                                print(
                                                                    'Latitude: ${destinationLocationCoordinates?['latitude']}, Longitude: ${destinationLocationCoordinates?['longitude']}');
                                                                await Future.delayed(
                                                                    Duration(
                                                                        milliseconds:
                                                                            500));
                                                                updateMarkers();
                                                                Navigator.of(
                                                                        context)
                                                                    .pop();
                                                              }
                                                            },
                                                            style:
                                                            ButtonStyle(
                                                              backgroundColor:
                                                              MaterialStateProperty.all<
                                                                  Color>(
                                                                  Color(
                                                                      0xFF008955)),
                                                              minimumSize:
                                                              MaterialStateProperty
                                                                  .all<
                                                                  Size>(
                                                                Size(250,
                                                                    40), // Change the width (and height) as needed
                                                              ),
                                                            ),
                                                            child: Text(
                                                              'Add',
                                                              style: TextStyle(
                                                                color:
                                                                    Colors.white,
                                                                fontFamily:
                                                                    'Poppins',
                                                                fontSize: 14,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xffe2f5ed),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 28),
                                      ),
                                      icon: Icon(
                                        Icons.search,
                                        color: Colors.grey,
                                      ),
                                      label: Text(
                                        'Where Would You Go?',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontFamily: 'Poppins',
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              showModalBottomSheet(
                                                isScrollControlled: true,
                                                backgroundColor: Colors.white,
                                                context: context,
                                                builder:
                                                    (BuildContext context) {
                                                  return Container(
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .height *
                                                            0.8,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.only(
                                                        topLeft:
                                                            Radius.circular(
                                                                30),
                                                        topRight:
                                                            Radius.circular(
                                                                30),
                                                      ),
                                                    ),
                                                    child: Column(
                                                      children: [
                                                        Align(
                                                          alignment: Alignment
                                                              .topRight,
                                                          child: IconButton(
                                                            icon: Icon(
                                                              Icons
                                                                  .keyboard_arrow_down_outlined,
                                                              color: Colors
                                                                  .black,
                                                            ),
                                                            onPressed: () {
                                                              Navigator.of(
                                                                      context)
                                                                  .pop();
                                                            },
                                                          ),
                                                        ),
                                                        Container(
                                                          width:
                                                              double.infinity,
                                                          alignment: Alignment
                                                              .center,
                                                          child: Column(
                                                            children: [
                                                              Divider(
                                                                color: Colors
                                                                    .grey,
                                                                thickness:
                                                                    4.0,
                                                                height: 0.0,
                                                                indent: 85.0,
                                                                endIndent:
                                                                    85.0,
                                                              ),
                                                              SizedBox(
                                                                  height: 8),
                                                              Text(
                                                                'Choose Date and Time',
                                                                style:
                                                                    TextStyle(
                                                                  color: Colors
                                                                      .black,
                                                                  fontFamily:
                                                                      'Poppins',
                                                                  fontSize:
                                                                      18,
                                                                ),
                                                              ),
                                                              Divider(
                                                                color: Colors
                                                                    .grey,
                                                                thickness:
                                                                    1.0,
                                                                height: 12.0,
                                                                indent: 0.0,
                                                                endIndent:
                                                                    0.0,
                                                              ),
                                                              SizedBox(
                                                                  height: 10),
                                                              Padding(
                                                                padding: const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        8.0),
                                                                child:
                                                                    Container(
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            10),
                                                                    border:
                                                                        Border
                                                                            .all(
                                                                      color: Colors
                                                                          .grey,
                                                                      width:
                                                                          1.0,
                                                                    ),
                                                                  ),
                                                                  child: Row(
                                                                    children: [
                                                                      Padding(
                                                                        padding:
                                                                            EdgeInsets.all(8.0),
                                                                        child:
                                                                            Icon(
                                                                          Icons.access_time,
                                                                          color:
                                                                              Colors.grey,
                                                                        ),
                                                                      ),
                                                                      Expanded(
                                                                        child:
                                                                            TextFormField(
                                                                          controller:
                                                                              timeController,
                                                                          readOnly:
                                                                              true,
                                                                          onTap:
                                                                              () async {
                                                                            TimeOfDay? selectedTime = await showTimePicker(
                                                                              context: context,
                                                                              initialTime: TimeOfDay.now(),
                                                                            );
                                                                            if (selectedTime != null) {
                                                                              setState(() {
                                                                                timeController.text = selectedTime.format(context);
                                                                              });
                                                                            }
                                                                          },
                                                                          decoration:
                                                                              InputDecoration(
                                                                            border: InputBorder.none,
                                                                            hintText: 'Select Time',
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                  height: 20),
                                                              ElevatedButton(
                                                                onPressed:
                                                                    () async {
                                                                  if (timeController
                                                                      .text
                                                                      .isNotEmpty) {
                                                                    print(
                                                                        'Selected Time: ${timeController.text}');
                                                                    Navigator.of(
                                                                            context)
                                                                        .pop();
                                                                  }
                                                                },
                                                                style:
                                                                ButtonStyle(
                                                                  backgroundColor:
                                                                  MaterialStateProperty.all<
                                                                      Color>(
                                                                      Color(
                                                                          0xFF008955)),
                                                                  minimumSize:
                                                                  MaterialStateProperty
                                                                      .all<
                                                                      Size>(
                                                                    Size(250,
                                                                        40), // Change the width (and height) as needed
                                                                  ),
                                                                ),
                                                                child: Text(
                                                                  'Add',
                                                                  style:
                                                                      TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontFamily:
                                                                        'Poppins',
                                                                    fontSize:
                                                                        14,
                                                                  ),
                                                                  textAlign:
                                                                      TextAlign
                                                                          .left,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Color(0xffe2f5ed),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 25),
                                            ),
                                            icon: Icon(
                                              Icons.calendar_today,
                                              color: Colors.grey,
                                            ),
                                            label: Text(
                                              'Date',
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontFamily: 'Poppins',
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 20),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              showModalBottomSheet(
                                                isScrollControlled: true,
                                                context: context,
                                                builder:
                                                    (BuildContext context) {
                                                  return Container(
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .height *
                                                            0.8,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.only(
                                                        topLeft:
                                                            Radius.circular(
                                                                30),
                                                        topRight:
                                                            Radius.circular(
                                                                30),
                                                      ),
                                                    ),
                                                    child: Column(
                                                      children: [
                                                        Align(
                                                          alignment: Alignment
                                                              .topRight,
                                                          child: IconButton(
                                                            icon: Icon(
                                                              Icons
                                                                  .keyboard_arrow_down_outlined,
                                                              color: Colors
                                                                  .black,
                                                            ),
                                                            onPressed: () {
                                                              Navigator.of(
                                                                      context)
                                                                  .pop();
                                                            },
                                                          ),
                                                        ),
                                                        Divider(
                                                          color: Colors.grey,
                                                          thickness: 4.0,
                                                          height: 0.0,
                                                          indent: 85.0,
                                                          endIndent: 85.0,
                                                        ),
                                                        SizedBox(height: 8),
                                                        Text(
                                                          'Select No. of Persons',
                                                          style: TextStyle(
                                                            color:
                                                                Colors.black,
                                                            fontFamily:
                                                                'Poppins',
                                                            fontSize: 18,
                                                          ),
                                                        ),
                                                        Divider(
                                                          color: Colors.grey,
                                                          thickness: 1.0,
                                                          height: 12.0,
                                                          indent: 0.0,
                                                          endIndent: 0.0,
                                                        ),
                                                        BookingModal(
                                                            controller:
                                                                personsController),
                                                        SizedBox(height: 20),
                                                        ElevatedButton(
                                                          onPressed: () {
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                            // print('Value stored in controller: ${personsController.text}');
                                                          },
                                                          style:
                                                          ButtonStyle(
                                                            backgroundColor:
                                                            MaterialStateProperty.all<
                                                                Color>(
                                                                Color(
                                                                    0xFF008955)),
                                                            minimumSize:
                                                            MaterialStateProperty
                                                                .all<
                                                                Size>(
                                                              Size(250,
                                                                  40), // Change the width (and height) as needed
                                                            ),
                                                          ),
                                                          child: Text(
                                                            'Add',
                                                            style: TextStyle(
                                                              color: Colors
                                                                  .white,
                                                              fontFamily:
                                                                  'Poppins',
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Color(0xffe2f5ed),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              padding: EdgeInsets.fromLTRB(
                                                  5, 5, 9, 5),
                                            ),
                                            icon: Icon(
                                              Icons.person,
                                              color: Colors.grey,
                                            ),
                                            label: Text(
                                              'Persons',
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontFamily: 'Poppins',
                                                fontSize: 14,
                                              ),
                                              textAlign: TextAlign.left,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        // Fifth modal
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              showModalBottomSheet(
                                                isScrollControlled: true,
                                                backgroundColor:
                                                    Color.fromARGB(
                                                        0, 255, 255, 255),
                                                context: context,
                                                builder:
                                                    (BuildContext context) {
                                                  return Container(
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .height *
                                                            0.8,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.only(
                                                        topLeft:
                                                            Radius.circular(
                                                                30),
                                                        topRight:
                                                            Radius.circular(
                                                                30),
                                                      ),
                                                    ),
                                                    child: Column(
                                                      children: [
                                                        Align(
                                                          alignment: Alignment
                                                              .topRight,
                                                          child: IconButton(
                                                            icon: Icon(
                                                              Icons
                                                                  .keyboard_arrow_down_outlined,
                                                              color: Colors
                                                                  .black,
                                                            ),
                                                            onPressed: () {
                                                              Navigator.of(
                                                                      context)
                                                                  .pop();
                                                            },
                                                          ),
                                                        ),
                                                        Container(
                                                          width:
                                                              double.infinity,
                                                          alignment: Alignment
                                                              .center,
                                                          child: Column(
                                                            children: [
                                                              Divider(
                                                                color: Colors
                                                                    .grey,
                                                                thickness:
                                                                    4.0,
                                                                height: 0.0,
                                                                indent: 85.0,
                                                                endIndent:
                                                                    85.0,
                                                              ),
                                                              SizedBox(
                                                                  height: 8),
                                                              Text(
                                                                'Select Travel Date',
                                                                style:
                                                                    TextStyle(
                                                                  color: Colors
                                                                      .black,
                                                                  fontFamily:
                                                                      'Poppins',
                                                                  fontSize:
                                                                      18,
                                                                ),
                                                              ),
                                                              Divider(
                                                                color: Colors
                                                                    .grey,
                                                                thickness:
                                                                    1.0,
                                                                height: 12.0,
                                                                indent: 0.0,
                                                                endIndent:
                                                                    0.0,
                                                              ),
                                                              Padding(
                                                                padding: const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        8.0),
                                                                child:
                                                                    Container(
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            10),
                                                                    border:
                                                                        Border
                                                                            .all(
                                                                      color: Colors
                                                                          .grey,
                                                                      width:
                                                                          1.0,
                                                                    ),
                                                                  ),
                                                                  child: Row(
                                                                    children: [
                                                                      Padding(
                                                                        padding:
                                                                            EdgeInsets.all(8.0),
                                                                        child:
                                                                            Icon(
                                                                          Icons.calendar_today,
                                                                          color:
                                                                              Colors.grey,
                                                                        ),
                                                                      ),
                                                                      Expanded(
                                                                        child:
                                                                            TextFormField(
                                                                          readOnly:
                                                                              true,
                                                                          controller:
                                                                              dateController,
                                                                          onTap:
                                                                              () async {
                                                                            DateTime? pickedDate = await showDatePicker(
                                                                              context: context,
                                                                              initialDate: DateTime.now(),
                                                                              firstDate: DateTime.now(),
                                                                              lastDate: DateTime(2100),
                                                                            );
                                                                            if (pickedDate != null) {
                                                                              setState(() {
                                                                                selectedDateText = pickedDate.toString();
                                                                                dateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
                                                                              });
                                                                            }
                                                                          },
                                                                          decoration:
                                                                              InputDecoration(
                                                                            hintText: selectedDateText ?? 'Select Date',
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                  height: 20),
                                                              ElevatedButton(
                                                                onPressed:
                                                                    () {
                                                                  String?
                                                                      selectedDate =
                                                                      selectedDateText;
                                                                  print(
                                                                      'Selected Date: $selectedDate');
                                                                  Navigator.of(
                                                                          context)
                                                                      .pop();
                                                                },
                                                                style:
                                                                ButtonStyle(
                                                                  backgroundColor:
                                                                  MaterialStateProperty.all<
                                                                      Color>(
                                                                      Color(
                                                                          0xFF008955)),
                                                                  minimumSize:
                                                                  MaterialStateProperty
                                                                      .all<
                                                                      Size>(
                                                                    Size(250,
                                                                        40), // Change the width (and height) as needed
                                                                  ),
                                                                ),
                                                                child: Text(
                                                                  'Add',
                                                                  style:
                                                                      TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontFamily:
                                                                        'Poppins',
                                                                    fontSize:
                                                                        14,
                                                                  ),
                                                                  textAlign:
                                                                      TextAlign
                                                                          .left,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Color(0xffe2f5ed),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              // padding: EdgeInsets.fromLTRB(4, 5, 5, 5)
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 15),
                                            ),
                                            icon: Icon(
                                              Icons.calendar_month,
                                              color: Colors.grey,
                                            ),
                                            label: Text(
                                              'Travel Days',
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontFamily: 'Poppins',
                                                fontSize: 14,
                                              ),
                                              textAlign: TextAlign.left,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 15),
                                        // Sixth modal
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              showModalBottomSheet(
                                                isScrollControlled: true,
                                                backgroundColor:
                                                    Color.fromARGB(
                                                        0, 255, 255, 255),
                                                context: context,
                                                builder:
                                                    (BuildContext context) {
                                                  return Container(
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .height *
                                                            0.8,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.only(
                                                        topLeft:
                                                            Radius.circular(
                                                                30),
                                                        topRight:
                                                            Radius.circular(
                                                                30),
                                                      ),
                                                    ),
                                                    child: Column(
                                                      children: [
                                                        Align(
                                                          alignment: Alignment
                                                              .topRight,
                                                          child: IconButton(
                                                            icon: Icon(
                                                              Icons
                                                                  .keyboard_arrow_down_outlined,
                                                              color: Colors
                                                                  .black,
                                                            ),
                                                            onPressed: () {
                                                              Navigator.of(
                                                                      context)
                                                                  .pop();
                                                            },
                                                          ),
                                                        ),
                                                        Container(
                                                          width:
                                                              double.infinity,
                                                          alignment: Alignment
                                                              .center,
                                                          child: Column(
                                                            children: [
                                                              Divider(
                                                                color: Colors
                                                                    .grey,
                                                                thickness:
                                                                    4.0,
                                                                height: 0.0,
                                                                indent: 85.0,
                                                                endIndent:
                                                                    85.0,
                                                              ),
                                                              SizedBox(
                                                                  height: 8),
                                                              SelectVehicle(
                                                                  controller:
                                                                      vehicleSelectController),
                                                              SizedBox(
                                                                  height: 20),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Color(0xffe2f5ed),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              padding: EdgeInsets.fromLTRB(
                                                  4, 5, 5, 5),
                                            ),
                                            icon: Icon(
                                              Icons.car_rental,
                                              color: Colors.grey,
                                            ),
                                            label: Text(
                                              'Vehicle',
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontFamily: 'Poppins',
                                                fontSize: 14,
                                              ),
                                              textAlign: TextAlign.left,
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                  
                          ElevatedButton(
                            onPressed: () async {
                              globalMatchedRideIds.matchedRideIds.clear();
                              globalMatchedRideIds.matchedUserIds.clear();
                              passengerRideData.rideSourceLatitude = 0.0;
                              passengerRideData.rideSourceLongitude = 0.0;
                              passengerRideData.rideDestinationLatitude = 0.0;
                              passengerRideData.rideDestinationLongitude = 0.0;
                  
                              String noOfperson = personsController.text;
                              print('Pass : $personsController.text');
                              int? noOfPassenger = int.tryParse(noOfperson);
                              print("No of Pass: $noOfPassenger");
                              if (noOfPassenger == null) {
                                print("Invalid number of passengers");
                                return;
                              }
                              passengerRideData.noOfPassengers.clear();
                              passengerRideData.noOfPassengers.add(noOfPassenger);
                              print(
                                  "No pass: ${passengerRideData.noOfPassengers}");
                              double? sourcelatitudeNullable =
                                  sourceLocationCoordinates?['latitude'];
                              double? sourcelongitudeNullable =
                                  sourceLocationCoordinates?['longitude'];
                              double? destinationlatitudeNullable =
                                  destinationLocationCoordinates?['latitude'];
                              double? destinationlongitudeNullable =
                                  destinationLocationCoordinates?['longitude'];
                  
                              if (sourcelatitudeNullable == null ||
                                  sourcelongitudeNullable == null ||
                                  destinationlongitudeNullable == null ||
                                  destinationlatitudeNullable == null) {
                                print(
                                    "Source or destination coordinates are null");
                                return;
                              }
                  
                              DateTime? dateTime;
                  
                              print("Fetching matched rides...");
                              RideDataProvider rideDataProvider =
                                  RideDataProvider(
                                passengerSourceLatitude: sourcelatitudeNullable,
                                passengerSourceLongitude: sourcelongitudeNullable,
                                passengerDestinationLatitude:
                                    destinationlatitudeNullable,
                                passengerDestinationLongitude:
                                    destinationlongitudeNullable,
                                vehicleType: vehicleSelectController.text,
                                dateTime: dateTime,
                              );
                              List<loc.Marker> matchedRides =
                                  await RideDataProvider(
                                passengerSourceLatitude: sourcelatitudeNullable,
                                passengerSourceLongitude: sourcelongitudeNullable,
                                passengerDestinationLatitude:
                                    destinationlatitudeNullable,
                                passengerDestinationLongitude:
                                    destinationlongitudeNullable,
                                vehicleType: vehicleSelectController.text,
                                dateTime: dateTime,
                              ).fetchRidesWithin3km(
                                passengerSourceLatitude: sourcelatitudeNullable,
                                passengerSourceLongitude: sourcelongitudeNullable,
                                passengerDestinationLatitude:
                                    destinationlatitudeNullable,
                                passengerDestinationLongitude:
                                    destinationlongitudeNullable,
                                dateTime: dateTime,
                                vehicleType: vehicleSelectController.text,
                              );
                              print(
                                  "PassVehcleTp${vehicleSelectController.text}");
                  
                              print(
                                  "GlobalMatchedRideIDsssss: ${globalMatchedRideIds.matchedRideIds}");
                              print(
                                  "GlobalMatchedUserID: ${globalMatchedRideIds.matchedUserIds}");
                              List<String> deepCopyMatchedRideIds =
                                  List<String>.from(
                                      globalMatchedRideIds.matchedRideIds);
                              List<String> deepCopyMatchedUserIds =
                                  List<String>.from(
                                      globalMatchedRideIds.matchedUserIds);
                  
                              Future.delayed(Duration(seconds: 3), () {
                                if (deepCopyMatchedRideIds.isNotEmpty) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AvailableRides(
                                        availableRides: matchedRides,
                                        matchedRideIds: deepCopyMatchedRideIds,
                                        userIds: deepCopyMatchedUserIds,
                                        documentName: docRef,
                                        vehicleType: vehicleSelectController.text,
                                      ),
                                    ),
                                  );
                                } else {
                                  print("No matched rides found");
                                }
                              });
                  
                              storeDataInFirestore(
                                vehicleSelectController: vehicleSelectController,
                                sourceController: sourceController,
                                destinationController: destinationController,
                                dateController: dateController,
                                timeController: timeController,
                                personsController: personsController,
                                sourceLocationCoordinates:
                                    sourceLocationCoordinates,
                                destinationLocationCoordinates:
                                    destinationLocationCoordinates,
                              );
                            },
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  Color(0xFF008955)),
                              minimumSize: MaterialStateProperty.all<Size>(
                                Size(250,
                                    40), // Change the width (and height) as needed
                              ),
                            ),
                            child: Text(
                              'Ride',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Poppins',
                                fontSize: 14, // Set the text color
                              ),
                              textAlign:
                                  TextAlign.left, // Align the text to the left
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: AnimatedDownBar(
              userType: 'passenger',
              screenNo: 0,
            ),
          )),
        ));
  }

  void storeDataInFirestore({
    required TextEditingController sourceController,
    required TextEditingController destinationController,
    required TextEditingController dateController,
    required TextEditingController timeController,
    required TextEditingController personsController,
    required TextEditingController vehicleSelectController,
    Map<String, double>? sourceLocationCoordinates,
    Map<String, double>? destinationLocationCoordinates,
  }) async {
    try {
      // Access Firebase Firestore instance
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      User? currentUser = FirebaseAuth.instance.currentUser;
      String? userId = currentUser?.uid;

      // Create a map to hold the data to be stored in Firestore
      Map<String, dynamic> data = {
        'source': sourceController.text,
        'destination': destinationController.text,
        'date': dateController.text,
        'time': timeController.text,
        'persons': personsController.text,
        'vehicle': vehicleSelectController.text,
        'userId': userId,
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

      // Add data to Firestore collection and get the document reference
      docRef = await firestore.collection('passengerride').add(data);

      // Show success message and print document ID
      print('Data stored successfully in Firestore! Document ID: ${docRef.id}');
    } catch (error) {
      // Show error message
      print('Error storing data in Firestore: $error');
    }
  }

  void fetchDataAndNavigate(BuildContext context) async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      DocumentSnapshot userSnapshot =
          await firestore.collection('users').doc(userId).get();
      print("user snapshot: $userSnapshot");
      if (userSnapshot.exists) {
        Map<String, dynamic> userData =
            userSnapshot.data() as Map<String, dynamic>;
        bool isDriver = userData['isDriver'];
        print("IsDriver $isDriver");
        if (isDriver == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => driverHome()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => Vehicle()),
          );
        }
      } else {
        print('No such document!');
      }
    } catch (error) {
      print('Error fetching data: $error');
    }
  }
}
