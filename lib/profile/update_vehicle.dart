import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UpdateVehicleForm extends StatefulWidget {
  const UpdateVehicleForm({Key? key}) : super(key: key);

  @override
  _VehicleFormState createState() => _VehicleFormState();
}

class _VehicleFormState extends State<UpdateVehicleForm> {
  String? _selectedBrand;
  String? _selectedModel;
  String? _registrationNumber;
  String? _selectedRegistrationYear;
  String? _selectedColor;
  File? _vehiclePhoto;
  File? _licensePhoto;
  File? _vehicleFile;

  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final _storage = FirebaseStorage.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    fetchVehicleData();
  }

  Future<void> fetchVehicleData() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      String? userId = currentUser?.uid;

      if (userId != null) {
        QuerySnapshot querySnapshot = await _firestore
            .collection('vehicle_data')
            .where('userId', isEqualTo: userId)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          DocumentSnapshot snapshot = querySnapshot.docs.first;
          setState(() {
            _selectedBrand = snapshot['brand'];
            _selectedModel = snapshot['model'];
            _registrationNumber = snapshot['registrationNumber'];
            _selectedRegistrationYear = snapshot['registrationYear'];
            _selectedColor = snapshot['color'];
            print('Selected Model: $_selectedModel');
            print('Registration Number: $_registrationNumber');
            print('Registration Year: $_selectedRegistrationYear');
            print('Selected Color: $_selectedColor');

          });
        }
      }
    } catch (error) {
      print('Error fetching vehicle data: $error');
    }
  }

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

    _formKey.currentState!.save();

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      String? userId = currentUser?.uid;

      if (userId != null) {
        // Update vehicle data in Firestore
        Map<String, dynamic> vehicleData = {
          'brand': _selectedBrand,
          'model': _selectedModel,
          'color': _selectedColor,
          'registrationNumber': _registrationNumber,
          'registrationYear': _selectedRegistrationYear,
        };

        if (_vehiclePhoto != null) {
          String vehicleImageUrl =
          await _uploadImage(_vehiclePhoto!, 'vehicle_photos');
          vehicleData['vehicleImageUrl'] = vehicleImageUrl;
        }

        if (_licensePhoto != null) {
          String licenseImageUrl =
          await _uploadImage(_licensePhoto!, 'license_photos');
          vehicleData['licenseImageUrl'] = licenseImageUrl;
        }

        if (_vehicleFile != null) {
          String vehicleFileUrl =
          await _uploadImage(_vehicleFile!, 'vehicle_files');
          vehicleData['vehicleFileUrl'] = vehicleFileUrl;
        }

        await _firestore
            .collection('vehicle_data')
            .where('userId', isEqualTo: userId)
            .limit(1)
            .get()
            .then((querySnapshot) {
          if (querySnapshot.docs.isNotEmpty) {
            String docId = querySnapshot.docs.first.id;
            _firestore.collection('vehicle_data').doc(docId).update(vehicleData);
          }
        });


        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Information updated Successfully!'),
          duration: Duration(seconds: 2),
        ));

        // Navigate to the previous screen
        Navigator.pop(context);
      }
    } catch (error) {
      print('Error saving data: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Update Vehicle Form')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Brand'),
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
                Text('Model'),
                TextFormField(
                  // initialValue: _selectedModel ?? '',
                  controller: TextEditingController(text: _selectedModel),
                  decoration: InputDecoration(
                    hintText: 'Enter Model',
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
                Text('Registration Number'),
                TextFormField(
                  // initialValue: _registrationNumber ?? '',
                  controller: TextEditingController(text: _registrationNumber),
                  decoration: InputDecoration(
                    hintText: 'Enter Registration Number',
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
                Text('Registration Year'),
                TextFormField(
                  // initialValue: _selectedRegistrationYear ?? '',
                  controller: TextEditingController(text: _selectedRegistrationYear),
                  decoration: InputDecoration(
                    hintText: 'Enter Registration Year',
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
                Text('Color'),
                TextFormField(
                  // initialValue: _selectedColor ?? '',
                  controller: TextEditingController(text: _selectedColor),
                  decoration: InputDecoration(
                    hintText: 'Enter Color',
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
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      _saveDataAndNavigate();
                    }
                  },
                  style: ButtonStyle(
                    backgroundColor:
                    MaterialStateProperty.all<Color>(Color(0xbb8dd7bc)),
                    foregroundColor:
                    MaterialStateProperty.all<Color>(Colors.black),
                  ),
                  child: Text('Update'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}