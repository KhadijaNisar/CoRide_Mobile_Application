import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../theme/custom_text_style.dart';
import '../../theme/theme_helper.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_pin_code_text_field.dart';
import 'package:hitchify/UI/profile_screen.dart';

class VerifyPhone extends StatefulWidget {
  final String verificationId;

  const VerifyPhone({Key? key, required this.verificationId});

  @override
  State<VerifyPhone> createState() => _VerifyPhoneState();
}

class _VerifyPhoneState extends State<VerifyPhone> {
  TextEditingController smsCodeController = TextEditingController();
  final auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: const Text("OTP Verification"),
          centerTitle: true,
        ),
        body: Container(
            width: double.maxFinite,
            padding: EdgeInsets.symmetric(horizontal: 26, vertical: 18),
            child: Column(children: [
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
                      onChanged: (value) {})),
              SizedBox(height: 20),
              RichText(
                  text: TextSpan(children: [
                    TextSpan(
                        text: "Didn’t receive code? ",
                        style: theme.textTheme.titleMedium),
                    TextSpan(
                        text: "Resend again",
                        style: CustomTextStyles.titleMediumPrimary_1)
                  ]),
                  textAlign: TextAlign.left),
              Spacer(flex: 52),
              Container(
                width: 350,
                height: 50,
                child: ElevatedButton(
                    child: Text("Verify",style: TextStyle(color: Colors.white,fontSize: 16),),
                    style : ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(Color(0xFF008955)),
                    ),
                    onPressed: () async {
                      final credential = PhoneAuthProvider.credential(
                          verificationId: widget.verificationId,
                          smsCode: smsCodeController.text.toString());
                      try {
                        await auth.signInWithCredential(credential);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileScreen(),
                          ),
                        );
                      } catch (e) {
                        setState(() {});
                      }
                    },),
              ),
              Spacer(flex: 47)
            ])));
  }

  onTapArrowLeft(BuildContext context) {
    Navigator.pop(context);
  }
}
