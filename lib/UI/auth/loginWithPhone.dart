import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hitchify/home/home_screen.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:hitchify/UI/auth/verifyPhone.dart';
import 'package:hitchify/UI/profile_screen.dart';
import 'package:hitchify/core/app_export.dart';
import 'package:hitchify/widgets/custom_elevated_button.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/custom_outlined_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hitchify/theme/theme_helper.dart';

class LoginWithPhone extends StatefulWidget {
  const LoginWithPhone({Key? key}) : super(key: key);

  @override
  State<LoginWithPhone> createState() => _LoginWithPhoneState();
}

class _LoginWithPhoneState extends State<LoginWithPhone> {
  TextEditingController phoneNumberController = TextEditingController();
  final auth = FirebaseAuth.instance;
  GoogleSignIn googleSignIn = GoogleSignIn(
    clientId:
        '632782991611-cc3kd5k0kfsbuu0hf88n95tmakqg82lu.apps.googleusercontent.com',
  );

  Future<User?> _handleSignIn() async {
    try {
      // Trigger Google Sign In
      GoogleSignInAccount? googleSignInAccount = await googleSignIn.signIn();

      if (googleSignInAccount == null) {
        // The user canceled the sign-in process
        print("Google Sign In canceled");
        return null;
      }

      // Get authentication details
      GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount.authentication;

      // Create Firebase credential
      AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );

      // Sign in with Firebase using the credential
      UserCredential authResult = await auth.signInWithCredential(credential);
      User? user = authResult.user;

      print("User signed in: ${user!.displayName}");
      Navigator.push(context,MaterialPageRoute(builder: (context)=>ProfileScreen()));
      return user;
    } catch (error) {
      // Handle errors during the sign-in process
      print("Error signing in with Google: $error");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: CustomAppBar(title: 'Back', context: context),
      body: Column(
        children: [
          Text("Get Started", style: theme.textTheme.headlineSmall),
          const SizedBox(height: 50),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: IntlPhoneField(
                keyboardType: TextInputType.phone,
                controller: phoneNumberController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(
                    borderSide: BorderSide(),
                  ),
                ),
                initialCountryCode: 'PK',
              )
              //
              ),
          const SizedBox(height: 50),
          Container(
            width: 350,
            height: 50,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton(
                child: Text("Next",style: TextStyle(color: Colors.white,fontSize: 16),),
                style : ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(Color(0xFF008955)),
                ),
                onPressed: () {
                  String phoneNumber = '+92${phoneNumberController.text}';

                  if (phoneNumber.isNotEmpty) {
                    auth.verifyPhoneNumber(
                      phoneNumber: phoneNumber,
                      verificationCompleted: (_) {},
                      verificationFailed: (e) {
                        print("Verification failed: ${e.message}");
                        // Handle verification failure
                      },
                      codeSent: (String verificationId, int? token) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VerifyPhone(
                              verificationId: verificationId,
                            ),
                          ),
                        );
                      },
                      codeAutoRetrievalTimeout: (e) {
                        // Handle auto-retrieval timeout
                      },
                    );
                  } else {
                    // Handle empty phone number case
                    print("Please enter a valid phone number");
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 30),
          const Text(
              "By signing up, you agree to the Terms of\n         service and Privacy policy."),
          const SizedBox(height: 50),
          Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                    padding: EdgeInsets.only(top: 10, bottom: 12),
                    child: SizedBox(
                        height: 10,
                        width: 156,
                        child: Divider(color: appTheme.gray400))),
                Padding(
                    padding: EdgeInsets.only(left: 7),
                    child:
                        Text("or", style: CustomTextStyles.titleMediumGray400)),
                Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 12),
                    child: SizedBox(
                        height: 10,
                        width: 156,
                        child: Divider(color: appTheme.gray400, indent: 7)))
              ]),
          SizedBox(
            height: 7,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11),
            child: CustomOutlinedButton(
                height: 48,
                text: "Sign up with Gmail",
                onPressed: () async {
                  User? user = await _handleSignIn();
                  if (user != null) {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ProfileScreen()));
                  }
                },
                leftIcon: Container(
                    margin: const EdgeInsets.only(right: 11),
                    child: CustomImageView(
                        imagePath: ImageConstant.imgGmail,
                        height: 12,
                        width: 16)),
                buttonStyle: CustomButtonStyles.outlineBlueGray,
                buttonTextStyle: theme.textTheme.titleMedium!),
          ),
        ],
      ),
    );
  }
}
