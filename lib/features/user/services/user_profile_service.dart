import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pivot/models/user_profile.dart';

class UserProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Map<String, UserProfile> _userProfilesCache = {};

  Future<UserProfile?> getLoggedInUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      // Check cache first
      if (_userProfilesCache.containsKey(user.uid)) {
        return _userProfilesCache[user.uid];
      }

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final profile = UserProfile.fromMap(doc.data()!);
        _userProfilesCache[user.uid] = profile;
        return profile;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get logged in user profile: $e');
    }
  }

  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      // Check cache first
      if (_userProfilesCache.containsKey(userId)) {
        return _userProfilesCache[userId];
      }

      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final profile = UserProfile.fromMap(doc.data()!);
        _userProfilesCache[userId] = profile;
        return profile;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  Future<List<UserProfile>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      final users =
          snapshot.docs.map((doc) => UserProfile.fromMap(doc.data())).toList();

      // Update cache
      for (final user in users) {
        _userProfilesCache[user.id] = user;
      }

      return users;
    } catch (e) {
      throw Exception('Failed to get all users: $e');
    }
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      await _firestore
          .collection('users')
          .doc(profile.id)
          .update(profile.toMap());
      _userProfilesCache[profile.id] = profile;
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  Future<void> updateEnrolledSubjects(List<String> subjectIds) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore.collection('users').doc(user.uid).update({
        'enrolledSubjects': subjectIds,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update enrolled subjects: $e');
    }
  }

  Future<void> updateTeachingSubjects(List<String> subjectIds) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore.collection('users').doc(user.uid).update({
        'teachingSubjects': subjectIds,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update teaching subjects: $e');
    }
  }

  Future<void> updateUserEnrolledSubjects(
    String userId,
    List<String> subjectIds,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'enrolledSubjects': subjectIds,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user enrolled subjects: $e');
    }
  }

  Future<void> updateUserTeachingSubjects(
    String userId,
    List<String> subjectIds,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'teachingSubjects': subjectIds,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user teaching subjects: $e');
    }
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user role: $e');
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
      _userProfilesCache.remove(userId);
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  Future<String> uploadProfileImage(String imagePath) async {
    try {
      // TODO: Implement image upload
      // final imageUrl = await StorageOptimizationService().uploadImage(
      //   await _getImageBytes(imagePath),
      //   'profile_images/${DateTime.now().millisecondsSinceEpoch}.jpg',
      // );
      // return imageUrl;
      return 'placeholder_profile_image_url';
    } catch (e) {
      throw Exception('Failed to upload profile image: $e');
    }
  }

  Future<void> createUserProfile(UserProfile profile) async {
    try {
      await _firestore.collection('users').doc(profile.id).set(profile.toMap());
      _userProfilesCache[profile.id] = profile;
    } catch (e) {
      throw Exception('Failed to create user profile: $e');
    }
  }

  Future<List<UserProfile>> searchUsers(String query) async {
    try {
      final snapshot =
          await _firestore
              .collection('users')
              .where('name', isGreaterThanOrEqualTo: query)
              .where('name', isLessThan: query + 'z')
              .get();

      return snapshot.docs
          .map((doc) => UserProfile.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }

  Future<List<UserProfile>> getUsersByRole(String role) async {
    try {
      final snapshot =
          await _firestore
              .collection('users')
              .where('role', isEqualTo: role)
              .get();

      return snapshot.docs
          .map((doc) => UserProfile.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get users by role: $e');
    }
  }

  Future<List<UserProfile>> getUsersByDepartment(String department) async {
    try {
      final snapshot =
          await _firestore
              .collection('users')
              .where('department', isEqualTo: department)
              .get();

      return snapshot.docs
          .map((doc) => UserProfile.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get users by department: $e');
    }
  }
}
