import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hitchify/profile/driver_profile_screen.dart';
import 'package:hitchify/driverAndVehicleRegistration/register.dart';
import 'package:hitchify/global/validations.dart';
import 'package:hitchify/widgets/custom_outlined_button.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddNewVehicle extends StatefulWidget {
  var selectedVehicle;

  // const AddNewVehicle({Key? key}) : super(key: key);
  AddNewVehicle({Key? key, this.selectedVehicle}) : super(key: key);

  @override
  _AddNewVehicleState createState() => _AddNewVehicleState();
}

class _AddNewVehicleState extends State<AddNewVehicle> {
  String? _selectedBrand;
  String? _selectedModel;
  String? _registrationNumber;
  String? _selectedRegistrationYear;

  String? _selectedColor;
  File? _vehiclePhoto;
  File? _licensePhoto;
  File? _vehicleFile;
  String? _selectedVehicle;

  @override
  void initState() {
    super.initState();
    _selectedVehicle = widget.selectedVehicle;
    print("Selected: $widget.selectedVehicle");
    print("Select : $_selectedVehicle");
  }

  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final _storage = FirebaseStorage.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<void> _getImage(ImageSource source, Function(File) setImage) async {
    final pickedImage = await _picker.pickImage(source: source);
    if (pickedImage != null) {
      setImage(File(pickedImage.path));
    }
  }

  Future<String> _uploadImage(File image, String folderName) async {
    try {
      final ref = _storage
          .ref()
          .child('$folderName/${DateTime.now().millisecondsSinceEpoch}');
      final snapshot = await ref.putFile(image);
      final url = await snapshot.ref.getDownloadURL();
      return url;
    } catch (error) {
      throw error;
    }
  }

  Future<void> _saveDataAndNavigate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_vehiclePhoto == null ||
        _licensePhoto == null ||
        _vehicleFile == null) {
      // Ensure all required images are selected
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select all required images'),
        ),
      );
      return;
    }

    User? currentUser = FirebaseAuth.instance.currentUser;
    String? userId = currentUser?.uid;
    _formKey.currentState!.save();

    final vehicleData = {
      'brand': _selectedBrand,
      'model': _selectedModel,
      'color': _selectedColor,
      'registrationNumber': _registrationNumber,
      'registrationYear': _selectedRegistrationYear,
      'userId': userId,
      'vehicleType': _selectedVehicle,
      'vehicleStatus': 'requested',
    };

    final vehicleImageUrl =
        await _uploadImage(_vehiclePhoto!, 'vehicle_photos');
    final licenseImageUrl =
        await _uploadImage(_licensePhoto!, 'license_photos');
    final vehicleFileUrl = await _uploadImage(_vehicleFile!, 'vehicle_files');

    vehicleData['vehicleImageUrl'] = vehicleImageUrl;
    vehicleData['licenseImageUrl'] = licenseImageUrl;
    vehicleData['vehicleFileUrl'] = vehicleFileUrl;

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      String? userId = currentUser?.uid;

      if (userId != null) {
        // Create a new document in the "vehicleType" collection
        await FirebaseFirestore.instance
            .collection('vehicle_data')
            .add(vehicleData);

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Information added Successfully!'),
          duration: Duration(seconds: 2),
        ));

        // Navigate to the next screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DriverProfileScreen(userType: 'driver',)),
        );
      }
    } catch (error) {
      print('Error saving data: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    String _customBrandOption = '';
    TextEditingController _customBrandController = TextEditingController();
    return Scaffold(
      appBar: AppBar(title: Text('Add New Vehicle Form')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedBrand,
                    onChanged: (value) {
                      setState(() {
                        _selectedBrand = value!;
                      });
                    },
                    items: [
                      'Honda',
                      'Toyota',
                      'Suzuki',
                      'Kia',
                    ].map((brand) {
                      return DropdownMenuItem(
                        child: Text(brand),
                        value: brand,
                      );
                    }).toList(),
                    decoration: InputDecoration(
                      labelText: 'Brand',
                      fillColor: Color(0xbb8dd7bc),
                      filled: true,
                      labelStyle: TextStyle(color: Colors.black),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a brand';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10),
                  // DropdownButtonFormField<String>(
                  //   value: _selectedModel,
                  //   onChanged: (value) =>
                  //       setState(() => _selectedModel = value),
                  //   items: [
                  //     '2015',
                  //     '2016',
                  //     '2017',
                  //     '2018',
                  //     '2019',
                  //     '2020',
                  //     '2021',
                  //     '2022',
                  //     '2023',
                  //     '2024'
                  //   ]
                  //       .map((model) => DropdownMenuItem(
                  //             child: Text(model),
                  //             value: model,
                  //           ))
                  //       .toList(),
                  //   decoration: InputDecoration(
                  //     labelText: 'Model',
                  //     fillColor: Color(0xbb8dd7bc),
                  //     filled: true,
                  //     labelStyle: TextStyle(color: Colors.black),
                  //   ),
                  //   validator: (value) =>
                  //       value == null ? 'Please Enter model' : null,
                  // ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Model',
                      hintText: 'WagonR',
                      fillColor: Color(0xbb8dd7bc),
                      filled: true,
                      labelStyle: TextStyle(color: Colors.black),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter Model';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _selectedModel = value;
                    },
                  ),

                  SizedBox(height: 10),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Registration Number',
                      fillColor: Color(0xbb8dd7bc),
                      filled: true,
                      labelStyle: TextStyle(color: Colors.black),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter Registration Number';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _registrationNumber = value;
                    },
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Registration Year',
                      hintText: '2022',
                      fillColor: Color(0xbb8dd7bc),
                      filled: true,
                      labelStyle: TextStyle(color: Colors.black),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please Enter Registration Year';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _selectedRegistrationYear = value;
                    },
                  ),
                  SizedBox(height: 20),

                  // TextFormField(
                  //   decoration: InputDecoration(
                  //     labelText: 'Color',
                  //     fillColor: Color(0xbb8dd7bc),
                  //     filled: true,
                  //     labelStyle: TextStyle(color: Colors.black),
                  //   ),
                  //   validator: (color) {
                  //     int validationResult = validateColor(color);
                  //
                  //     if (validationResult == 1) {
                  //       return "Please enter a valid Color";
                  //     }
                  //
                  //     return null;
                  //   },
                  //   autovalidateMode: AutovalidateMode.onUserInteraction,
                  // ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Color',
                      fillColor: Color(0xbb8dd7bc),
                      filled: true,
                      labelStyle: TextStyle(color: Colors.black),
                    ),
                    validator: (color) {
                      if (color == null || color.isEmpty) {
                        return "Please enter a valid Color";
                      }
                      return null; // Return null if validation passes
                    },
                    onSaved: (value) {
                      _selectedColor = value;
                    },
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _getImage(
                        ImageSource.gallery, (image) => _vehiclePhoto = image),
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Color(0xbb8dd7bc)),
                      foregroundColor:
                          MaterialStateProperty.all<Color>(Colors.black),
                    ),
                    child: Text('Upload Vehicle Photo'),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _getImage(
                        ImageSource.gallery, (image) => _licensePhoto = image),
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Color(0xbb8dd7bc)),
                      foregroundColor:
                          MaterialStateProperty.all<Color>(Colors.black),
                    ),
                    child: Text('Upload License Photo'),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _getImage(
                        ImageSource.gallery, (image) => _vehicleFile = image),
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Color(0xbb8dd7bc)),
                      foregroundColor:
                          MaterialStateProperty.all<Color>(Colors.black),
                    ),
                    child: Text('Upload Vehicle File'),
                  ),
                  SizedBox(height: 20),
                  CustomOutlinedButton(
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        _saveDataAndNavigate();
                      }
                    },
                    text: 'Done',
                    height: 50,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// class _VehicleFormState extends State<VehicleForm> {
