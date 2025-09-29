import 'package:firebase_auth/firebase_auth.dart';
import 'package:pivot/models/user_profile.dart'; // Assuming your UserProfile model is here
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pivot/services/user_number_service.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream to listen to authentication state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Clear any cached credentials and auth state
  Future<void> clearAuthState() async {
    try {
      if (_firebaseAuth.currentUser != null) {
        await _firebaseAuth.signOut();
      }
      // Wait for sign out to complete
      await Future.delayed(const Duration(milliseconds: 200));
    } catch (e) {
      // Ignore sign out errors
    }
  }

  // Sign in with email and password
  Future<UserProfile?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      // Validate inputs
      if (email.isEmpty || password.isEmpty) {
        throw FirebaseAuthException(
          code: 'invalid-credential',
          message: 'البريد الإلكتروني وكلمة المرور مطلوبان',
        );
      }

      // Clean email input
      final cleanEmail = email.trim().toLowerCase();

      // Clear any existing auth state to prevent credential conflicts
      await clearAuthState();

      // Validate email format
      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(cleanEmail)) {
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'البريد الإلكتروني غير صحيح',
        );
      }

      UserCredential result = await _firebaseAuth.signInWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        // Verify email if needed
        if (!user.emailVerified) {
          // For now, we'll allow unverified emails, but you might want to handle this
          print('Warning: User email is not verified');
        }

        // Fetch the user profile after successful login
        return await getUserProfile(user.uid);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'لا يوجد مستخدم بهذا البريد الإلكتروني';
          break;
        case 'wrong-password':
          errorMessage = 'كلمة المرور غير صحيحة';
          break;
        case 'invalid-email':
          errorMessage = 'البريد الإلكتروني غير صحيح';
          break;
        case 'user-disabled':
          errorMessage = 'تم تعطيل هذا الحساب';
          break;
        case 'too-many-requests':
          errorMessage = 'محاولات كثيرة جداً، حاول مرة أخرى لاحقاً';
          break;
        case 'invalid-credential':
          errorMessage = 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
          break;
        default:
          errorMessage = 'فشل في تسجيل الدخول: ${e.message}';
      }
      throw FirebaseAuthException(code: e.code, message: errorMessage);
    } catch (e) {
      // Handle other errors
      throw Exception('حدث خطأ غير متوقع: $e');
    }
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
      // Generate unique user number
      final userNumber = await UserNumberService.getNextUserNumber();

      // Create a UserProfile object from the provided data and UID
      UserProfile newUserProfile = UserProfile(
        id: user.uid,
        name: userData['name'],
        email: email,
        department: userData['department'],
        level: userData['level'],
        section: userData['section'],
        profileImageUrl: userData['profileImageUrl'], // Optional
        userNumber: userNumber, // Add the generated user number
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
      rethrow;
    }
  }
}
