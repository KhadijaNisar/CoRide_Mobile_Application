import 'dart:io';
import 'package:hitchify/home/locationpage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hitchify/core/app_export.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:hitchify/validations.dart';
import 'package:hitchify/widgets/custom_elevated_button.dart';
import 'package:image_picker/image_picker.dart';

import '../core/utils/image_constant.dart';
import '../theme/theme_helper.dart';
import '../widgets/custom_image_view.dart';
import '../widgets/custom_outlined_button.dart';

class ProfileScreen extends StatefulWidget {
  ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _imagePath;
  File? _imageFile;

  Future<void> _pickImage(ImageSource source) async {
    final imagePicker = ImagePicker();
    try {
      final pickedFile = await imagePicker.pickImage(source: ImageSource.camera);
      setState(() {
        _imageFile = pickedFile != null ? File(pickedFile.path) : null;
      });
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  void _resetForm() {
    // Clear text controllers and reset form fields
    nameController.clear();
    emailController.clear();
    addressController.clear();
    cnicController.clear();
    _imagePath = null; // Assuming imageUrl is a variable storing the image URL
    // Clear other form fields here
  }
  void _saveDataToFirebase() async {
    if (_formKey.currentState!.validate()) {
      try {
        User? currentUser = FirebaseAuth.instance.currentUser;
        String? userId = currentUser?.uid;

        // Upload the image to Firebase Storage
        String imageUrl = await _uploadImageToFirebaseStorage();

        // Save data, including the image URL, to Firestore
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'displayName': nameController.text,
          'email': emailController.text,
          'address': addressController.text,
          'cnic': cnicController.text,
          'image': imageUrl,
        });

        // Data saved successfully
        print('Data saved to Firebase!');
      } catch (e) {
        // Handle errors
        print('Error saving data to Firebase: $e');
      }
    }
  }

  Future<String> _uploadImageToFirebaseStorage() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      String? userId = currentUser?.uid;

      if (_imageFile != null) {
        // Get a reference to the storage service
        FirebaseStorage storage = FirebaseStorage.instance;
        Reference storageRef =
            storage.ref().child('user_images').child(userId!);

        // Upload the image to Firebase Storage
        UploadTask uploadTask = storageRef.putFile(File(_imageFile!.path));

        // Get the download URL of the uploaded image
        String downloadURL = await (await uploadTask).ref.getDownloadURL();

        return downloadURL;
      } else {
        return ''; // Return an empty string if no image is selected
      }
    } catch (e) {
      // Handle errors
      print('Error uploading image to Firebase Storage: $e');
      throw e; // Rethrow the error to be caught in the main function
    }
  }


  TextEditingController emailController = TextEditingController();

  TextEditingController phoneNumberController = TextEditingController();

  List<String> gender = ["Male", "Female"];

  TextEditingController addressController = TextEditingController();

  TextEditingController nameController = TextEditingController();

  TextEditingController cnicController = TextEditingController();

  GlobalKey<NavigatorState> navigatorKey = GlobalKey();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Profile"),
          centerTitle: true,
        ),
        body: Padding(
            padding: EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Container(
                width: double.maxFinite,
                padding: EdgeInsets.symmetric(vertical: 13),
                child: Column(children: [
                  Expanded(
                    child: SingleChildScrollView(
                      reverse: true,
                      child: Padding(
                        padding:
                            EdgeInsets.only(left: 15, right: 15, bottom: 5),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                _pickImage(ImageSource.gallery);
                              },
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey[300],
                                ),
                                child: _imageFile == null
                                    ? Icon(
                                  Icons.camera_alt,
                                  size: 60,
                                  color: Colors.grey[600],
                                )
                                    : ClipOval(
                                  child: Image.file(
                                    _imageFile!,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              "Take Photo",
                              style: CustomTextStyles.titleMediumBlack900,
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            TextFormField(
                              controller: nameController,
                              keyboardType: TextInputType.text,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: appTheme.gray400,
                                    width: 1,
                                  ),
                                ),
                                hintText: 'Full Name',
                              ),
                              validator: (name) {
                                int validationResult = validateName(name);

                                if (validationResult == 1) {
                                  return "Please enter a valid name";
                                }

                                return null;
                              },
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: appTheme.gray400,
                                    width: 1,
                                  ),
                                ),
                                hintText: 'Email :: talha@gmail.com',
                              ),
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: (email) {
                                int validationResult = validateEmail(email);

                                if (validationResult == 1) {
                                  return "Please enter an email address";
                                } else if (validationResult == 2) {
                                  return "Please enter a valid email address";
                                }

                                return null;
                              },
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: appTheme.gray400,
                                    width: 1,
                                  ),
                                ),
                                hintText: 'Address',

                              ),
                              controller: addressController,
                              keyboardType: TextInputType.text,
                                  validator: (address) {
                                    int validationResult = validateAddress(address);

                                    if (validationResult == 1) {
                                      return 'Address cannot be empty';
                                    } else if (validationResult == 2) {
                                      return 'Address must be at least 5 characters long';
                                    }

                                    return null; // Return null to indicate the value is valid
                                  },
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: appTheme.gray400,
                                    width: 1,
                                  ),
                                ),
                                hintText: 'CNIC',
                              ),
                              controller: cnicController,
                              keyboardType: TextInputType.number,
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
                            const SizedBox(height: 50),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 11),
                              child: Row(
                                children: [
                                  CustomOutlinedButton(
                                    height: 45,
                                    width: 125,
                                    text: "Cancel",
                                    onPressed: () {
                                      _resetForm();
                                    },
                                    margin: const EdgeInsets.only(
                                      right: 10,
                                    ),
                                  ),
                                  CustomElevatedButton(
                                    text: "Save",
                                    onPressed: (){
                                      _saveDataToFirebase();
                                      Navigator.push(context,MaterialPageRoute(builder: (context)=>LocationAccess()));
                                    },
                                    height: 46,
                                    width: 125,
                                    margin: const EdgeInsets.only(
                                      left: 10,
                                    ),
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            )));
  }

  onTapArrowLeft(BuildContext context) {
    Navigator.pop(context);
  }

}

