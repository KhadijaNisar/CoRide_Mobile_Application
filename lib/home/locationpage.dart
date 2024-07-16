import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hitchify/home/home_screen.dart';

void main() {
  runApp(MaterialApp(home: LocationAccess()));
}

class LocationAccess extends StatefulWidget {
  const LocationAccess({Key? key}) : super(key: key);

  @override
  State<LocationAccess> createState() => _LocationAccessState();
}

class _LocationAccessState extends State<LocationAccess> {
  Future<void> _requestLocationPermission(BuildContext context) async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      // Location permission granted, handle the logic here
      print('Location permission granted');
    } else {
      // Location permission denied, handle the logic here
      print('Location permission denied');
    }
    await Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => HomeScreen(),
      ),(route)=>false
    );
    // await Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (BuildContext context) => HomeScreen(),
    //   ),
    // );
  }

  void _skipForNow(BuildContext context) async {
    // Navigate to the next screen or perform any desired action
    print('Skipping for now');
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => HomeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SafeArea(
          child: Scaffold(
            body: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/Map.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Center(
                child: Container(
                  width: 340,
                  height: 340,
                  padding: EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 30,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0XFF8AD4B5),
                          ),
                          child: Icon(
                            Icons.location_on,
                            size: 30,
                            color: Colors.black,
                          ),
                        ),
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Color(0XFFB9E5D1),
                              width: 4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Text(
                      "Enable your Location",
                      style: TextStyle(
                          fontFamily: 'Poppins', fontWeight: FontWeight.bold),
                    ),
                    Text(
                        "Choose your location to start find the request around you",
                        style: TextStyle(fontFamily: 'Poppins'),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => _requestLocationPermission(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0XFF08B783),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.0),
                        ), // Set the background color
                      ),
                      child: Text(
                        'Use My Location',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateColor.resolveWith(
                            (states) => Colors.white),
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                        ),
                      ),
                      onPressed: () => _skipForNow(context),
                      child: Text(
                        'Skip for now',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Poppins',
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ));
  }
}
