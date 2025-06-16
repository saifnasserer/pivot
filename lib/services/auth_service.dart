import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pivot/models/user_profile.dart'; // Assuming your UserProfile model is here

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Constructor to set persistence
  AuthService() {
    _firebaseAuth.setPersistence(Persistence.LOCAL);
  }

  // Stream to listen to authentication state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Sign in with email and password
  Future<UserProfile?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    UserCredential result = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    User? user = result.user;

    if (user != null) {
      // Fetch the user profile after successful login
      return await getUserProfile(user.uid);
    }
    return null;
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
  Future<UserProfile?> signUpWithEmailAndPassword(
    String email,
    String password,
    Map<String, dynamic> userData,
  ) async {
    UserCredential result = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email, password: password);
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
      return newUserProfile;
    }
    return null;
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

  // Method to get all users
  Future<List<UserProfile>> getAllUsers() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('users').get();
      return snapshot.docs
          .map((doc) => UserProfile.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print(e.toString());
      return [];
    }
  }

  // Method to update a user's role
  Future<void> updateUserRole(String uid, String role) async {
    try {
      await _firestore.collection('users').doc(uid).update({'role': role});
    } catch (e) {
      print('Error updating user role: $e');
      // Optionally re-throw or handle the error as needed
      rethrow;
    }
  }

  // Method to update a user's about me text
  Future<void> updateUserAboutMe(String uid, String aboutMe) async {
    try {
      await _firestore.collection('users').doc(uid).update({'aboutMe': aboutMe});
    } catch (e) {
      print('Error updating user about me: $e');
      rethrow;
    }
  }
}
