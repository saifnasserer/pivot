import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show File;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_profile.dart';
import 'package:pivot/services/cache_service.dart';

class UserProfileProvider with ChangeNotifier {
  UserProfile? _userProfile; // The profile being viewed on a profile screen
  UserProfile?
  _loggedInUserProfile; // The profile of the currently authenticated user
  List<UserProfile> _allUsers = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;

  UserProfile? get userProfile => _userProfile;
  UserProfile? get loggedInUserProfile => _loggedInUserProfile;
  List<UserProfile> get allUsers => _allUsers;
  bool get isLoading => _isLoading;

  // Sets the profile to be viewed on a screen
  void setUserProfile(UserProfile profile) {
    _userProfile = profile;
    notifyListeners();
  }

  // Sets the profile for the currently authenticated user
  void setLoggedInUserProfile(UserProfile profile) {
    _loggedInUserProfile = profile;
    debugPrint(
      '[UserProfileProvider] Set logged in user profile: ${profile.name} (${profile.id})',
    );
    notifyListeners();
  }

  void updateUserProfile({
    String? name,
    String? email,
    String? universityId,
    String? department,
    String? level,
    String? profileImageUrl,
  }) {
    if (_loggedInUserProfile != null) {
      _loggedInUserProfile = _loggedInUserProfile!.copyWith(
        name: name,
        email: email,
        department: department,
        level: level,
        profileImageUrl: profileImageUrl,
      );
      notifyListeners();
    }
  }

  void clearProfile() {
    _userProfile = null;
    _loggedInUserProfile = null;
    notifyListeners();
  }

  Future<UserProfile?> updateTeachingSubjects(List<String> subjectIds) async {
    final user = _auth.currentUser;
    if (_loggedInUserProfile != null && user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'teachingSubjects': subjectIds,
        });

        _loggedInUserProfile = _loggedInUserProfile!.copyWith(
          teachingSubjects: subjectIds,
        );

        // Also update the viewed profile if it's the same as the logged-in user
        if (_userProfile?.id == user.uid) {
          _userProfile = _userProfile!.copyWith(teachingSubjects: subjectIds);
        }

        notifyListeners();
        return _loggedInUserProfile;
      } catch (e) {
        print('Failed to update teaching subjects: $e');
        rethrow;
      }
    }
    return null;
  }

  Future<UserProfile?> updateEnrolledSubjects(List<String> subjectIds) async {
    final user = _auth.currentUser;
    if (_loggedInUserProfile != null && user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'enrolledSubjects': subjectIds,
        });

        _loggedInUserProfile = _loggedInUserProfile!.copyWith(
          enrolledSubjects: subjectIds,
        );
        notifyListeners();
        return _loggedInUserProfile;
      } catch (e) {
        print('Failed to update enrolled subjects: $e');
        rethrow;
      }
    }
    return null;
  }

  Future<void> fetchAllUsers() async {
    _isLoading = true;
    notifyListeners();
    try {
      // Step 1: Load from cache first
      final cachedUsers = CacheService.instance.getCachedUsers();
      if (cachedUsers.isNotEmpty) {
        _allUsers = cachedUsers;
        _isLoading = false;
        notifyListeners(); // Notify with cached data
      }

      // Step 2: Fetch from server in the background
      final snapshot = await _firestore.collection('users').get();
      final serverUsers =
          snapshot.docs.map((doc) => UserProfile.fromJson(doc.data())).toList();

      // Step 3: Update UI and cache if new data is available
      if (serverUsers.length != cachedUsers.length) {
        _allUsers = serverUsers;
        await CacheService.instance.cacheUsers(serverUsers);
      }
    } catch (e) {
      print('Failed to fetch all users: $e');
      // Optionally handle the error
    } finally {
      _isLoading = false;
      notifyListeners(); // Notify with final data (or if an error occurred)
    }
  }

  Future<void> updateUserEnrolledSubjects(
    String userId,
    List<String> subjectIds,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'enrolledSubjects': subjectIds,
      });

      final userIndex = _allUsers.indexWhere((user) => user.id == userId);
      if (userIndex != -1) {
        _allUsers[userIndex] = _allUsers[userIndex].copyWith(
          enrolledSubjects: subjectIds,
        );
        notifyListeners();
      }
    } catch (e) {
      print('Failed to update enrolled subjects for user $userId: $e');
      rethrow;
    }
  }

  Future<void> updateAboutMe(String userId, String aboutMe) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'aboutMe': aboutMe,
      });

      if (_userProfile?.id == userId) {
        _userProfile = _userProfile!.copyWith(aboutMe: aboutMe);
      }
      if (_loggedInUserProfile?.id == userId) {
        _loggedInUserProfile = _loggedInUserProfile!.copyWith(aboutMe: aboutMe);
      }
      notifyListeners();
      // Log profile update
      // await ActivityLogService().logAction(
      //   action: 'Profile updated',
      //   details: 'About me updated for user $userId',
      // );
    } catch (e) {
      print('Failed to update about me: $e');
      rethrow;
    }
  }

  Future<void> updateUserProfileData(
    String userId,
    Map<String, dynamic> data, {
    XFile? imageFile,
  }) async {
    try {
      String? imageUrl;
      if (imageFile != null) {
        // Upload image to Firebase Storage
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child('$userId.jpg');

        if (kIsWeb) {
          await storageRef.putData(await imageFile.readAsBytes());
        } else {
          await storageRef.putFile(File(imageFile.path));
        }

        imageUrl = await storageRef.getDownloadURL();
        data['profileImageUrl'] = imageUrl;
      }

      final userRef = _firestore.collection('users').doc(userId);
      await userRef.update(data);

      // Update local cache
      if (_userProfile?.id == userId) {
        _userProfile = _userProfile?.copyWith(
          name: data['name'],
          level: data['level'],
          department: data['department'],
          section: data['section'],
          gender: data['gender'],
          profileImageUrl: imageUrl ?? _userProfile?.profileImageUrl,
        );
      }
      if (_loggedInUserProfile?.id == userId) {
        _loggedInUserProfile = _loggedInUserProfile?.copyWith(
          name: data['name'],
          level: data['level'],
          department: data['department'],
          section: data['section'],
          gender: data['gender'],
          profileImageUrl: imageUrl ?? _loggedInUserProfile?.profileImageUrl,
        );
      }

      notifyListeners();
      // Log profile update
      // await ActivityLogService().logAction(
      //   action: 'Profile updated',
      //   details: 'Profile data updated for user $userId',
      // );
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  Future<bool> loadLoggedInUserProfile() async {
    _isLoading = true;
    notifyListeners();
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('[UserProfileProvider] No current user found');
        clearProfile();
        return false;
      }

      debugPrint('[UserProfileProvider] Loading profile for user: ${user.uid}');
      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists) {
        debugPrint(
          '[UserProfileProvider] Profile document exists, parsing data',
        );
        _loggedInUserProfile = UserProfile.fromJson(doc.data()!);
        _userProfile =
            _loggedInUserProfile; // Also set the default viewed profile
        debugPrint(
          '[UserProfileProvider] Profile loaded successfully: ${_loggedInUserProfile?.name}',
        );
        return true;
      } else {
        debugPrint(
          '[UserProfileProvider] Profile document does not exist for user: ${user.uid}',
        );
        // User authenticated but no profile in Firestore
        clearProfile();
        return false;
      }
    } catch (e) {
      debugPrint(
        '[UserProfileProvider] Failed to load logged-in user profile: $e',
      );
      clearProfile();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
