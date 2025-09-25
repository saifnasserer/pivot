import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'package:pivot/models/user_profile.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/providers/settings_provider.dart';

// Edit Profile Provider for State Management
class EditProfileProvider extends ChangeNotifier {
  final UserProfileProvider _userProfileProvider;
  final SettingsProvider _settingsProvider;

  EditProfileProvider({
    required UserProfileProvider userProfileProvider,
    required SettingsProvider settingsProvider,
  }) : _userProfileProvider = userProfileProvider,
       _settingsProvider = settingsProvider;

  // State variables
  UserProfile? _userProfile;
  File? _profileImage;
  Map<String, int> _sectionCounts = {};
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  bool _isFormValid = false;
  bool _hasSaved = false;

  // Getters
  UserProfile? get userProfile => _userProfile;
  File? get profileImage => _profileImage;
  Map<String, int> get sectionCounts => _sectionCounts;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  bool get isFormValid => _isFormValid;
  bool get hasSaved => _hasSaved;

  // Load user profile and settings
  Future<void> loadProfile() async {
    _isLoading = true;
    _errorMessage = null;
    _hasSaved = false;
    notifyListeners();

    try {
      await _settingsProvider.fetchSectionCounts();
      _sectionCounts = _settingsProvider.sectionCounts;
      _userProfile = _userProfileProvider.userProfile;

      if (_userProfile != null) {
        _validateForm();
      } else {
        _errorMessage = 'فشل في تحميل بيانات المستخدم';
      }
    } catch (e) {
      _errorMessage = 'حدث خطأ أثناء تحميل البيانات: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update profile image
  void updateProfileImage(File imageFile) {
    _profileImage = imageFile;
    notifyListeners();
  }

  // Update basic info
  void updateBasicInfo(String name, String gender) {
    if (_userProfile != null) {
      _userProfile = _userProfile!.copyWith(name: name, gender: gender);
      _validateForm();
      notifyListeners();
    }
  }

  // Update educational info
  void updateEducationalInfo(String year, String department, String section) {
    if (_userProfile != null) {
      _userProfile = _userProfile!.copyWith(
        level: year,
        department: department,
        section: section,
      );
      _validateForm();
      notifyListeners();
    }
  }

  // Validate form
  void _validateForm() {
    if (_userProfile == null) {
      _isFormValid = false;
      return;
    }

    _isFormValid =
        _userProfile!.name.isNotEmpty &&
        _userProfile!.gender.isNotEmpty &&
        _userProfile!.level.isNotEmpty &&
        _userProfile!.department.isNotEmpty &&
        _userProfile!.section.isNotEmpty;
  }

  // Save profile
  Future<void> saveProfile({
    String? currentPassword,
    String? newPassword,
    String? confirmPassword,
  }) async {
    if (_userProfile == null) return;

    _isSaving = true;
    _errorMessage = null;
    _hasSaved = false;
    notifyListeners();

    try {
      final Map<String, dynamic> updateData = {
        'name': _userProfile!.name,
        'gender': _userProfile!.gender,
        'level': _userProfile!.level,
        'department': _userProfile!.department,
        'section': _userProfile!.section,
      };

      // Handle password update if provided
      if (newPassword != null && newPassword.isNotEmpty) {
        if (currentPassword == null || currentPassword.isEmpty) {
          _errorMessage = 'كلمة المرور الحالية مطلوبة لتغيير كلمة المرور';
          _isSaving = false;
          notifyListeners();
          return;
        }
        if (newPassword != confirmPassword) {
          _errorMessage = 'كلمة المرور غير متطابقة';
          _isSaving = false;
          notifyListeners();
          return;
        }
        if (newPassword.length < 6) {
          _errorMessage = 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
          _isSaving = false;
          notifyListeners();
          return;
        }

        updateData['password'] = newPassword;
        updateData['currentPassword'] = currentPassword;
      }

      // Check if profile image exists
      if (_profileImage != null) {
        final imageFile = XFile(_profileImage!.path);
      } else {}

      await _userProfileProvider.updateUserProfileData(
        _userProfile!.id,
        updateData,
        imageFile: _profileImage != null ? XFile(_profileImage!.path) : null,
      );

      _isSaving = false;
      _hasSaved = true;
      notifyListeners();
    } catch (e) {
      _errorMessage = _getErrorMessage(e.toString());
      _isSaving = false;
      notifyListeners();
    }
  }

  // Get specific error message
  String _getErrorMessage(String error) {
    if (error.contains('requires-recent-login')) {
      return 'انتهت صلاحية الجلسة. يرجى إعادة تسجيل الدخول';
    } else if (error.contains('wrong-password')) {
      return 'كلمة المرور الحالية غير صحيحة';
    } else if (error.contains('weak-password')) {
      return 'كلمة المرور ضعيفة جداً';
    } else if (error.contains('operation-cancelled')) {
      return 'تم إلغاء العملية';
    } else {
      return 'فشل في حفظ التغييرات';
    }
  }

  // Reset form
  void resetForm() {
    _profileImage = null;
    _errorMessage = null;
    _hasSaved = false;
    loadProfile();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Clear save status
  void clearSaveStatus() {
    _hasSaved = false;
    notifyListeners();
  }
}
