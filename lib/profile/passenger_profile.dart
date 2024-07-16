import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hitchify/home/driver_home.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';
import '../global/validations.dart';
import '../home/animated_downbar.dart';
import '../home/home_screen.dart';
import '../theme/theme_helper.dart';

class EditProfileScreen extends StatefulWidget {
  final String userType; // Add userType parameter to the constructor

  EditProfileScreen({required this.userType});
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}


class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController addressController;
  late TextEditingController cnicController;
  late TextEditingController phoneNumberController;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();
  late User _currentUser;
  bool _isLoading = false;
  late String _displayName = '';
  late String _email = '';
  late String _phoneNumber = '';
  late String _address = '';
  late String _cnic = '';
  File? _pickedImage;
  late String _currentUserProfilePicture = '';

  bool myInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),(route)=>false
    );
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(builder: (context) => HomeScreen()),
      // );
    return true;
  }

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    nameController = TextEditingController();
    emailController = TextEditingController();
    addressController = TextEditingController();
    cnicController = TextEditingController();
    phoneNumberController = TextEditingController();
    BackButtonInterceptor.add(myInterceptor);
  }

  @override
  void dispose() {
    // Dispose controllers
    nameController.dispose();
    emailController.dispose();
    addressController.dispose();
    cnicController.dispose();
    phoneNumberController.dispose();
    BackButtonInterceptor.remove(myInterceptor);
    super.dispose();
  }

  Future<void> _getCurrentUser() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();

      if (userSnapshot.exists) {
        final userData = userSnapshot.data() as Map<String, dynamic>;
        _currentUser = _auth.currentUser!;
        _displayName = userData['displayName'] ?? '';
        _email = userData['email'] ?? '';
        _phoneNumber = userData['phoneNumber'] ?? '';
        _address = userData['address'] ?? '';
        _cnic = userData['cnic'] ?? '';
        _currentUserProfilePicture = userData['image'] ?? '';

        // Set initial values for text controllers
        nameController.text = _displayName;
        emailController.text = _email;
        addressController.text = _address;
        cnicController.text = _cnic;
        phoneNumberController.text = _phoneNumber;
      }
    } catch (error) {
      print('Error fetching user data: $error');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Update user document in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .update({
        'displayName': _displayName,
        'email': _email,
        'phoneNumber': _phoneNumber,
        'address': _address,
        'cnic': _cnic,
        'profilePicture':
            _currentUserProfilePicture, // Add profile picture here
      });
    } catch (error) {
      print('Error saving changes: $error');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _pickImage() async {
    final pickedImageFile = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (pickedImageFile != null) {
      setState(() {
        _pickedImage = File(pickedImageFile.path);
      });

      try {
        final reference = _storage
            .ref()
            .child('user_images')
            .child(_auth.currentUser!.uid)
            .child(
                'profile_picture.jpg'); // Consider setting a fixed filename for profile pictures
        await reference.putFile(_pickedImage!);

        final imageUrl = await reference.getDownloadURL();

        // Update the image field in the user document in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .update({'image': imageUrl});

        setState(() {
          _currentUserProfilePicture =
              imageUrl; // Update the profile picture URL
        });
      } catch (error) {
        print('Error uploading image: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
        leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              if (widget.userType == 'passenger') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HomeScreen()),
                );
              } else if (widget.userType == 'driver') {
                // print("Type: $widget.userType");
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => driverHome()),
                );
              }
            }),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InkWell(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundImage: _pickedImage != null
                            ? FileImage(_pickedImage!) as ImageProvider<Object>?
                            : _currentUserProfilePicture.isNotEmpty
                                ? NetworkImage(_currentUserProfilePicture)
                                    as ImageProvider<Object>?
                                : null,
                      ),
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Display Name',
                        labelStyle: TextStyle(color: Colors.green),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.green),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _displayName = value;
                        });
                      },
                      controller: nameController,
                      validator: (name) {
                        int validationResult = validateName(name);

                        if (validationResult == 1) {
                          return "Please enter a valid name";
                        }

                        return null;
                      },
                      autovalidateMode: AutovalidateMode
                          .onUserInteraction, // Use the controller
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(color: Colors.green),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.green),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _email = value;
                        });
                      },
                      controller: emailController, // Use the controller
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
                    SizedBox(height: 10),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        labelStyle: TextStyle(color: Colors.green),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.green),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _phoneNumber = value;
                        });
                      },
                      keyboardType: TextInputType.number,
                      controller: phoneNumberController, // Use the controller
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Address',
                        labelStyle: TextStyle(color: Colors.green),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.green),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _address = value;
                        });
                      },
                      controller: addressController, // Use the controller
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
                    SizedBox(height: 10),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'CNIC',
                        labelStyle: TextStyle(color: Colors.green),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.green),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _cnic = value;
                        });
                      },
                      controller: cnicController, // Use the controller
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
                    SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () {
                        _saveChanges();
                        // Upload the image after saving changes
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appTheme.teal500,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Save Changes'),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: AnimatedDownBar(
        userType: 'passenger',
        screenNo: 3,
      ),
    );
  }
}