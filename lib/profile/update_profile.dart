import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hitchify/driverAndVehicleRegistration/register.dart';
import 'dart:io';
import 'package:hitchify/global/validations.dart';

import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

import 'driver_profile_screen.dart';

class UpdateProfile extends StatefulWidget {
  const UpdateProfile({Key? key}) : super(key: key);

  @override
  State<UpdateProfile> createState() => _ProfileState();
}

class _ProfileState extends State<UpdateProfile> {
  File? _image;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool isLoading = false;

  Future<void> getImageFromCamera(bool isCamera) async {
    File? image;
    final picker = ImagePicker();
    if (isCamera) {
      final pickedImage = await picker.pickImage(source: ImageSource.camera);
      if (pickedImage != null) {
        image = File(pickedImage.path);
      }
    }
    setState(() {
      _image = image;
    });
  }

  Future<void> saveProfileData() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    String name = _nameController.text.trim();
    String email = _emailController.text.trim();
    String? imageUrl;

    if (_image != null) {
      firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${DateTime.now()}.png');
      firebase_storage.UploadTask uploadTask = ref.putFile(_image!);

      await uploadTask.whenComplete(() async {
        imageUrl = await ref.getDownloadURL();
      });
    }

    String uid = FirebaseAuth.instance.currentUser!.uid;
    try {
      // Update corresponding user document in 'users' collection
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'displayName': name,
        'email': email,
        'image': imageUrl ?? '',
        'isDriver': true, // Assuming this user is a driver
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Profile updated successfully!'),
        duration: Duration(seconds: 2),
      ));
    } catch (e) {
      print('Error saving profile data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Retrieve the current user's data from Firebase
    User? currentUser = FirebaseAuth.instance.currentUser;
    String uid = currentUser!.uid;
    CollectionReference usersCollection =
        FirebaseFirestore.instance.collection('users');

    return FutureBuilder<DocumentSnapshot>(
      future: usersCollection.doc(uid).get(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          Map<String, dynamic> userData =
              snapshot.data!.data() as Map<String, dynamic>;

          // Set the initial values for name and email fields
          String initialName = userData['displayName'];
          String initialEmail = userData['email'];
          String imageUrl = userData['image'];

          // Set the initial image file if it exists
          File? initialImage;
          // String imageUrl = userData['image'];
          if (imageUrl.isNotEmpty) {
            initialImage = File(imageUrl);
          }

          return Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              title: Center(child: Text("Basic Info")),
            ),
            body: Form(
              key: _formKey,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      getImageFromCamera(true);
                    },
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[300],
                      ),
                      child: imageUrl.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                imageUrl,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(
                              Icons.camera_alt,
                              size: 60,
                              color: Colors.grey[600],
                            ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 8.0),
                    child: TextFormField(
                      controller: _nameController..text = initialName,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
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
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: TextFormField(
                      controller: _emailController..text = initialEmail,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
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
                  ),
                  SizedBox(height: 30),
                  Stack(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState?.validate() ?? false) {
                            setState(() {
                              isLoading =
                                  true; // Set isLoading to true to indicate the process has started
                            });
                            saveProfileData().then((_) {
                              // After saving profile data completes, navigate to the next screen
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => DriverProfileScreen(
                                          userType: 'driver',
                                        )),
                              );
                            }).whenComplete(() {
                              // Set isLoading back to false when the process completes
                              setState(() {
                                isLoading = false;
                              });
                            });
                          }
                        },
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                              Color(0xFF008955)),
                          foregroundColor:
                              MaterialStateProperty.all<Color>(Colors.white),
                          minimumSize: MaterialStateProperty.all<Size>(
                            Size(270,
                                45), // Change the width (and height) as needed
                          ),
                        ),
                        child: Text(
                          'Update',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isLoading) // Render loading indicator if isLoading is true
                        Positioned.fill(
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    ],
                  )
                ],
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return Center(child: Text("Error fetching profile data"));
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
