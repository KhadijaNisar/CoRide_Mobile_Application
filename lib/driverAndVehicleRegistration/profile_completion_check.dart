import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<bool> isProfileComplete(String? phoneNo) async {
  // final User? user = FirebaseAuth.instance.currentUser;
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('phoneNumber', isEqualTo: phoneNo)
        .get();
    // final snapshot = await FirebaseFirestore.instance
    //     .collection('users')
    //     .doc(user?.phoneNumber)
    //     .get();

    if (snapshot.docs.isNotEmpty) {
      return true;
    } else {
      return false;
    }
  } catch (error) {
    // Handle error, such as no user logged in or database connection issue
    print('Error checking profile completion: $error');
    return false;
  }
}
