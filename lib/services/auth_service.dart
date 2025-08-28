import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pivot/models/user_profile.dart'; // Assuming your UserProfile model is here

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
    final user = _firebaseAuth.currentUser;
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
      email: email,
      password: password,
    );
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

      // Add createdAt and gender to the user data for Firestore
      Map<String, dynamic> userDataForFirestore = newUserProfile.toJson();
      userDataForFirestore['createdAt'] = FieldValue.serverTimestamp();
      userDataForFirestore['gender'] = userData['gender'];

      // Store the user profile in Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userDataForFirestore);
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
    final user = _firebaseAuth.currentUser;
    if (user == null) return [];
    try {
      // Fetch the current user's role
      // final userDoc = await _firestore.collection('users').doc(user.uid).get();
      // final userRole = userDoc.data()?['role']?.toString() ?? '';
      final snapshot =
          await _firestore
              .collection('users')
              // .where('role', whereIn: ['Professor', 'miniProfessor'])
              .get();

      return snapshot.docs
          .map((doc) => UserProfile.fromJson(doc.data()))
          .toList();
    } catch (e) {
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
      await _firestore.collection('users').doc(uid).update({
        'aboutMe': aboutMe,
      });
    } catch (e) {
      print('Error updating user about me: $e');
      rethrow;
    }
  }

  // Method to delete a user's Firestore document.
  // NOTE: This does NOT delete the user from Firebase Authentication.
  // For full user deletion, a backend function with Admin SDK is required.
  Future<void> deleteUser(String uid) async {
    try {
      if (uid == _firebaseAuth.currentUser?.uid) {
        throw Exception('Admins cannot delete their own account.');
      }
      await _firestore.collection('users').doc(uid).delete();
    } catch (e) {
      print('Error deleting user document: $e');
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  // Method to create user with email and password (for admin use)
  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final result = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      return result;
    } catch (e) {
      print('Error creating user: $e');
      rethrow;
    }
  }

  // Method to create user profile in Firestore
  Future<void> createUserProfile(UserProfile userProfile) async {
    try {
      Map<String, dynamic> userDataForFirestore = userProfile.toJson();
      userDataForFirestore['createdAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('users')
          .doc(userProfile.id)
          .set(userDataForFirestore);
    } catch (e) {
      print('Error creating user profile: $e');
      rethrow;
    }
  }
}
