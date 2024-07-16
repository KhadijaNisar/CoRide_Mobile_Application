import 'package:flutter/material.dart';

class StartRide extends StatelessWidget {
  const StartRide({Key? key});

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
            // Small card above the map image
            Positioned(
              left: 10.0,
              right: 10.0,
              top: 16.0,
              child: Card(
                elevation: 4, // Add a bottom box shadow to the card
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Your driver is on the way\n5 minutes away',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                ),
              ),
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
                      color: Colors.black12
                          .withOpacity(0.2), // Adjust shadow color and opacity
                      spreadRadius: 1,
                      blurRadius: 2,
                      offset: Offset(-2, -2), // changes position of shadow
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Ride information
                    Text(
                      "Red MOTOR-BIKE Honda",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0,
                      ),
                    ),
                    Divider(
                      color: Colors.black12,
                    ),
                    SizedBox(
                      height: 30.0,
                    ),
                    // Driver information
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Driver image
                        CircleAvatar(
                          backgroundImage: AssetImage(
                              'assets/driver_image.jpg'), // Replace with your driver image asset
                          radius: 25.0,
                        ),
                        SizedBox(
                          width: 10.0,
                        ),
                        // Driver name
                        Text(
                          "Driver Name",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                          ),
                        ),
                        // Spacer
                        Spacer(),
                        // Chat icon
                        TextButton(
                            onPressed: () {},
                            style: ButtonStyle(
                              padding:
                                  MaterialStateProperty.all<EdgeInsetsGeometry>(
                                EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                              ),
                              backgroundColor: MaterialStateColor.resolveWith(
                                (states) => Color(0xFF08B783),
                              ),
                              foregroundColor: MaterialStateColor.resolveWith(
                                (states) => Colors.white,
                              ),
                              shape: MaterialStateProperty.all<
                                  RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  // You can also add a border if you want
                                  // side: BorderSide(color: Colors.green, width: 2),
                                ),
                              ),
                            ),
                            child: Text("Start Ride"))
                      ],
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
