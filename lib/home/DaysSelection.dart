import 'package:flutter/material.dart';

class DaysSelection extends StatefulWidget {
  final TextEditingController controller;

  const DaysSelection({Key? key, required this.controller}) : super(key: key);

  @override
  _DaysSelectionState createState() => _DaysSelectionState();
}

class _DaysSelectionState extends State<DaysSelection> {
  List<String> selectedDays = []; // Store selected days

  @override
  void initState() {
    super.initState();
    widget.controller.text =
        selectedDays.join(', '); // Display selected days in the text field
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
                Text(
                  'Select Days',
                  style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'Poppins',
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
                SingleChildScrollView(
                  child: Column(
                    children: [
                      CheckboxListTile(
                        title: Text('Monday'),
                        value: selectedDays.contains('Monday'),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value != null && value) {
                              selectedDays.add('Monday');
                            } else {
                              selectedDays.remove('Monday');
                            }
                            widget.controller.text = selectedDays.join(', ');
                          });
                        },
                      ),
                      CheckboxListTile(
                        title: Text('Tuesday'),
                        value: selectedDays.contains('Tuesday'),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value != null && value) {
                              selectedDays.add('Tuesday');
                            } else {
                              selectedDays.remove('Tuesday');
                            }
                            widget.controller.text = selectedDays.join(', ');
                          });
                        },
                      ),
                      CheckboxListTile(
                        title: Text('Wednesday'),
                        value: selectedDays.contains('Wednesday'),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value != null && value) {
                              selectedDays.add('Wednesday');
                            } else {
                              selectedDays.remove('Wednesday');
                            }
                            widget.controller.text = selectedDays.join(', ');
                          });
                        },
                      ),
                      CheckboxListTile(
                        title: Text('Thursday'),
                        value: selectedDays.contains('Thursday'),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value != null && value) {
                              selectedDays.add('Thursday');
                            } else {
                              selectedDays.remove('Thursday');
                            }
                            widget.controller.text = selectedDays.join(', ');
                          });
                        },
                      ),
                      CheckboxListTile(
                        title: Text('Friday'),
                        value: selectedDays.contains('Friday'),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value != null && value) {
                              selectedDays.add('Friday');
                            } else {
                              selectedDays.remove('Friday');
                            }
                            widget.controller.text = selectedDays.join(', ');
                          });
                        },
                      ),
                      CheckboxListTile(
                        title: Text('Saturday'),
                        value: selectedDays.contains('Saturday'),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value != null && value) {
                              selectedDays.add('Saturday');
                            } else {
                              selectedDays.remove('Saturday');
                            }
                            widget.controller.text = selectedDays.join(', ');
                          });
                        },
                      ),
                      CheckboxListTile(
                        title: Text('Sunday'),
                        value: selectedDays.contains('Sunday'),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value != null && value) {
                              selectedDays.add('Sunday');
                            } else {
                              selectedDays.remove('Sunday');
                            }
                            widget.controller.text = selectedDays.join(', ');
                          });
                        },
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Handle the selected days
                    print('Selected Days: $selectedDays');

                    // Dismiss the bottom sheet
                    Navigator.of(context).pop();
                  },
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Color(0xFF008955)),
                    minimumSize: MaterialStateProperty.all<Size>(
                      Size(250, 40), // Change the width (and height) as needed
                    ),
                  ),
                  child: Text(
                    'Add',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
