import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hitchify/driverAndVehicleRegistration/register.dart';
import 'package:hitchify/widgets/custom_outlined_button.dart';
import 'dart:io';
import 'package:hitchify/global/validations.dart';

import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CNIC extends StatefulWidget {
  const CNIC({Key? key}) : super(key: key);

  @override
  State<CNIC> createState() => _CNICPageState();
}

class _CNICPageState extends State<CNIC> {
  File? _frontImage;
  File? _backImage;
  final TextEditingController _cnicController = TextEditingController();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isLoading = false;

  Future<void> getImage(bool isFront) async {
    final picker = ImagePicker();

    final pickedImage = await picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      File image = File(pickedImage.path);
      setState(() {
        if (isFront) {
          _frontImage = image;
        } else {
          _backImage = image;
        }
      });
    }
  }

  Future<void> uploadImages(BuildContext context) async {
    try {
      if (_frontImage != null && _backImage != null) {
        String frontImageUrl = await _uploadImageToStorage(_frontImage!);
        String backImageUrl = await _uploadImageToStorage(_backImage!);
        String cnicNumber = _cnicController.text.trim();
        await saveToFirestore(cnicNumber, frontImageUrl, backImageUrl);
        // Navigate to the existing registration screen after saving the data
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Register(),
          ),
        );
        // Success message or navigation to the next screen
        print('Images uploaded successfully!');
      } else {
        // Show a SnackBar if images are not selected
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select both front and back images.'),
          ),
        );
      }
    } catch (error) {
      // Handle errors
      print('Error uploading images: $error');
    }
  }

  Future<String> _uploadImageToStorage(File image) async {
    try {
      TaskSnapshot snapshot = await _storage
          .ref()
          .child('cnic_images/${DateTime.now().millisecondsSinceEpoch}')
          .putFile(image);
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (error) {
      throw error;
    }
  }

  Future<void> saveToFirestore(
      String cnicNumber, String frontImageUrl, String backImageUrl) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      String? userId = currentUser?.uid;

      if (userId != null) {
        // Update corresponding user document in 'users' collection
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'cnic': cnicNumber,
          'frontImageUrl': frontImageUrl,
          'backImageUrl': backImageUrl,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Uploaded Successfully!'),
        duration: Duration(seconds: 2),
      ));
    } catch (error) {
      throw error;
    }
  }

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('CNIC')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Front Side Image Section
                ElevatedButton(
                  onPressed: () => getImage(true),
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Color(0xFF008955)),
                    foregroundColor:
                        MaterialStateProperty.all<Color>(Colors.white),
                    minimumSize: MaterialStateProperty.all<Size>(
                      Size(250, 40), // Change the width (and height) as needed
                    ),
                  ),
                  child: Text('Upload Front Side CNIC'),
                ),
                _frontImage != null ? Image.file(_frontImage!) : Container(),

                // Back Side Image Section
                ElevatedButton(
                  onPressed: () => getImage(false),
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Color(0xFF008955)),
                    foregroundColor:
                        MaterialStateProperty.all<Color>(Colors.white),
                    minimumSize: MaterialStateProperty.all<Size>(
                      Size(250, 40), // Change the width (and height) as needed
                    ),
                  ),
                  child: Text('Upload Back Side CNIC'),
                ),
                _backImage != null ? Image.file(_backImage!) : Container(),
                SizedBox(
                  height: 30,
                ),

                // CNIC TextField Section
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextFormField(
                      controller: _cnicController,
                      decoration: InputDecoration(
                        hintText: 'Enter CNIC Number',
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors
                                .green, // Set the default border color to green
                          ),
                        ),
                      ),
                      validator: (cnic) {
                        int validationResult = validateCNIC(cnic);

                        if (validationResult == 1) {
                          return "Please enter a CNIC";
                        } else if (validationResult == 2) {
                          return "Please enter a valid CNIC (e.g., 1234567890123)";
                        }

                        return null;
                      },
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                    ),
                  ),
                ),

                SizedBox(height: 30),
                Stack(
                  children: [
                    ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all<Color>(Color(0xFF008955)),
                        foregroundColor:
                            MaterialStateProperty.all<Color>(Colors.white),
                        minimumSize: MaterialStateProperty.all<Size>(
                          Size(270,
                              45), // Change the width (and height) as needed
                        ),
                      ),
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          uploadImages(context);
                        }
                      },
                      child: Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isLoading) // isLoading is a boolean variable indicating whether the process is ongoing
                      Positioned.fill(
                        child: Center(
                          child:
                              CircularProgressIndicator(), // Display loading indicator
                        ),
                      ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
