import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> signUpWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      return credential.user;
    } on FirebaseAuthException catch (e) {
      // Re-throw the specific Firebase Auth exception
      throw e;
    } catch (e) {
      // Re-throw any other unexpected exceptions as a generic Exception
      throw Exception("An unexpected error occurred during sign up: ${e.toString()}");
    }
  }

  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return credential.user;
    } on FirebaseAuthException catch (e) {
      // Re-throw the specific Firebase Auth exception
      throw e;
    } catch (e) {
      // Re-throw any other unexpected exceptions as a generic Exception
      throw Exception("An unexpected error occurred during sign in: ${e.toString()}");
    }
  }

  // Method for logging out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw e; // Re-throw Firebase Auth exceptions
    } catch (e) {
      throw Exception("An unexpected error occurred during sign out: ${e.toString()}");
    }
  }

  // Stream to listen to authentication state changes (useful in main.dart's StreamBuilder)
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}