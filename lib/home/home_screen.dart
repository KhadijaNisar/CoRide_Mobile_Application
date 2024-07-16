import 'dart:async';
import 'package:double_back_to_close_app/double_back_to_close_app.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hitchify/Assistants/assistant_method.dart';
import 'package:hitchify/home/nav_bar.dart';
import 'package:action_slider/action_slider.dart';
import 'package:hitchify/home/animated_downbar.dart';
import 'package:hitchify/home/timepicker.dart';
import 'package:hitchify/home/bookingPerson.dart';
import 'package:hitchify/home/datepicker.dart';
import 'package:hitchify/vehicle.dart';
import 'package:location/location.dart' as loc;
import 'package:hitchify/fuelPriceCal.dart';
import 'package:flutter/services.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:geocoding/platform.dart';
import 'package:location/location.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:hitchify/global/map_key.dart';

void main() {

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: HomeScreen(),
  ));
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>

    with SingleTickerProviderStateMixin {
  final Completer<GoogleMapController> _controller = Completer();

  static const LatLng srcLocation =
  LatLng(31.45725697261883, 73.15453226904458);
  static const LatLng destLocation =
  LatLng(31.376427711911038, 73.06324943511385);

  List<LatLng> polylineCoordinates = [];
  LocationData? currentLocation;

  Location location = Location();



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


  // @override
  // void initState() {
  //   super.initState();
  //   _initMap();
  // }
  @override
  void initState() {
    super.initState();
    _initMap();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _selectedTime = TimeOfDay.now();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    if (_isDriverMode) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
    setState(() {
      _isDriverMode = !_isDriverMode;
    });
  }

  Color _toggleColor() {
    return _isDriverMode ? Color(0xff52c498) : Color(0x7744C393);
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
  String? petrolPrice;
  @override
  DateTime? currentBackPressTime;
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
    return WillPopScope(
      onWillPop: () async {
        bool exit = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Exit App'),
              content: Text('Are you sure you want to exit?'),
              actions: <Widget>[
                TextButton(
                  child: Text('No'),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                TextButton(
                  child: Text('Yes'),
                  onPressed: () {
                    // Navigator.of(context).pop(true);
                    SystemChannels.platform.invokeMethod('SystemNavigator.pop');
                  },
                ),
              ],
            );
          },
        );
        return exit;
      },
      child: MaterialApp(
          debugShowCheckedModeBanner: false,
        home: SafeArea(
          child: Scaffold(
            extendBodyBehindAppBar: true,
            key: _scaffoldKey,
            drawer: NavBar(),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Builder(
                  builder: (context) {
                    return Container(
                      height: 100,
                      // decoration: BoxDecoration(
                      //   image: DecorationImage(
                      //     image: AssetImage('assets/images/Map.png'),
                      //     fit: BoxFit.cover,
                      //   ),
                      // ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ActionSlider.standard(
                            sliderBehavior: SliderBehavior.stretch,
                            height: 45,
                            width: 200.0,
                            backgroundColor: Colors.white,
                            toggleColor: _toggleColor(),
                            action: (controller) {
                              _toggleMode();
                              Navigator.push(context,MaterialPageRoute(builder: (context)=>Vehicle()));
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: Text(
                                _isDriverMode ? 'Driver Mode' : 'Passenger Mode',
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              actions: [ // Move the actions property inside the AppBar widget
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
                Positioned.fill(
                  child: currentLocation == null
                      ? Center(child: CircularProgressIndicator())
                      : GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
                      zoom: 14.5,
                    ),
                    polylines: {
                      Polyline(
                        polylineId: PolylineId("route"),
                        points: polylineCoordinates,
                        color: Colors.green,
                        width: 6,
                      ),
                    },
                    markers: {
                      Marker(
                        markerId: MarkerId("Current Location"),
                        position: LatLng(
                          currentLocation!.latitude!,
                          currentLocation!.longitude!,
                        ),
                      ),
                      Marker(
                        markerId: MarkerId("Destination"),
                        position: destLocation,
                      ),
                      Marker(
                        markerId: MarkerId("Source"),
                        position: srcLocation,
                      ),
                    },
                    onMapCreated: (mapController) {
                      _controller.complete(mapController);
                    },
                  ),
                ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 200,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 50, 8, 0),
                          child: Positioned(
                            // top: 100,
                            bottom: 10,
                            // Adjust the value to position the white bo
                            left: 80,
                            right: 80,
                            child: Container(
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
                              child: Column(
                                // mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      showModalBottomSheet(
                                          scrollControlDisabledMaxHeightRatio: 10,
                                          backgroundColor:
                                          Color.fromARGB(0, 255, 255, 255),
                                          context: _scaffoldKey.currentState!.context,
                                          builder: (BuildContext Context) {
                                            return Container(
                                              // height: 400,
                                              height:
                                              MediaQuery.of(context).size.height *
                                                  0.8,
                                              decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.only(
                                                      topLeft: Radius.circular(30),
                                                      topRight: Radius.circular(30))),
                                              child: Column(
                                                children: [
                                                  Align(
                                                    alignment: Alignment.topRight,
                                                    child: IconButton(
                                                      icon: Icon(
                                                        Icons
                                                            .keyboard_arrow_down_outlined,
                                                        color: Colors.black,
                                                      ),
                                                      onPressed: () {
                                                        Navigator.of(Context).pop();
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
                                                          'Select PickUp Location',
                                                          style: TextStyle(
                                                              color: Colors.black,
                                                              fontFamily: 'Poppins',
                                                              fontSize:
                                                              18 // Set the text color
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
                                                          padding: const EdgeInsets
                                                              .symmetric(
                                                              horizontal: 8.0),
                                                          child: Container(
                                                            decoration: BoxDecoration(
                                                              borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
                                                              border: Border.all(
                                                                color: Colors.grey,
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
                                                                    color:
                                                                    Colors.grey,
                                                                  ),
                                                                ),
                                                                Expanded(
                                                                  child: TextField(
                                                                    decoration:
                                                                    InputDecoration(
                                                                      border:
                                                                      InputBorder
                                                                          .none,
                                                                      hintText:
                                                                      'Enter your name',
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding: const EdgeInsets
                                                              .fromLTRB(0, 8, 8, 8),
                                                          child: Text(
                                                            'Recent Places',
                                                            style: TextStyle(
                                                                fontSize: 18,
                                                                fontFamily:
                                                                'Poppins'),
                                                          ),
                                                        ),
                                                        ListTile(
                                                          leading:
                                                          Icon(Icons.location_on),
                                                          title: Text('Place 1'),
                                                        ),
                                                        ListTile(
                                                          leading:
                                                          Icon(Icons.location_on),
                                                          title: Text('Place 2'),
                                                        ),
                                                        ListTile(
                                                          leading:
                                                          Icon(Icons.location_on),
                                                          title: Text('Place 3'),
                                                        ),
                                                        ElevatedButton(
                                                          onPressed: () => {
                                                            Navigator.of(Context)
                                                                .pop()
                                                          },
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                            backgroundColor:
                                                            Color(0xff008955),
                                                            // Set the background color
                                                            shape:
                                                            RoundedRectangleBorder(
                                                              borderRadius:
                                                              BorderRadius.circular(
                                                                  8), // Set the border radius
                                                            ),
                                                            padding:
                                                            EdgeInsets.fromLTRB(
                                                                11, 6, 15, 6),
                                                          ),
                                                          child: Text(
                                                            'Add',
                                                            style: TextStyle(
                                                              color: Colors.white,
                                                              fontFamily: 'Poppins',
                                                              fontSize:
                                                              14, // Set the text color
                                                            ),
                                                            textAlign: TextAlign
                                                                .left, // Align the text to the left
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          });
                                    },
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xffe2f5ed),
                                        // Set the background color
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              8), // Set the border radius
                                        ),
                                        padding: EdgeInsets.symmetric(horizontal: 50)),
                                    // padding: EdgeInsets.fromLTRB(4, 5, 95, 5)),
                                    icon: Icon(
                                      Icons.search,
                                      color: Colors.grey, // Set the icon color
                                    ),
                                    label: Text(
                                      'Pick Up Location',
                                      style: TextStyle(
                                          color: Colors.grey,
                                          fontFamily: 'Poppins',
                                          fontSize: 14 // Set the text color
                                      ),
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      showModalBottomSheet(
                                          scrollControlDisabledMaxHeightRatio: 10,
                                          backgroundColor:
                                          Color.fromARGB(0, 255, 255, 255),
                                          context: _scaffoldKey.currentState!.context,
                                          builder: (BuildContext Context) {
                                            return Container(
                                              // height: 400,
                                              height:
                                              MediaQuery.of(context).size.height *
                                                  0.8,
                                              decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.only(
                                                      topLeft: Radius.circular(30),
                                                      topRight: Radius.circular(30))),
                                              child: Column(
                                                children: [
                                                  Align(
                                                    alignment: Alignment.topRight,
                                                    child: IconButton(
                                                      icon: Icon(
                                                        Icons
                                                            .keyboard_arrow_down_outlined,
                                                        color: Colors.black,
                                                      ),
                                                      onPressed: () {
                                                        Navigator.of(Context).pop();
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
                                                              fontFamily: 'Poppins',
                                                              fontSize:
                                                              18 // Set the text color
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
                                                          padding: const EdgeInsets
                                                              .symmetric(
                                                              horizontal: 8.0),
                                                          child: Container(
                                                            decoration: BoxDecoration(
                                                              borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
                                                              border: Border.all(
                                                                color: Colors.grey,
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
                                                                    color:
                                                                    Colors.grey,
                                                                  ),
                                                                ),
                                                                Expanded(
                                                                  child: TextField(
                                                                    decoration:
                                                                    InputDecoration(
                                                                      border:
                                                                      InputBorder
                                                                          .none,
                                                                      hintText:
                                                                      'Enter your name',
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding: const EdgeInsets
                                                              .fromLTRB(0, 8, 8, 8),
                                                          child: Text(
                                                            'Recent Places',
                                                            style: TextStyle(
                                                                fontSize: 18,
                                                                fontFamily:
                                                                'Poppins'),
                                                          ),
                                                        ),
                                                        ListTile(
                                                          leading:
                                                          Icon(Icons.location_on),
                                                          title: Text('Place 1'),
                                                        ),
                                                        ListTile(
                                                          leading:
                                                          Icon(Icons.location_on),
                                                          title: Text('Place 2'),
                                                        ),
                                                        ListTile(
                                                          leading:
                                                          Icon(Icons.location_on),
                                                          title: Text('Place 3'),
                                                        ),
                                                        ElevatedButton(
                                                          onPressed: () => {
                                                            Navigator.of(Context)
                                                                .pop()
                                                          },
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                            backgroundColor:
                                                            Color(0xff008955),
                                                            // Set the background color
                                                            shape:
                                                            RoundedRectangleBorder(
                                                              borderRadius:
                                                              BorderRadius.circular(
                                                                  8), // Set the border radius
                                                            ),
                                                            padding:
                                                            EdgeInsets.fromLTRB(
                                                                11, 6, 15, 6),
                                                          ),
                                                          child: Text(
                                                            'Add',
                                                            style: TextStyle(
                                                              color: Colors.white,
                                                              fontFamily: 'Poppins',
                                                              fontSize:
                                                              14, // Set the text color
                                                            ),
                                                            textAlign: TextAlign
                                                                .left, // Align the text to the left
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          });
                                    },
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xffe2f5ed),
                                        // Set the background color
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              8), // Set the border radius
                                        ),
                                        // padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                                        // padding: EdgeInsets.fromLTRB(4, 5, 48, 5)),
                                        padding: EdgeInsets.symmetric(horizontal: 27)),
                                    icon: Icon(
                                      Icons.search,
                                      color: Colors.grey, // Set the icon color
                                    ),
                                    label: Text(
                                      'Where Would You Go?',
                                      style: TextStyle(
                                          color: Colors.grey,
                                          fontFamily: 'Poppins',
                                          fontSize: 14 // Set the text color
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding:  EdgeInsets.symmetric(horizontal: 15),
                                    child: Row(
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            showModalBottomSheet(
                                                scrollControlDisabledMaxHeightRatio: 10,
                                                backgroundColor: Colors.white,
                                                context:
                                                _scaffoldKey.currentState!.context,
                                                builder: (BuildContext Context) {
                                                  return Container(
                                                    // height: 400,
                                                    height: MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                        0.8,
                                                    decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius: BorderRadius.only(
                                                            topLeft:
                                                            Radius.circular(30),
                                                            topRight:
                                                            Radius.circular(30))),
                                                    child: Column(
                                                      children: [
                                                        Align(
                                                          alignment: Alignment.topRight,
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
                                                                'Chose Date and Time',
                                                                style: TextStyle(
                                                                    color: Colors.black,
                                                                    fontFamily:
                                                                    'Poppins',
                                                                    fontSize:
                                                                    18 // Set the text color
                                                                ),
                                                              ),
                                                              Divider(
                                                                color: Colors.grey,
                                                                thickness: 1.0,
                                                                height: 12.0,
                                                                indent: 0.0,
                                                                endIndent: 0.0,
                                                              ),
                                                              SizedBox(
                                                                height: 10,
                                                              ),
                                                              TimePickerWidget(
                                                                key: UniqueKey(),
                                                                // Add a unique key
                                                                initialTime:
                                                                TimeOfDay.now(),
                                                                onTimeSelected:
                                                                    (selectedTime) {
                                                                  // Handle the selected time
                                                                  print(
                                                                      'Selected Time: $selectedTime');
                                                                  // You can perform any additional actions with the selected time here
                                                                },
                                                              ),
                                                              ElevatedButton(
                                                                onPressed: () => {
                                                                  Navigator.of(Context)
                                                                      .pop()
                                                                },
                                                                style: ElevatedButton
                                                                    .styleFrom(
                                                                  backgroundColor:
                                                                  Color(0xff008955),
                                                                  // Set the background color
                                                                  shape:
                                                                  RoundedRectangleBorder(
                                                                    borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                        8), // Set the border radius
                                                                  ),
                                                                  padding: EdgeInsets
                                                                      .fromLTRB(
                                                                      11, 6, 15, 6),
                                                                ),
                                                                child: Text(
                                                                  'Add',
                                                                  style: TextStyle(
                                                                    color: Colors.white,
                                                                    fontFamily:
                                                                    'Poppins',
                                                                    fontSize:
                                                                    14, // Set the text color
                                                                  ),
                                                                  textAlign: TextAlign
                                                                      .left, // Align the text to the left
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                });
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Color(0xffe2f5ed),
                                            // Set the background color
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(
                                                  8), // Set the border radius
                                            ),
                                            // padding: EdgeInsets.fromLTRB(4, 5, 5, 5),
                                            //   padding: EdgeInsets.symmetric(horizontal: 5),
                                          ),
                                          icon: Icon(
                                            Icons.calendar_month,
                                            color: Colors.grey, // Set the icon color
                                          ),
                                          label: Text(
                                            'Date  ',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontFamily: 'Poppins',
                                              fontSize: 14, // Set the text color
                                            ),
                                            textAlign: TextAlign
                                                .left, // Align the text to the left
                                          ),
                                        ),
                                        SizedBox(width: 32),
                                        // Add some spacing between the buttons
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            showModalBottomSheet(
                                                scrollControlDisabledMaxHeightRatio: 10,
                                                backgroundColor:
                                                Color.fromARGB(0, 255, 255, 255),
                                                context:
                                                _scaffoldKey.currentState!.context,
                                                builder: (BuildContext Context) {
                                                  return Container(
                                                    // height: 400,
                                                    height: MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                        0.8,
                                                    decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius: BorderRadius.only(
                                                            topLeft:
                                                            Radius.circular(30),
                                                            topRight:
                                                            Radius.circular(30))),
                                                    child: Column(
                                                      children: [
                                                        Align(
                                                          alignment: Alignment.topRight,
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
                                                                'Select No. of Persons',
                                                                style: TextStyle(
                                                                    color: Colors.black,
                                                                    fontFamily:
                                                                    'Poppins',
                                                                    fontSize:
                                                                    18 // Set the text color
                                                                ),
                                                              ),
                                                              Divider(
                                                                color: Colors.grey,
                                                                thickness: 1.0,
                                                                height: 12.0,
                                                                indent: 0.0,
                                                                endIndent: 0.0,
                                                              ),
                                                              BookingModal(),
                                                              ElevatedButton(
                                                                onPressed: () => {
                                                                  Navigator.of(Context)
                                                                      .pop()
                                                                },
                                                                style: ElevatedButton
                                                                    .styleFrom(
                                                                  backgroundColor:
                                                                  Color(0xff008955),
                                                                  // Set the background color
                                                                  shape:
                                                                  RoundedRectangleBorder(
                                                                    borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                        8), // Set the border radius
                                                                  ),
                                                                  padding: EdgeInsets
                                                                      .fromLTRB(
                                                                      11, 6, 15, 6),
                                                                ),
                                                                child: Text(
                                                                  'Add',
                                                                  style: TextStyle(
                                                                    color: Colors.white,
                                                                    fontFamily:
                                                                    'Poppins',
                                                                    fontSize:
                                                                    14, // Set the text color
                                                                  ),
                                                                  textAlign: TextAlign
                                                                      .left, // Align the text to the left
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                });
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Color(0xffe2f5ed),
                                            // Set the background color
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(
                                                  8), // Set the border radius
                                            ),
                                            padding: EdgeInsets.fromLTRB(5, 5, 12, 5),
                                            // padding: EdgeInsets.only(left:5)
                                          ),
                                          icon: Icon(
                                            Icons.person,
                                            color: Colors.grey, // Set the icon color
                                          ),
                                          label: Text(
                                            'Persons',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontFamily: 'Poppins',
                                              fontSize: 14, // Set the text color
                                            ),
                                            textAlign: TextAlign
                                                .left, // Align the text to the left
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 5),
                                    child: Row(
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            showModalBottomSheet(
                                                scrollControlDisabledMaxHeightRatio: 10,
                                                backgroundColor:
                                                Color.fromARGB(0, 255, 255, 255),
                                                context:
                                                _scaffoldKey.currentState!.context,
                                                builder: (BuildContext Context) {
                                                  return Container(
                                                    // height: 400,
                                                    height: MediaQuery.of(context)
                                                        .size
                                                        .height *
                                                        0.8,
                                                    decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius: BorderRadius.only(
                                                            topLeft:
                                                            Radius.circular(30),
                                                            topRight:
                                                            Radius.circular(30))),
                                                    child: Column(
                                                      children: [
                                                        Align(
                                                          alignment: Alignment.topRight,
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
                                                                'Select No. of Persons',
                                                                style: TextStyle(
                                                                    color: Colors.black,
                                                                    fontFamily:
                                                                    'Poppins',
                                                                    fontSize:
                                                                    18 // Set the text color
                                                                ),
                                                              ),
                                                              Divider(
                                                                color: Colors.grey,
                                                                thickness: 1.0,
                                                                height: 12.0,
                                                                indent: 0.0,
                                                                endIndent: 0.0,
                                                              ),
                                                              DatePickerModal(),
                                                              ElevatedButton(
                                                                onPressed: () => {
                                                                  Navigator.of(Context)
                                                                      .pop()
                                                                },
                                                                style: ElevatedButton
                                                                    .styleFrom(
                                                                  backgroundColor:
                                                                  Color(0xff008955),
                                                                  // Set the background color
                                                                  shape:
                                                                  RoundedRectangleBorder(
                                                                    borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                        8), // Set the border radius
                                                                  ),
                                                                  padding: EdgeInsets
                                                                      .fromLTRB(
                                                                      11, 6, 15, 6),
                                                                ),
                                                                child: Text(
                                                                  'Add',
                                                                  style: TextStyle(
                                                                    color: Colors.white,
                                                                    fontFamily:
                                                                    'Poppins',
                                                                    fontSize:
                                                                    14, // Set the text color
                                                                  ),
                                                                  textAlign: TextAlign
                                                                      .left, // Align the text to the left
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                });
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Color(0xffe2f5ed),
                                            // Set the background color
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(
                                                  8), // Set the border radius
                                            ),
                                            padding: EdgeInsets.fromLTRB(4, 5, 5, 5),
                                          ),
                                          icon: Icon(
                                            Icons.calendar_month,
                                            color: Colors.grey, // Set the icon color
                                          ),
                                          label: Text(
                                            'Travel Days',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontFamily: 'Poppins',
                                              fontSize: 14, // Set the text color
                                            ),
                                            textAlign: TextAlign
                                                .left, // Align the text to the left
                                          ),
                                        ),
                                        SizedBox(width: 40),
                                        // Add some spacing between the buttons
                                        ElevatedButton(
                                          onPressed: () => (),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Color(0xff008955),
                                            // Set the background color
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(
                                                  8), // Set the border radius
                                            ),
                                            padding: EdgeInsets.fromLTRB(25, 6, 23, 6),
                                          ),
                                          child: Text(
                                            'Ride',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontFamily: 'Poppins',
                                              fontSize: 14, // Set the text color
                                            ),
                                            textAlign: TextAlign
                                                .left, // Align the text to the left
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                bottomNavigationBar: AnimatedDownBar(),
              ))),
    );
  }
}






