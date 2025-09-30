import 'package:pivot/models/user_profile.dart';
import 'package:pivot/models/subject_model.dart';
import 'package:pivot/models/section_model.dart';
import 'package:pivot/services/auth_service.dart';
import 'package:pivot/services/subject_service.dart';
import 'package:pivot/services/section_service.dart';
import 'package:pivot/services/data_deletion_service.dart';
import 'package:pivot/services/storage_optimization_service.dart';
import 'package:pivot/services/notification_service.dart';

class AdministrationService {
  final AuthService _authService = AuthService();
  final SubjectService _subjectService = SubjectService();
  final SectionService _sectionService = SectionService();
  final StorageOptimizationService _storageService =
      StorageOptimizationService();
  final NotificationService _notificationService = NotificationService();

  // User Management
  Future<List<UserProfile>> getAllUsers() async {
    return await _authService.getAllUsers();
  }

  Future<UserProfile?> getUserById(String userId) async {
    return await _authService.getUserProfile(userId);
  }

  Future<bool> createUser(UserProfile userProfile) async {
    try {
      await _authService.createUserProfile(userProfile);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateUserRole(String userId, String role) async {
    try {
      await _authService.updateUserRole(userId, role);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateUserAboutMe(String userId, String aboutMe) async {
    try {
      await _authService.updateUserAboutMe(userId, aboutMe);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteUser(String userId) async {
    try {
      await _authService.deleteUser(userId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> bulkDeleteUsers(List<String> userIds) async {
    bool allSuccessful = true;
    for (final userId in userIds) {
      try {
        await _authService.deleteUser(userId);
      } catch (e) {
        allSuccessful = false;
      }
    }
    return allSuccessful;
  }

  // Subject Management
  Future<List<Subject>> getAllSubjects() async {
    return await _subjectService.getSubjects();
  }

  Future<Subject?> getSubjectById(String subjectId) async {
    final subjects = await _subjectService.getSubjects();
    try {
      return subjects.firstWhere((s) => s.id == subjectId);
    } catch (e) {
      return null;
    }
  }

  Future<Subject> addSubject(Subject subject) async {
    return await _subjectService.addSubject(subject);
  }

  Future<void> updateSubject(Subject subject) async {
    await _subjectService.updateSubject(subject);
  }

  Future<void> deleteSubject(String subjectId) async {
    await _subjectService.deleteSubject(subjectId);
  }

  // Data Management
  Future<bool> deleteUserData(String userId) async {
    return await DataDeletionService.deleteAllUserData(userId);
  }

  Future<bool> bulkDeleteUserData(List<String> userIds) async {
    bool allSuccessful = true;
    for (final userId in userIds) {
      final success = await DataDeletionService.deleteAllUserData(userId);
      if (!success) allSuccessful = false;
    }
    return allSuccessful;
  }

  // Storage Management
  Future<Map<String, dynamic>> getStorageStats() async {
    return await _storageService.getStorageStats();
  }

  Future<bool> optimizeStorage() async {
    try {
      await _storageService.performFullCleanup();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> clearCache() async {
    try {
      await _storageService.cleanupOrphanedFiles();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Notification Management
  Future<bool> sendNotificationToUser(
    String userId,
    String title,
    String body,
  ) async {
    try {
      // Get user's FCM token first
      final token = await _notificationService.getUserFCMToken(userId);
      if (token == null) return false;

      final success = await _notificationService.sendNotification(
        targetToken: token,
        title: title,
        body: body,
        userId: userId,
      );
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<bool> sendBulkNotification(
    List<String> userIds,
    String title,
    String body,
  ) async {
    try {
      // Get tokens for all users
      final tokens = await _notificationService.getMultipleUserFCMTokens(
        userIds,
      );

      final results = await _notificationService.sendBatchNotifications(
        title: title,
        body: body,
        tokens: tokens,
      );
      return results['success'] == true;
    } catch (e) {
      return false;
    }
  }

  // Search and Filter
  Future<List<UserProfile>> searchUsers(String query) async {
    final allUsers = await getAllUsers();
    final lowercaseQuery = query.toLowerCase();
    return allUsers
        .where(
          (user) =>
              user.name.toLowerCase().contains(lowercaseQuery) ||
              (user.email?.toLowerCase().contains(lowercaseQuery) ?? false) ||
              user.department.toLowerCase().contains(lowercaseQuery) ||
              user.section.toLowerCase().contains(lowercaseQuery),
        )
        .toList();
  }

  Future<List<Subject>> searchSubjects(String query) async {
    final allSubjects = await getAllSubjects();
    final lowercaseQuery = query.toLowerCase();
    return allSubjects
        .where(
          (subject) =>
              subject.name.toLowerCase().contains(lowercaseQuery) ||
              subject.englishName.toLowerCase().contains(lowercaseQuery) ||
              (subject.description?.toLowerCase().contains(lowercaseQuery) ??
                  false),
        )
        .toList();
  }

  Future<List<UserProfile>> getUsersByRole(String role) async {
    final allUsers = await getAllUsers();
    return allUsers.where((user) => user.role == role).toList();
  }

  Future<List<Subject>> getSubjectsByYear(int year) async {
    final allSubjects = await getAllSubjects();
    return allSubjects.where((subject) => subject.year == year).toList();
  }

  // Section Management
  Future<List<Section>> getAllSections() async {
    return await _sectionService.getAllSections();
  }

  Future<List<Section>> getSectionsForAssistant(String assistantId) async {
    return await _sectionService.getSectionsForAssistant(assistantId);
  }

  Future<List<Section>> getSectionsForSubjects(List<String> subjectIds) async {
    return await _sectionService.getSectionsForSubjects(subjectIds);
  }
}
