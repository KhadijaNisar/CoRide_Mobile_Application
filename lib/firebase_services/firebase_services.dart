// ignore_for_file: avoid_print, nullable_type_in_catch_clause, empty_constructor_bodies
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  FirebaseAuthService() {}

  User? getCurrentUser() {
    return _auth.currentUser;
  }
  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print("Failed to sign in: ${e.message}");
      return null;
    } catch (e) {
      print("Unexpected error during sign in: $e");
      return null;
    }
  }

  Future<User?> signUpWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print("Failed to sign up: ${e.message}");
      return null;
    } catch (e) {
      print("Unexpected error during sign up: $e");
      return null;
    }
  }
}
