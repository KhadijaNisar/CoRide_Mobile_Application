import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hitchify/register.dart';
import 'package:hitchify/widgets/custom_outlined_button.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VehicleForm extends StatefulWidget {
  const VehicleForm({Key? key}) : super(key: key);

  @override
  _VehicleFormState createState() => _VehicleFormState();
}

class _VehicleFormState extends State<VehicleForm> {
  String? _selectedBrand;
  String? _selectedModel;
  String? _selectedColor;
  File? _vehiclePhoto;
  File? _licensePhoto;
  File? _vehicleFile;

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
    _formKey.currentState!.save();

    final vehicleData = {
      'brand': _selectedBrand,
      'model': _selectedModel,
      'color': _selectedColor,
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
      await _firestore.collection('vehicle_data').add(vehicleData);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Register()),
      );
    } catch (error) {
      print('Error saving data: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Vehicle Form')),
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
                    onChanged: (value) =>
                        setState(() => _selectedBrand = value),
                    items: ['Honda', 'Toyota', 'Suzuki', 'Kia']
                        .map((brand) => DropdownMenuItem(
                              child: Text(brand),
                              value: brand,
                            ))
                        .toList(),
                    decoration: InputDecoration(
                      labelText: 'Brand',
                      fillColor: Color(0xbb8dd7bc),
                      filled: true,
                      labelStyle: TextStyle(color: Colors.black),
                    ),
                    validator: (value) =>
                        value == null ? 'Please select a brand' : null,
                  ),
                  SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _selectedModel,
                    onChanged: (value) =>
                        setState(() => _selectedModel = value),
                    items: [
                      '2015',
                      '2016',
                      '2017',
                      '2018',
                      '2019',
                      '2020',
                      '2021',
                      '2022',
                      '2023',
                      '2024'
                    ]
                        .map((model) => DropdownMenuItem(
                              child: Text(model),
                              value: model,
                            ))
                        .toList(),
                    decoration: InputDecoration(
                      labelText: 'Model',
                      fillColor: Color(0xbb8dd7bc),
                      filled: true,
                      labelStyle: TextStyle(color: Colors.black),
                    ),
                    validator: (value) =>
                        value == null ? 'Please select a model' : null,
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Color',
                      fillColor: Color(0xbb8dd7bc),
                      filled: true,
                      labelStyle: TextStyle(color: Colors.black),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Enter a color' : null,
                    onSaved: (value) => _selectedColor = value,
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
                    onPressed: _saveDataAndNavigate,
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
