import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LocationShare extends StatelessWidget {
  const LocationShare({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
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
              backgroundColor: Color(0xFF66b899),
              title:
                  Align(alignment: Alignment.topRight, child: Text("cancel")),
            ),
          ),
        ),
        body: Stack(
          children: [
            // Background map image
            Image.asset(
              'images/map_image.png', // Replace with your map image asset
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
            // Fixed bottom sheet
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
                      spreadRadius: 1,
                      blurRadius: 2,
                      offset: Offset(-2, -2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Ride information
                    Center(
                      child: Text(
                        "Ongoing Ride",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.0,
                        ),
                      ),
                    ),
                    Divider(
                      color: Colors.black12,
                    ),
                    SizedBox(
                      height: 30.0,
                    ),
                    // Share Location
                    Row(children: [
                      IconButton(
                        icon: Icon(Icons.location_on),
                        onPressed: () {
                          // Implement share location functionality
                        },
                        iconSize: 30.0,
                        color: Color(0xFF08B783),
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        "Share Location",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                      Spacer(),
                      Text(
                        "123 Main St, City Name",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ]),
                    SizedBox(height: 16.0),
                    // Call Police
                    Row(children: [
                      IconButton(
                        icon: Icon(Icons.call),
                        onPressed: () {
                          // Implement call police functionality
                        },
                        iconSize: 30.0,
                        color: Color(0xFF08B783),
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        "Call Police",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                    ]),
                    SizedBox(height: 16.0),
                    // Complete Ride
                    SizedBox(
                      height: 50.0, // Set the height of the button
                      child: ElevatedButton(
                        onPressed: () {
                          // Implement complete ride functionality
                        },
                        child: Text(
                          "Complete Ride",
                          style: TextStyle(color: Colors.white, fontSize: 17.0),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF08B783),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