//   String? _selectedBrand;
//   String? _selectedModel;
//   String? _selectedColor;
//   File? _vehiclePhoto;
//   File? _licensePhoto;
//   File? _vehicleFile;
//
//   final _formKey = GlobalKey<FormState>();
//   final _picker = ImagePicker();
//   final _storage = FirebaseStorage.instance;
//   final _firestore = FirebaseFirestore.instance;
//
//   Future<void> _saveDataAndNavigate() async {
//     if (!_formKey.currentState!.validate()) {
//       return;
//     }
//
//     if (_vehiclePhoto == null ||
//         _licensePhoto == null ||
//         _vehicleFile == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Please select all required images'),
//         ),
//       );
//       return;
//     }
//
//     _formKey.currentState!.save();
//
//     final vehicleData = {
//       'brand': _selectedBrand,
//       'model': _selectedModel,
//       'color': _selectedColor,
//       'registrationNumber': _registrationNumber,
//     };
//
//     final vehicleImageUrl = await _uploadImage(_vehiclePhoto!, 'vehicle_photos');
//     final licenseImageUrl = await _uploadImage(_licensePhoto!, 'license_photos');
//     final vehicleFileUrl = await _uploadImage(_vehicleFile!, 'vehicle_files');
//
//     vehicleData['vehicleImageUrl'] = vehicleImageUrl;
//     vehicleData['licenseImageUrl'] = licenseImageUrl;
//     vehicleData['vehicleFileUrl'] = vehicleFileUrl;
//
//     try {
//       User? currentUser = FirebaseAuth.instance.currentUser;
//       String? userId = currentUser?.uid;
//
//       if (userId != null) {
//         vehicleData['userId'] = userId;
//
//         await _firestore.collection('vehicle_data').add(vehicleData);
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//           content: Text('Information added Successfully!'),
//           duration: Duration(seconds: 2),
//         ));
//
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => Register()),
//         );
//       }
//     } catch (error) {
//       print('Error saving data: $error');
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Vehicle Form')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: SingleChildScrollView(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Existing dropdowns and text fields...
//                 DropdownButtonFormField<String>(
//                   // Brand dropdown...
//                 ),
//                 SizedBox(height: 10),
//                 DropdownButtonFormField<String>(
//                   // Model dropdown...
//                 ),
//                 SizedBox(height: 10),
//                 TextFormField(
//                   // Color text field...
//                 ),
//
//                 SizedBox(height: 20),
//                 ElevatedButton(
//                   onPressed: () {
//                     if (_formKey.currentState!.validate()) {
//                       _saveDataAndNavigate();
//                     }
//                   },
//                   style: ButtonStyle(
//                     backgroundColor:
//                     MaterialStateProperty.all<Color>(Color(0xbb8dd7bc)),
//                     foregroundColor: MaterialStateProperty.all<Color>(Colors.black),
//                   ),
//                   child: Text('Done'),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
