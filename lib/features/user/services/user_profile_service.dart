import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/services/storage_optimization_service.dart';

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

      // Clear cache to force refresh
      _userProfilesCache.remove(user.uid);
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

      // Clear cache to force refresh
      _userProfilesCache.remove(user.uid);
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

      // Clear cache to force refresh
      _userProfilesCache.remove(userId);
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

      // Clear cache to force refresh
      _userProfilesCache.remove(userId);
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
      // Convert image path to XFile
      final imageFile = XFile(imagePath);

      // Upload image using StorageOptimizationService with profile optimization
      final imageUrl = await StorageOptimizationService().uploadFileOptimized(
        imageFile,
        usage: 'profile',
        folder: 'profile',
        checkDuplicate: false, // Don't check for duplicates for profile images
      );

      if (imageUrl == null) {
        throw Exception('Failed to upload image to storage');
      }

      // Update user profile with new image URL
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _firestore.collection('users').doc(currentUser.uid).update({
          'profileImageUrl': imageUrl,
        });
      }

      return imageUrl;
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
              .where('name', isLessThan: '${query}z')
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

  Future<void> updateAssistantPreferences(
    Map<String, String> preferences,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _firestore.collection('users').doc(user.uid).update({
        'assistantPreferences': preferences,
      });

      // Clear cache to force refresh
      _userProfilesCache.remove(user.uid);
    } catch (e) {
      throw Exception('Failed to update assistant preferences: $e');
    }
  }

  Future<void> updateUserProfileData(
    String userId,
    Map<String, dynamic> data, {
    XFile? imageFile,
  }) async {
    try {
      // Handle image upload if provided
      if (imageFile != null) {
        final String imageUrl = await _uploadProfileImage(imageFile, userId);
        data['profileImageUrl'] = imageUrl;
      }

      // Handle password update if provided
      if (data.containsKey('password')) {
        final newPassword = data['password'] as String;
        final currentPassword = data['currentPassword'] as String?;
        data.remove('password');
        data.remove('currentPassword');

        final user = _auth.currentUser;
        if (user != null &&
            currentPassword != null &&
            currentPassword.isNotEmpty) {
          // Re-authenticate user before password change
          final credential = EmailAuthProvider.credential(
            email: user.email!,
            password: currentPassword,
          );

          await user.reauthenticateWithCredential(credential);
          await user.updatePassword(newPassword);
        }
      }

      // Update Firestore document
      if (data.isNotEmpty) {
        await _firestore.collection('users').doc(userId).update(data);
      }

      // Clear cache to force refresh
      _userProfilesCache.remove(userId);
    } catch (e) {
      if (e.toString().contains('wrong-password')) {
        throw Exception('wrong-password');
      } else if (e.toString().contains('requires-recent-login')) {
        throw Exception('requires-recent-login');
      }
      throw Exception('Failed to update user profile data: $e');
    }
  }

  Future<String> _uploadProfileImage(XFile imageFile, String userId) async {
    try {
      final File file = File(imageFile.path);

      // Create optimized metadata for faster upload
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'public, max-age=31536000', // Public cache for 1 year
        customMetadata: {
          'userId': userId,
          'uploadedAt': DateTime.now().toIso8601String(),
          'type': 'profile_image',
          'compressed': 'true', // Indicate this is a compressed image
        },
      );

      // Update path to match storage rules: users/{userId}/profile/{fileName}
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(userId)
          .child('profile')
          .child('profile_image.jpg');

      // Upload with optimized settings
      final UploadTask uploadTask = storageRef.putFile(file, metadata);

      // Wait for upload completion
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      // Provide more specific error messages
      String errorMessage = 'Failed to upload profile image';
      if (e.toString().contains('unauthorized')) {
        errorMessage = 'Upload failed: Unauthorized access';
      } else if (e.toString().contains('network')) {
        errorMessage =
            'Upload failed: Network error. Please check your connection';
      } else if (e.toString().contains('quota')) {
        errorMessage = 'Upload failed: Storage quota exceeded';
      }
      throw Exception('$errorMessage: $e');
    }
  }

  Future<void> updateSocialMediaLinks(
    String userId,
    List<SocialMediaLink> socialMediaLinks,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'socialMediaLinks':
            socialMediaLinks.map((link) => link.toJson()).toList(),
      });

      // Clear cache to force refresh
      _userProfilesCache.remove(userId);
    } catch (e) {
      throw Exception('Failed to update social media links: $e');
    }
  }

  Future<void> updateAboutMe(String userId, String aboutMe) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'aboutMe': aboutMe,
      });

      // Clear cache to force refresh
      _userProfilesCache.remove(userId);
    } catch (e) {
      throw Exception('Failed to update about me: $e');
    }
  }
}
