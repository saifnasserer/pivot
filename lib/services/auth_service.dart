import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pivot/models/user_profile.dart'; // Assuming your UserProfile model is here

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream to listen to authentication state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // // Sign up with email and password
  // Future<User?> signUpWithEmailAndPassword(String email, String password) async {
  //   try {
  //     UserCredential result = await _firebaseAuth.createUserWithEmailAndPassword(
  //         email: email, password: password);
  //     return result.user;
  //   } catch (e) {
  //     print(e.toString());
  //     return null;
  //   }
  // }

  // Sign in with email and password
  Future<UserProfile?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential result = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        // Fetch the user profile after successful login
        return await getUserProfile(user.uid);
      } else {
        return null;
      }
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  // Get current user
  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  // Sign up with email and password and store user profile
  Future<User?> signUpWithEmailAndPassword(
    String email,
    String password,
    Map<String, dynamic> userData,
  ) async {
    try {
      UserCredential result = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;

      if (user != null) {
        // Create a UserProfile object from the provided data and UID
        UserProfile newUserProfile = UserProfile(
          id: user.uid,
          name: userData['name'],
          email: email,
          department: userData['department'],
          level: userData['level'],
          section: userData['section'],
          profileImageUrl: userData['profileImageUrl'], // Optional
        );

        // Store the user profile in Firestore
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(newUserProfile.toJson());
      }
      return user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // You might also want a method to fetch user profile data
  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserProfile.fromJson(doc.data() as Map<String, dynamic>);
      } else {
        return null;
      }
    } catch (e) {
      print(e.toString());
      return null;
    }
  }
}
