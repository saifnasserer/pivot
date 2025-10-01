import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/features/user/providers/user_profile_provider.dart';
import 'package:pivot/features/settings/providers/settings_provider.dart';

/// State for Edit Profile screen
class EditProfileState {
  final UserProfile? userProfile;
  final File? profileImage;
  final Map<String, int> sectionCounts;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final bool isFormValid;
  final bool hasSaved;
  final bool hasUnsavedChanges;
  final Map<String, String> fieldErrors;
  final double completionPercentage;
  
  // Individual section unsaved changes
  final bool hasUnsavedProfileImage;
  final bool hasUnsavedBasicInfo;
  final bool hasUnsavedEducationalInfo;
  final bool hasUnsavedPassword;

  const EditProfileState({
    this.userProfile,
    this.profileImage,
    this.sectionCounts = const {},
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.isFormValid = false,
    this.hasSaved = false,
    this.hasUnsavedChanges = false,
    this.fieldErrors = const {},
    this.completionPercentage = 0.0,
    this.hasUnsavedProfileImage = false,
    this.hasUnsavedBasicInfo = false,
    this.hasUnsavedEducationalInfo = false,
    this.hasUnsavedPassword = false,
  });

  EditProfileState copyWith({
    UserProfile? userProfile,
    File? profileImage,
    Map<String, int>? sectionCounts,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool? isFormValid,
    bool? hasSaved,
    bool? hasUnsavedChanges,
    Map<String, String>? fieldErrors,
    double? completionPercentage,
    bool? hasUnsavedProfileImage,
    bool? hasUnsavedBasicInfo,
    bool? hasUnsavedEducationalInfo,
    bool? hasUnsavedPassword,
    bool clearError = false,
  }) {
    return EditProfileState(
      userProfile: userProfile ?? this.userProfile,
      profileImage: profileImage ?? this.profileImage,
      sectionCounts: sectionCounts ?? this.sectionCounts,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isFormValid: isFormValid ?? this.isFormValid,
      hasSaved: hasSaved ?? this.hasSaved,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      hasUnsavedProfileImage: hasUnsavedProfileImage ?? this.hasUnsavedProfileImage,
      hasUnsavedBasicInfo: hasUnsavedBasicInfo ?? this.hasUnsavedBasicInfo,
      hasUnsavedEducationalInfo: hasUnsavedEducationalInfo ?? this.hasUnsavedEducationalInfo,
      hasUnsavedPassword: hasUnsavedPassword ?? this.hasUnsavedPassword,
    );
  }
}

/// Edit Profile provider
final editProfileProvider = StateNotifierProvider.autoDispose<EditProfileNotifier, EditProfileState>((ref) {
  return EditProfileNotifier(ref);
});

/// Edit Profile Notifier
class EditProfileNotifier extends StateNotifier<EditProfileState> {
  EditProfileNotifier(this._ref) : super(const EditProfileState()) {
    // Initialize with existing user profile if available
    final userProfileState = _ref.read(userProfileProvider);
    if (userProfileState.userProfile != null) {
      state = state.copyWith(userProfile: userProfileState.userProfile);
      _validateForm();
    }
  }

  final Ref _ref;

