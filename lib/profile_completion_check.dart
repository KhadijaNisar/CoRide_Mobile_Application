// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:hitchify/UI/profile_screen.dart';
//
// import '../home/home_screen.dart';
//
// class ProfileCheckScreen extends StatefulWidget {
//   final String phoneuNmber;
//
//   const ProfileCheckScreen({Key? key, required this.phoneNumber})
//       : super(key: key);
//
//   @override
//   _ProfileCheckScreenState createState() => _ProfileCheckScreenState();
// }
//
// class _ProfileCheckScreenState extends State<ProfileCheckScreen> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   late User? _user;
//   Map<String, dynamic>? _userData;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchUserData();
//   }
//
//   Future<void> _fetchUserData() async {
//     try {
//       // Get the current user
//       _user = _auth.currentUser;
//       if (_user == null) {
//         throw 'User not authenticated.';
//       }
//       // Retrieve user data from Firestore based on phone number
//       QuerySnapshot querySnapshot = await _firestore
//           .collection('users')
//           .where('phoneNumber', isEqualTo: widget.phoneNumber)
//           .get();
//       if (querySnapshot.docs.isNotEmpty) {
//         // User document found, check profile completion
//         DocumentSnapshot userDoc = querySnapshot.docs.first;
//         setState(() {
//           _userData = userDoc.data() as Map<String, dynamic>?;
//         });
//         if (_isProfileComplete()) {
//           // Profile is complete, navigate to home screen
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (context) => HomeScreen()),
//           );
//         } else {
//           // Profile is incomplete, navigate to profile completion screen
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (context) => ProfileScreen()),
//           );
//         }
//       } else {
//         // User document not found, handle accordingly
//         // For example, show an error message or navigate to sign-up screen
//         print('User document not found.');
//       }
//     } catch (error) {
//       print('Error fetching user data: $error');
//       // Handle error accordingly
//     }
//   }
//
//   bool _isProfileComplete() {
//     // Check if all required fields are present in the user data
//     return _userData != null &&
//         _userData!.containsKey('displayName') &&
//         _userData!.containsKey('address') &&
//         _userData!.containsKey('cnic') &&
//         _userData!.containsKey('email') &&
//         _userData!.containsKey('image');
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // Display loading indicator or placeholder UI while fetching user data
//     return Scaffold(
//       body: Center(
//         child: CircularProgressIndicator(),
//       ),
//     );
//   }
// }
