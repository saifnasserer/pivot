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
       _settingsProvider = settingsProvider {
    // Initialize with existing user profile if available
    _userProfile = _userProfileProvider.userProfile;
    if (_userProfile != null) {
      _validateForm();
    }
  }

  // State variables
  UserProfile? _userProfile;
  File? _profileImage;
  Map<String, int> _sectionCounts = {};
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  bool _isFormValid = false;
  bool _hasSaved = false;
  bool _hasUnsavedChanges = false;
  Map<String, String> _fieldErrors = {};
  double _completionPercentage = 0.0;

  // Getters
  UserProfile? get userProfile => _userProfile;
  File? get profileImage => _profileImage;
  Map<String, int> get sectionCounts => _sectionCounts;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  bool get isFormValid => _isFormValid;
  bool get hasSaved => _hasSaved;
  bool get hasUnsavedChanges => _hasUnsavedChanges;
  Map<String, String> get fieldErrors => _fieldErrors;
  double get completionPercentage => _completionPercentage;

  // Load user profile and settings
  Future<void> loadProfile() async {
    _isLoading = true;
    _errorMessage = null;
    _hasSaved = false;
    notifyListeners();

    try {
      await _settingsProvider.fetchSectionCounts();
      _sectionCounts = _settingsProvider.sectionCounts;

      // Only update user profile if it's not already loaded
      if (_userProfile == null) {
        _userProfile = _userProfileProvider.userProfile;
      }

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
      _hasUnsavedChanges = true;
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
      _hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  // Validate form
  void _validateForm() {
    if (_userProfile == null) {
      _isFormValid = false;
      _completionPercentage = 0.0;
      return;
    }

    _fieldErrors.clear();
    int completedFields = 0;
    int totalFields = 5; // name, gender, level, department, section

    // Validate name
    if (_userProfile!.name.isEmpty) {
      _fieldErrors['name'] = 'الاسم مطلوب';
    } else if (_userProfile!.name.length < 2) {
      _fieldErrors['name'] = 'الاسم يجب أن يكون حرفين على الأقل';
    } else {
      completedFields++;
    }

    // Validate gender
    if (_userProfile!.gender.isEmpty) {
      _fieldErrors['gender'] = 'النوع مطلوب';
    } else {
      completedFields++;
    }

    // Validate level
    if (_userProfile!.level.isEmpty) {
      _fieldErrors['level'] = 'السنة الدراسية مطلوبة';
    } else {
      completedFields++;
    }

    // Validate department
    if (_userProfile!.department.isEmpty) {
      _fieldErrors['department'] = 'القسم مطلوب';
    } else {
      completedFields++;
    }

    // Validate section
    if (_userProfile!.section.isEmpty) {
      _fieldErrors['section'] = 'الشعبة مطلوبة';
    } else {
      completedFields++;
    }

    _isFormValid = _fieldErrors.isEmpty;

    // Calculate completion percentage
    // If user doesn't have a profile picture, max completion is 80% (4/5)
    // If user has a profile picture, max completion is 100% (5/5)
    bool hasProfilePicture =
        _userProfile!.profileImageUrl != null &&
        _userProfile!.profileImageUrl!.isNotEmpty;

    if (hasProfilePicture) {
      // User has profile picture, so all 5 fields can be completed (100%)
      _completionPercentage = completedFields / totalFields;
    } else {
      // User doesn't have profile picture, so max is 80% (4/5)
      // Cap the percentage at 0.8 (80%)
      double basePercentage = completedFields / totalFields;
      _completionPercentage = basePercentage > 0.8 ? 0.8 : basePercentage;
    }
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
      // Image will be handled in the updateUserProfileData call below

      await _userProfileProvider.updateUserProfileData(
        _userProfile!.id,
        updateData,
        imageFile: _profileImage != null ? XFile(_profileImage!.path) : null,
      );

      _isSaving = false;
      _hasSaved = true;
      _hasUnsavedChanges = false;
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

  // Clear unsaved changes
  void clearUnsavedChanges() {
    _hasUnsavedChanges = false;
    notifyListeners();
  }

  // Get field error
  String? getFieldError(String fieldName) {
    return _fieldErrors[fieldName];
  }

  // Check if field has error
  bool hasFieldError(String fieldName) {
    return _fieldErrors.containsKey(fieldName);
  }
}
