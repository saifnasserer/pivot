import 'package:pivot/features/administration/services/administration_service.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/models/subject_model.dart';
import 'package:pivot/models/section_model.dart';

class AdministrationRepository {
  AdministrationRepository(this._service);

  final AdministrationService _service;

  // User Management
  Future<List<UserProfile>> getAllUsers() => _service.getAllUsers();

  Future<UserProfile?> getUserById(String userId) =>
      _service.getUserById(userId);

  Future<bool> createUser(UserProfile userProfile) =>
      _service.createUser(userProfile);

  Future<bool> updateUserRole(String userId, String role) =>
      _service.updateUserRole(userId, role);

  Future<bool> updateUserAboutMe(String userId, String aboutMe) =>
      _service.updateUserAboutMe(userId, aboutMe);

  Future<bool> deleteUser(String userId) => _service.deleteUser(userId);

  Future<bool> bulkDeleteUsers(List<String> userIds) =>
      _service.bulkDeleteUsers(userIds);

  // Subject Management
  Future<List<Subject>> getAllSubjects() => _service.getAllSubjects();

  Future<Subject?> getSubjectById(String subjectId) =>
      _service.getSubjectById(subjectId);

  Future<Subject> addSubject(Subject subject) => _service.addSubject(subject);

  Future<void> updateSubject(Subject subject) =>
      _service.updateSubject(subject);

  Future<void> deleteSubject(String subjectId) =>
      _service.deleteSubject(subjectId);

  // Data Management
  Future<bool> deleteUserData(String userId) => _service.deleteUserData(userId);

  Future<bool> bulkDeleteUserData(List<String> userIds) =>
      _service.bulkDeleteUserData(userIds);

  // Storage Management
  Future<Map<String, dynamic>> getStorageStats() => _service.getStorageStats();

  Future<bool> optimizeStorage() => _service.optimizeStorage();

  Future<bool> clearCache() => _service.clearCache();

  // Notification Management
  Future<bool> sendNotificationToUser(
    String userId,
    String title,
    String body,
  ) => _service.sendNotificationToUser(userId, title, body);

  Future<bool> sendBulkNotification(
    List<String> userIds,
    String title,
    String body,
  ) => _service.sendBulkNotification(userIds, title, body);

  // Search and Filter
  Future<List<UserProfile>> searchUsers(String query) =>
      _service.searchUsers(query);

  Future<List<Subject>> searchSubjects(String query) =>
      _service.searchSubjects(query);

  Future<List<UserProfile>> getUsersByRole(String role) =>
      _service.getUsersByRole(role);

  Future<List<Subject>> getSubjectsByYear(int year) =>
      _service.getSubjectsByYear(year);

  // Section Management
  Future<List<Section>> getAllSections() => _service.getAllSections();

  Future<List<Section>> getSectionsForAssistant(String assistantId) =>
      _service.getSectionsForAssistant(assistantId);

  Future<List<Section>> getSectionsForSubjects(List<String> subjectIds) =>
      _service.getSectionsForSubjects(subjectIds);
}
