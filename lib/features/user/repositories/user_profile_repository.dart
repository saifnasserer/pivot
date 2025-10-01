import 'package:image_picker/image_picker.dart';
import 'package:pivot/features/user/services/user_profile_service.dart';
import 'package:pivot/models/user_profile.dart';

class UserProfileRepository {
  UserProfileRepository(this._service);

  final UserProfileService _service;

  Future<UserProfile?> getLoggedInUserProfile() =>
      _service.getLoggedInUserProfile();

  Future<UserProfile?> getUserProfile(String userId) =>
      _service.getUserProfile(userId);

  Future<List<UserProfile>> getAllUsers() => _service.getAllUsers();

  Future<void> updateUserProfile(UserProfile profile) =>
      _service.updateUserProfile(profile);

  Future<void> updateEnrolledSubjects(List<String> subjectIds) =>
      _service.updateEnrolledSubjects(subjectIds);

  Future<void> updateTeachingSubjects(List<String> subjectIds) =>
      _service.updateTeachingSubjects(subjectIds);

  Future<void> updateUserEnrolledSubjects(
    String userId,
    List<String> subjectIds,
  ) => _service.updateUserEnrolledSubjects(userId, subjectIds);

  Future<void> updateUserTeachingSubjects(
    String userId,
    List<String> subjectIds,
  ) => _service.updateUserTeachingSubjects(userId, subjectIds);

  Future<void> updateUserRole(String userId, String newRole) =>
      _service.updateUserRole(userId, newRole);

  Future<void> deleteUser(String userId) => _service.deleteUser(userId);

  Future<String> uploadProfileImage(String imagePath) =>
      _service.uploadProfileImage(imagePath);

  Future<void> createUserProfile(UserProfile profile) =>
      _service.createUserProfile(profile);

  Future<List<UserProfile>> searchUsers(String query) =>
      _service.searchUsers(query);

  Future<List<UserProfile>> getUsersByRole(String role) =>
      _service.getUsersByRole(role);

  Future<List<UserProfile>> getUsersByDepartment(String department) =>
      _service.getUsersByDepartment(department);

  Future<void> updateAssistantPreferences(Map<String, String> preferences) =>
      _service.updateAssistantPreferences(preferences);

  Future<void> updateUserProfileData(
    String userId,
    Map<String, dynamic> data, {
    XFile? imageFile,
  }) => _service.updateUserProfileData(userId, data, imageFile: imageFile);

  Future<void> updateSocialMediaLinks(
    String userId,
    List<SocialMediaLink> socialMediaLinks,
  ) => _service.updateSocialMediaLinks(userId, socialMediaLinks);

  Future<void> updateAboutMe(String userId, String aboutMe) =>
      _service.updateAboutMe(userId, aboutMe);
}
