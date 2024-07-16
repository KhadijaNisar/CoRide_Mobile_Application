import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hitchify/home/home_screen.dart';
import 'package:hitchify/driverAndVehicleRegistration/profile_completion_check.dart';

import '../../theme/custom_text_style.dart';
import '../../theme/theme_helper.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_pin_code_text_field.dart';
import 'package:hitchify/UI/profile_screen.dart';

class VerifyPhone extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const VerifyPhone(
      {Key? key, required this.verificationId, required this.phoneNumber});

  @override
  State<VerifyPhone> createState() => _VerifyPhoneState();
}

class _VerifyPhoneState extends State<VerifyPhone> {
  void _resendOtp() {
    final phoneNumber = widget.phoneNumber; // Access phoneNumber from widget

    if (phoneNumber.isNotEmpty) {
      setState(() {
        _isLoading = true; // Set loading state to true when sending OTP
      });

      FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (_) {},
        verificationFailed: (FirebaseAuthException e) {
          setState(() {
            _isLoading = false; // Set loading state to false
          });
          print("Verification failed: ${e.message}");
          // Handle verification failure
        },
        codeSent: (String verificationId, int? token) {
          setState(() {
            _isLoading = false; // Set loading state to false
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() {
            _isLoading = false; // Set loading state to false
          });
          // Handle auto-retrieval timeout
        },
      );
    } else {
      // Handle empty phone number case
      print("Please enter a valid phone number");
    }
  }

  TextEditingController smsCodeController = TextEditingController();
  final auth = FirebaseAuth.instance;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(),
      body: Container(
        width: double.maxFinite,
        padding: EdgeInsets.symmetric(horizontal: 26, vertical: 18),
        child: Column(
          children: [
            Text("Phone verification", style: theme.textTheme.headlineSmall),
            SizedBox(height: 11),
            Text("Enter your OTP code",
                style: CustomTextStyles.bodyLargeGray500),
            SizedBox(height: 37),
            Padding(
              padding: EdgeInsets.only(left: 25, right: 26),
              child: CustomPinCodeTextField(
                controller: smsCodeController,
                context: context,
                onChanged: (value) {},
              ),
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "Didn’t receive code? ",
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.left,
                  ),
                  TextButton(onPressed: _resendOtp, child: Text('Resend OTP')),
                ],
              ),
            ),
            Spacer(flex: 52),
            Container(
              width: 350,
              height: 50,
              child: ElevatedButton(
                child: Text(
                  "Verify",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.all<Color>(Color(0xFF008955)),
                ),
                onPressed: _isLoading ? null : _verifyButtonPressed,
              ),
            ),
            Spacer(flex: 47),
          ],
        ),
      ),
    );
  }

  void _verifyButtonPressed() async {
    final credential = PhoneAuthProvider.credential(
      verificationId: widget.verificationId,
      smsCode: smsCodeController.text.toString(),
    );
    try {
      setState(() {
        _isLoading = true;
      });

      await auth.signInWithCredential(credential);

      final bool profileComplete = await isProfileComplete(widget.phoneNumber);

      if (profileComplete) {
        Navigator.pushAndRemoveUntil(context,  MaterialPageRoute(
          builder: (context) => HomeScreen(),
        ), (route) => false);
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => HomeScreen(),
        //   ),
      } else {
        Navigator.pushAndRemoveUntil(context,  MaterialPageRoute(
          builder: (context) => ProfileScreen(),
        ), (route) => false);
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (context) => ProfileScreen(),
        //   ),
        // );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  onTapArrowLeft(BuildContext context) {
    Navigator.pop(context);
  }
}
