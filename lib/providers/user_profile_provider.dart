import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_profile.dart';
import 'package:pivot/services/session_management_service.dart';
import 'package:pivot/services/storage_optimization_service.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:hive/hive.dart';

class UserProfileProvider with ChangeNotifier {
  UserProfile? _userProfile; // The profile being viewed on a profile screen
  UserProfile?
  _loggedInUserProfile; // The profile of the currently authenticated user
  List<UserProfile> _allUsers = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Map<String, UserProfile> _userProfilesCache = {};
  final String _profilePicsBoxName = 'userProfilePicsBox';
  Box? _profilePicsBox;
  bool _isLoading = false;
  String? _error;

  UserProfile? get userProfile => _userProfile;
  UserProfile? get loggedInUserProfile => _loggedInUserProfile;
  List<UserProfile> get allUsers => _allUsers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Add cache getter
  Map<String, UserProfile> get userProfilesCache => _userProfilesCache;

  // Add method to get user profile by ID
  Future<UserProfile?> getUserProfileById(String userId) async {
    // Try Hive cache for profile pic
    _profilePicsBox ??= await Hive.openBox(_profilePicsBoxName);
    String? cachedPic = _profilePicsBox?.get(userId);
    if (_userProfilesCache.containsKey(userId)) {
      // If we have a cached UserProfile, but no profileImageUrl, update it from Hive
      if (cachedPic != null &&
          _userProfilesCache[userId]?.profileImageUrl != cachedPic) {
        _userProfilesCache[userId] = _userProfilesCache[userId]!.copyWith(
          profileImageUrl: cachedPic,
        );
      }
      return _userProfilesCache[userId];
    }

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

      if (!doc.exists) {
        return null;
      }

      final profile = UserProfile.fromJson(doc.data()!);
      _userProfilesCache[userId] = profile;
      // Cache profile pic in Hive
      if (profile.profileImageUrl != null &&
          profile.profileImageUrl!.isNotEmpty) {
        _profilePicsBox?.put(userId, profile.profileImageUrl);
      }
      return profile;
    } catch (e) {
      //debugprint('Error fetching user profile: $e');
      return null;
    }
  }

  // Sets the profile to be viewed on a screen
  void setUserProfile(UserProfile profile) {
    _userProfile = profile;
    notifyListeners();
  }

  // Sets the profile for the currently authenticated user
  void setLoggedInUserProfile(UserProfile profile) {
    _loggedInUserProfile = profile;
    //debugprint(
    //   '[UserProfileProvider] Set logged in user profile: ${profile.name} (${profile.id})',
    // );
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

  Future<void> fetchAllUsers({
    bool forceAll = false,
    List<String>? roleFilter,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      if (forceAll) {
        Query query = _firestore.collection('users');
        if (roleFilter != null && roleFilter.isNotEmpty) {
          query = query.where('role', whereIn: roleFilter);
        }
        final snapshot = await query.get();
        _allUsers =
            snapshot.docs
                .map(
                  (doc) =>
                      UserProfile.fromJson(doc.data() as Map<String, dynamic>),
                )
                .toList();
      } else {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          _allUsers = [UserProfile.fromJson(doc.data()!)];
        }
      }
      notifyListeners();
    } catch (e) {
      print('Failed to fetch user(s): $e');
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

  Future<void> updateUserTeachingSubjects(
    String userId,
    List<String> subjectIds,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'teachingSubjects': subjectIds,
      });

      final userIndex = _allUsers.indexWhere((user) => user.id == userId);
      if (userIndex != -1) {
        _allUsers[userIndex] = _allUsers[userIndex].copyWith(
          teachingSubjects: subjectIds,
        );
        notifyListeners();
      }

      // Also update the displayed profile if it's the same user
      if (_userProfile?.id == userId) {
        _userProfile = _userProfile!.copyWith(teachingSubjects: subjectIds);
        notifyListeners();
      }
    } catch (e) {
      print('Failed to update teaching subjects for user $userId: $e');
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
    BuildContext? context,
  }) async {
    try {
      // Handle password update if present
      if (data.containsKey('password')) {
        final newPassword = data['password'] as String;
        final currentPassword = data['currentPassword'] as String?;
        data.remove('password');
        data.remove('currentPassword');

        final user = _auth.currentUser;
        if (user != null &&
            currentPassword != null &&
            currentPassword.isNotEmpty) {
          // Use session management service for password changes
          if (context != null) {
            final sessionService = SessionManagementService();
            final validationResult = await sessionService
                .validateSessionForSensitiveOperation(context, currentPassword);

            if (!validationResult.isValid) {
              // Handle different validation errors
              switch (validationResult.error) {
                case SessionValidationError.wrongPassword:
                  throw Exception('wrong-password');
                case SessionValidationError.sessionExpired:
                  throw Exception('requires-recent-login');
                case SessionValidationError.cancelled:
                  throw Exception('operation-cancelled');
                default:
                  throw Exception('session-validation-failed');
              }
            }
          } else {
            // Fallback to direct re-authentication if no context provided
            try {
              final credential = EmailAuthProvider.credential(
                email: user.email!,
                password: currentPassword,
              );
              await user.reauthenticateWithCredential(credential);
            } catch (e) {
              if (e.toString().contains('wrong-password')) {
                throw Exception('wrong-password');
              }
              rethrow;
            }
          }

          // Update password
          await user.updatePassword(newPassword);
        }
      }

      String? imageUrl;
      if (imageFile != null) {
        // Use the optimized storage service for profile images
        final storageService = StorageOptimizationService();
        final xFile = XFile(imageFile.path);
        imageUrl = await storageService.uploadFileOptimized(
          xFile,
          folder: 'profile_images',
          usage: 'profile',
          checkDuplicate: true,
        );

        if (imageUrl != null) {
          data['profileImageUrl'] = imageUrl;
        }
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

  Future<bool> loadLoggedInUserProfile({bool notifyImmediately = true}) async {
    _isLoading = true;
    if (notifyImmediately) notifyListeners();

    try {
      final user = _auth.currentUser;
      if (user == null) {
        clearProfile();
        return false;
      }

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              throw TimeoutException('Fetching user profile timed out');
            },
          );

      if (doc.exists) {
        _loggedInUserProfile = UserProfile.fromJson(doc.data()!);
        _userProfile = _loggedInUserProfile;

        Future(() {
          _cleanupInvalidProfileImageUrl(user.uid).catchError((e) {});
          _triggerOneTimeCleanup().catchError((e) {});
        });

        return true;
      } else {
        clearProfile();
        return false;
      }
    } catch (e) {
      if (e is TimeoutException) {
        debugPrint('[UserProfileProvider] Timeout loading profile');
      } else if (e is FirebaseException && e.code == 'permission-denied') {
        debugPrint('[UserProfileProvider] Permission denied loading profile');
      } else {
        debugPrint('[UserProfileProvider] Error loading profile: $e');
      }
      clearProfile();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Track if cleanup has been run to avoid running it multiple times
  static bool _cleanupRun = false;

  /// Trigger one-time cleanup of all invalid profile image URLs
  Future<void> _triggerOneTimeCleanup() async {
    if (_cleanupRun) return; // Only run once per app session

    _cleanupRun = true;

    // Run cleanup in the background without blocking the UI
    Future.microtask(() async {
      try {
        await cleanupAllInvalidProfileImageUrls();
      } catch (e) {
        //debugprint('[UserProfileProvider] Background cleanup failed: $e');
      }
    });
  }

  /// Cleans up invalid profile image URLs from the database
  Future<void> _cleanupInvalidProfileImageUrl(String userId) async {
    try {
      if (_loggedInUserProfile?.profileImageUrl != null &&
          _loggedInUserProfile!.profileImageUrl!.isNotEmpty) {
        // Check if the image URL is accessible
        bool isValid = await _isImageUrlAccessible(
          _loggedInUserProfile!.profileImageUrl!,
        );

        if (!isValid) {
          //debugprint(
          //   '[UserProfileProvider] Invalid profile image URL detected, cleaning up...',
          // );

          // Remove the invalid URL from the database
          await _firestore.collection('users').doc(userId).update({
            'profileImageUrl': null,
          });

          // Update local cache
          _loggedInUserProfile = _loggedInUserProfile!.copyWith(
            profileImageUrl: null,
          );
          _userProfile = _userProfile?.copyWith(profileImageUrl: null);
          notifyListeners();

          //debugprint(
          //   '[UserProfileProvider] Invalid profile image URL cleaned up',
          // );
        }
      }
    } catch (e) {
      //debugprint(
      //   '[UserProfileProvider] Error cleaning up invalid profile image URL: $e',
      // );
    }
  }

  /// Check if an image URL is accessible without throwing exceptions
  Future<bool> _isImageUrlAccessible(String url) async {
    try {
      final client = HttpClient();
      try {
        final request = await client.getUrl(Uri.parse(url));
        final response = await request.close();

        // Only consider 404 (Not Found) as invalid
        // Other status codes (200, 403, 500, etc.) or network errors should not cause removal
        if (response.statusCode == 404) {
          //debugprint('[UserProfileProvider] Image URL returned 404: $url');
          return false;
        }

        // For any other status code or successful response, consider it valid
        return true;
      } finally {
        client.close();
      }
    } catch (e) {
      // Network errors, timeouts, etc. should not cause URL removal
      // Only log the error but return true to keep the URL
      //debugprint(
      //   '[UserProfileProvider] Network error checking URL (keeping URL): $url - $e',
      // );
      return true;
    }
  }

  /// Public method to clean up invalid profile image URLs for all users
  Future<void> cleanupAllInvalidProfileImageUrls() async {
    try {
      //debugprint(
      //   '[UserProfileProvider] Starting cleanup of invalid profile image URLs...',
      // );

      final snapshot = await _firestore.collection('users').get();
      int cleanedCount = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final profileImageUrl = data['profileImageUrl'] as String?;

        if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
          bool isValid = await _isImageUrlAccessible(profileImageUrl);

          if (!isValid) {
            await _firestore.collection('users').doc(doc.id).update({
              'profileImageUrl': null,
            });
            cleanedCount++;
            //debugprint(
            //   '[UserProfileProvider] Cleaned invalid URL for user: ${doc.id}',
            // );
          }
        }
      }

      //debugprint(
      //   '[UserProfileProvider] Cleanup completed. Removed $cleanedCount invalid URLs.',
      // );

      // Refresh the current user's profile if they were affected
      if (_loggedInUserProfile != null) {
        await loadLoggedInUserProfile();
      }
    } catch (e) {
      //debugprint('[UserProfileProvider] Error during bulk cleanup: $e');
    }
  }
}
