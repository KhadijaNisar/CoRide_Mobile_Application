import 'package:flutter/material.dart';

class SelectVehicle extends StatefulWidget {
  final TextEditingController controller;

  const SelectVehicle({Key? key, required this.controller}) : super(key: key);

  @override
  _SelectVehicleState createState() => _SelectVehicleState();
}

class _SelectVehicleState extends State<SelectVehicle> {
  String selectedVehicle = 'Car'; // Default selected value

  @override
  void initState() {
    super.initState();
    widget.controller.text = selectedVehicle;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            alignment: Alignment.center,
            child: Column(
              children: [
                SizedBox(
                  height: 8,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.grey,
                        width: 1.0,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 40),
                      child: DropdownButtonFormField<String>(
                        value: selectedVehicle,
                        onChanged: (String? value) {
                          if (value != null) {
                            setState(() {
                              selectedVehicle =
                                  value; // Update selectedVehicle when an item is selected
                              widget.controller.text = selectedVehicle;
                            });
                          }
                        },
                        items: [
                          DropdownMenuItem(
                            value: 'Car',
                            child: Row(
                              children: [
                                Image.asset(
                                  'assets/images/Car.png',
                                  width: 24,
                                  height: 24,
                                ),
                                SizedBox(width: 8),
                                Text('Car'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Rickshaw',
                            child: Row(
                              children: [
                                Image.asset(
                                  'assets/images/Rickshaw.png',
                                  width: 24,
                                  height: 24,
                                ),
                                SizedBox(width: 8),
                                Text('Rickshaw'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Bike',
                            child: Row(
                              children: [
                                Image.asset(
                                  'assets/images/Bike.png',
                                  width: 24,
                                  height: 24,
                                ),
                                SizedBox(width: 8),
                                Text('Bike'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
