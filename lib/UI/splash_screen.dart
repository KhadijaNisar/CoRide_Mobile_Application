import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hitchify/firebase_services/splash_services.dart';
import 'package:hitchify/UI/auth/loginWithPhone.dart';
import 'package:hitchify/UI/profile_screen.dart';
import 'package:hitchify/home/home_screen.dart';
import '../widgets/custom_image_view.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // SplashServices splashScreen = SplashServices();

  void isLogin(BuildContext context) {
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    if (user != null) {
      Timer(
          const Duration(seconds: 3),
              () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                // builder: (context) => HomeScreen(),
                builder: (context) => ProfileScreen(),
              )));
    } else {
      Timer(
          const Duration(seconds: 3),
              () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(),
                // builder: (context) => HomeScreen(),
              )));
    }
  }
  @override
  void initState() {
    super.initState();
    isLogin(context);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
        home: SafeArea(
          child: Scaffold(
              body: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/splashimage.png'), // Replace with your image asset path
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              ),
        ),
        );
      // home: SafeArea(
      //   child: Scaffold(
      //
      //     resizeToAvoidBottomInset: false,
      //     body: Container(
      //       child: Image(image:AssetImage('assets/images/splashimage.png')),
      //     ),
      //   ),
      // ),

  }
}