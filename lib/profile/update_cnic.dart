import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hitchify/global/validations.dart';

class UpdateCNIC extends StatefulWidget {
  const UpdateCNIC({Key? key}) : super(key: key);

  @override
  State<UpdateCNIC> createState() => _CNICPageState();
}

class _CNICPageState extends State<UpdateCNIC> {
  File? _frontImage;
  File? _backImage;
  final TextEditingController _cnicController = TextEditingController();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isNetworkImage = true;
  bool _isBackNetworkImage = true;

  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    fetchStoredData();
  }

  Future<void> fetchStoredData() async {
    try {
      // Fetch the stored data from Firestore
      User? currentUser = FirebaseAuth.instance.currentUser;
      String? userId = currentUser?.uid;

      if (userId != null) {
        DocumentSnapshot snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        // Get the stored values
        String? frontImageUrl = snapshot.get('frontImageUrl');
        String? backImageUrl = snapshot.get('backImageUrl');
        String? cnicNumber = snapshot.get('cnic');
        print("Front Image Url :$frontImageUrl");
        setState(() {
          // Set the fetched values to the state variables
          if (frontImageUrl != null) {
            _frontImage = File(frontImageUrl);
          }
          if (backImageUrl != null) {
            _backImage = File(backImageUrl);
          }
          if (cnicNumber != null) {
            _cnicController.text = cnicNumber;
          }
        });
      }
    } catch (error) {
      // Handle errors
      print('Error fetching stored data: $error');
    }
  }

  Future<void> getImage(bool isFrontImage) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        if (isFrontImage) {
          _frontImage = File(pickedFile.path);
          _isNetworkImage = false;
        } else {
          _backImage = File(pickedFile.path);
          _isBackNetworkImage = false;
        }
      });
    }
  }

  Future<void> uploadImages(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      try {
        User? currentUser = FirebaseAuth.instance.currentUser;
        String? userId = currentUser?.uid;

        if (userId != null) {
          if (_frontImage != null && _backImage != null) {
            String frontImageName = 'front_$userId.jpg';
            String backImageName = 'back_$userId.jpg';

            // Upload front image
            UploadTask frontUploadTask = _storage
                .ref('cnic_images/$frontImageName')
                .putFile(_frontImage!);
            TaskSnapshot frontSnapshot = await frontUploadTask;
            String frontImageURL = await frontSnapshot.ref.getDownloadURL();

            // Upload back image
            UploadTask backUploadTask =
                _storage.ref('cnic_images/$backImageName').putFile(_backImage!);
            TaskSnapshot backSnapshot = await backUploadTask;
            String backImageURL = await backSnapshot.ref.getDownloadURL();

            // Save data to Firestore
            await saveToFirestore(frontImageURL, backImageURL);
            setState(() {
              isLoading = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Images uploaded successfully!'),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Please select both images!'),
              ),
            );
          }
        }
      } catch (error) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading images: $error'),
          ),
        );
      }
    }
  }

  Future<void> saveToFirestore(
      String frontImageUrl, String backImageUrl) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    String? userId = currentUser?.uid;

    if (userId != null) {
      await _firestore.collection('users').doc(userId).update({
        'frontImageUrl': frontImageUrl,
        'backImageUrl': backImageUrl,
        'cnic': _cnicController.text,
      });
    }
  }

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
                // if (_frontImage != null) Image.network(_frontImage!.path),
                // if (_frontImage != null) Image.file(_frontImage!),
                if (_frontImage != null)
                  _isNetworkImage
                      ? Image.network(_frontImage!.path)
                      : Image.file(_frontImage!),
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
                  child: Text('Upload Front Side CNIC Image'),
                ),

                // Back Side Image Section
                if (_backImage != null)
                  _isBackNetworkImage
                      ? Image.network(_backImage!.path)
                      : Image.file(_backImage!),
                // if (_backImage != null) Image.network(_backImage!.path),
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
                  child: Text('Upload Back Side CNIC Image'),
                ),

                // CNIC Number Input Field
                TextFormField(
                  controller: _cnicController,
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
                  decoration: InputDecoration(
                    labelText: 'CNIC Number',
                    hintText: 'Enter your CNIC number',
                    border: OutlineInputBorder(),
                  ),
                ),

                // Save Button
                ElevatedButton(
                  onPressed: () => uploadImages(context),
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Color(0xFF008955)),
                    foregroundColor:
                        MaterialStateProperty.all<Color>(Colors.white),
                    minimumSize: MaterialStateProperty.all<Size>(
                      Size(250, 40), // Change the width (and height) as needed
                    ),
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