  /// Load user profile and settings
  Future<void> loadProfile() async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      hasSaved: false,
      clearError: true,
    );

    try {
      // Fetch section counts
      await _ref.read(settingsProvider.notifier).fetchSectionCounts();
      final settingsState = _ref.read(settingsProvider);
      
      // Get user profile
      final userProfileState = _ref.read(userProfileProvider);
      final userProfile = userProfileState.userProfile;

      if (userProfile != null) {
        state = state.copyWith(
          userProfile: userProfile,
          sectionCounts: settingsState.sectionCounts,
          isLoading: false,
        );
        _validateForm();
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'فشل في تحميل بيانات المستخدم',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'حدث خطأ أثناء تحميل البيانات: $e',
      );
    }
  }

  /// Update profile image
  void updateProfileImage(File imageFile) {
    state = state.copyWith(
      profileImage: imageFile,
      hasUnsavedProfileImage: true,
    );
    _updateOverallUnsavedChanges();
  }

  /// Update basic info
  void updateBasicInfo(String name, String gender) {
    if (state.userProfile != null) {
      final updatedProfile = state.userProfile!.copyWith(
        name: name,
        gender: gender,
      );
      state = state.copyWith(
        userProfile: updatedProfile,
        hasUnsavedBasicInfo: true,
      );
      _validateForm();
      _updateOverallUnsavedChanges();
    }
  }

  /// Update educational info
  void updateEducationalInfo(String year, String department, String section) {
    if (state.userProfile != null) {
      final updatedProfile = state.userProfile!.copyWith(
        level: year,
        department: department,
        section: section,
      );
      state = state.copyWith(
        userProfile: updatedProfile,
        hasUnsavedEducationalInfo: true,
      );
      _validateForm();
      _updateOverallUnsavedChanges();
    }
  }

  /// Update overall unsaved changes status
  void _updateOverallUnsavedChanges() {
    final hasChanges =
        state.hasUnsavedProfileImage ||
        state.hasUnsavedBasicInfo ||
        state.hasUnsavedEducationalInfo ||
        state.hasUnsavedPassword;
    
    state = state.copyWith(hasUnsavedChanges: hasChanges);
  }

  /// Validate form
  void _validateForm() {
    if (state.userProfile == null) {
      state = state.copyWith(
        isFormValid: false,
        completionPercentage: 0.0,
        fieldErrors: {},
      );
      return;
    }

    final Map<String, String> fieldErrors = {};
    int completedFields = 0;
    const int totalFields = 5; // name, gender, level, department, section

    // Validate name
    if (state.userProfile!.name.isEmpty) {
      fieldErrors['name'] = 'الاسم مطلوب';
    } else if (state.userProfile!.name.length < 2) {
      fieldErrors['name'] = 'الاسم يجب أن يكون حرفين على الأقل';
    } else {
      completedFields++;
    }

    // Validate gender
    if (state.userProfile!.gender.isEmpty) {
      fieldErrors['gender'] = 'النوع مطلوب';
    } else {
      completedFields++;
    }

    // Validate level
    if (state.userProfile!.level.isEmpty) {
      fieldErrors['level'] = 'السنة الدراسية مطلوبة';
    } else {
      completedFields++;
    }

    // Validate department
    if (state.userProfile!.department.isEmpty) {
      fieldErrors['department'] = 'القسم مطلوب';
    } else {
      completedFields++;
    }

    // Validate section
    if (state.userProfile!.section.isEmpty) {
      fieldErrors['section'] = 'الشعبة مطلوبة';
    } else {
      completedFields++;
    }

    final isFormValid = fieldErrors.isEmpty;

    // Calculate completion percentage
    final bool hasProfilePicture =
        state.userProfile!.profileImageUrl != null &&
        state.userProfile!.profileImageUrl!.isNotEmpty;

    final double completionPercentage;
    if (hasProfilePicture) {
      // User has profile picture, so all 5 fields can be completed (100%)
      completionPercentage = completedFields / totalFields;
    } else {
      // User doesn't have profile picture, so max is 80% (4/5)
      double basePercentage = completedFields / totalFields;
      completionPercentage = basePercentage > 0.8 ? 0.8 : basePercentage;
    }

    state = state.copyWith(
      isFormValid: isFormValid,
      fieldErrors: fieldErrors,
      completionPercentage: completionPercentage,
    );
  }

  /// Save profile - intelligently saves only changed sections
  Future<void> saveProfile({
    String? currentPassword,
    String? newPassword,
    String? confirmPassword,
  }) async {
    if (state.userProfile == null || !state.hasUnsavedChanges) return;

    state = state.copyWith(
      isSaving: true,
      errorMessage: null,
      hasSaved: false,
      clearError: true,
    );

    try {
      final Map<String, dynamic> updateData = {};

      // Only include basic info if it has changes
      if (state.hasUnsavedBasicInfo) {
        updateData['name'] = state.userProfile!.name;
        updateData['gender'] = state.userProfile!.gender;
      }

      // Only include educational info if it has changes
      if (state.hasUnsavedEducationalInfo) {
        updateData['level'] = state.userProfile!.level;
        updateData['department'] = state.userProfile!.department;
        updateData['section'] = state.userProfile!.section;
      }

      // Handle password update if provided
      if (newPassword != null && newPassword.isNotEmpty) {
        if (currentPassword == null || currentPassword.isEmpty) {
          state = state.copyWith(
            errorMessage: 'كلمة المرور الحالية مطلوبة لتغيير كلمة المرور',
            isSaving: false,
          );
          return;
        }
        if (newPassword != confirmPassword) {
          state = state.copyWith(
            errorMessage: 'كلمة المرور غير متطابقة',
            isSaving: false,
          );
          return;
        }
        if (newPassword.length < 6) {
          state = state.copyWith(
            errorMessage: 'كلمة المرور يجب أن تكون 6 أحرف على الأقل',
            isSaving: false,
          );
          return;
        }

        updateData['password'] = newPassword;
        updateData['currentPassword'] = currentPassword;
      }

      // Determine if we need to update image
      XFile? imageFile;
      if (state.hasUnsavedProfileImage && state.profileImage != null) {
        imageFile = XFile(state.profileImage!.path);
      }

      // Only call update if there's something to update
      if (updateData.isNotEmpty || imageFile != null) {
        // TODO: Update this to use Riverpod userProfileProvider
        // For now, using legacy provider access through repository
        final userProfileNotifier = _ref.read(userProfileProvider.notifier);
        
        // We need to add updateUserProfileData method to UserProfileNotifier
        // For now, call the repository directly
        await _ref.read(userProfileRepositoryProvider).updateUserProfileData(
          state.userProfile!.id,
          updateData,
          imageFile: imageFile,
        );
        
        // Reload the user profile
        await userProfileNotifier.loadLoggedInUserProfile();
      }

      // Reset all unsaved change flags
      state = state.copyWith(
        hasUnsavedProfileImage: false,
        hasUnsavedBasicInfo: false,
        hasUnsavedEducationalInfo: false,
        hasUnsavedPassword: false,
        hasUnsavedChanges: false,
        isSaving: false,
        hasSaved: true,
      );
      
      _validateForm(); // Recalculate completion percentage
    } catch (e) {
      state = state.copyWith(
        errorMessage: _getErrorMessage(e.toString()),
        isSaving: false,
      );
    }
  }

  /// Mark password as having changes
  void markPasswordAsChanged() {
    state = state.copyWith(hasUnsavedPassword: true);
    _updateOverallUnsavedChanges();
  }

  /// Get specific error message
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

  /// Reset form
  void resetForm() {
    state = state.copyWith(
      profileImage: null,
      errorMessage: null,
      hasSaved: false,
      clearError: true,
    );
    loadProfile();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Clear save status
  void clearSaveStatus() {
    state = state.copyWith(hasSaved: false);
  }

  /// Clear unsaved changes
  void clearUnsavedChanges() {
    state = state.copyWith(hasUnsavedChanges: false);
  }

  /// Get field error
  String? getFieldError(String fieldName) {
    return state.fieldErrors[fieldName];
  }

  /// Check if field has error
  bool hasFieldError(String fieldName) {
    return state.fieldErrors.containsKey(fieldName);
  }
}


