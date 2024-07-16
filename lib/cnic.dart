import 'package:flutter/material.dart';
import 'package:hitchify/register.dart';
import 'package:hitchify/widgets/custom_outlined_button.dart';
import 'dart:io';
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
            builder: (context) =>
                Register(), // Replace with your registration screen widget
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
      await _firestore.collection('cnic_data').add({
        'cnicNumber': cnicNumber,
        'frontImageUrl': frontImageUrl,
        'backImageUrl': backImageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      throw error;
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
          child: Column(
            children: [
              // Front Side Image Section
              ElevatedButton(
                onPressed: () => getImage(true),
                style: ButtonStyle(
                  backgroundColor:
                  MaterialStateProperty.all<Color>(Color(0xbb8dd7bc)),
                  foregroundColor:
                  MaterialStateProperty.all<Color>(Colors.black),
                ),
                child: Text('Upload Front Side CNIC'),
              ),
              _frontImage != null ? Image.file(_frontImage!) : Container(),

              // Back Side Image Section
              ElevatedButton(
                onPressed: () => getImage(false),
                style: ButtonStyle(
                  backgroundColor:
                  MaterialStateProperty.all<Color>(Color(0xbb8dd7bc)),
                  foregroundColor:
                  MaterialStateProperty.all<Color>(Colors.black),
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
                  child: TextField(
                    controller: _cnicController,
                    decoration: InputDecoration(
                      hintText: 'Enter CNIC Number',
                    ),
                  ),
                ),
              ),

              SizedBox(height: 20),
              CustomOutlinedButton(
                text: 'Save',
                height: 50,
                width: 200,
                onPressed: () => uploadImages(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}