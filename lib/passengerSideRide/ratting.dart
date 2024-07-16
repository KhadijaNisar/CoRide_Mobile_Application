import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RateRide extends StatelessWidget {
  const RateRide({Key? key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50),
        child: Container(
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
            title: Align(alignment: Alignment.topRight, child: Text("cancel")),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background map image
          Image.asset(
            'assets/images/Map.png',
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
                      "Rate the Ride",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18.0,
                      ),
                    ),
                  ),
                  SizedBox(height: 20.0),
                  // Rating stars
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star, color: Colors.yellow),
                      Icon(Icons.star, color: Colors.yellow),
                      Icon(Icons.star, color: Colors.yellow),
                      Icon(Icons.star, color: Colors.yellow),
                      Icon(Icons.star, color: Colors.yellow),
                    ],
                  ),
                  SizedBox(height: 20.0),
                  // Review text field
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Write a review...",
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Colors.black12), // Set the border color here
                      ),
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: 20.0),
                  // Submit button
                  SizedBox(
                    height: 50.0, // Set the height of the button
                    child: ElevatedButton(
                      onPressed: () {
                        // Implement complete ride functionality
                      },
                      child: Text(
                        "Submit",
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
    );
  }
}
