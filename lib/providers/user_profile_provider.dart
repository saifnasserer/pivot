import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';

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

  Future<void> updateTeachingSubjects(List<String> subjectIds) async {
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
      } catch (e) {
        print('Failed to update teaching subjects: $e');
        rethrow;
      }
    }
  }

  Future<void> updateEnrolledSubjects(List<String> subjectIds) async {
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
      } catch (e) {
        print('Failed to update enrolled subjects: $e');
        rethrow;
      }
    }
  }

  Future<void> fetchAllUsers() async {
    _isLoading = true;
    notifyListeners();
    try {
      final snapshot = await _firestore.collection('users').get();
      _allUsers =
          snapshot.docs.map((doc) => UserProfile.fromJson(doc.data())).toList();
    } catch (e) {
      print('Failed to fetch all users: $e');
      // Optionally handle the error
    } finally {
      _isLoading = false;
      notifyListeners();
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
    } catch (e) {
      print('Failed to update about me: $e');
      rethrow;
    }
  }

  Future<bool> loadLoggedInUserProfile() async {
    _isLoading = true;
    notifyListeners();
    try {
      final user = _auth.currentUser;
      if (user == null) {
        clearProfile();
        return false;
      }
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        _loggedInUserProfile = UserProfile.fromJson(doc.data()!);
        _userProfile =
            _loggedInUserProfile; // Also set the default viewed profile
        return true;
      } else {
        // User authenticated but no profile in Firestore
        clearProfile();
        return false;
      }
    } catch (e) {
      print('Failed to load logged-in user profile: $e');
      clearProfile();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
