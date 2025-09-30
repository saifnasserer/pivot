import 'package:pivot/models/subject_model.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/services/subject_service.dart';
import 'package:pivot/services/cache_service.dart';
import 'package:pivot/providers/subject_provider.dart';

class SubjectsService {
  final SubjectService _subjectService = SubjectService();
  final UserProfileProvider _userProfileProvider = UserProfileProvider();
  final SubjectProvider _subjectProvider = SubjectProvider();

  Future<List<Subject>> getAllSubjects() async {
    // Use existing SubjectProvider to get all subjects
    await _subjectProvider.fetchAllSubjectsWithoutFilter();
    return _subjectProvider.allSubjects;
  }

  Future<List<Subject>> getSubjectsByUser(String userId) async {
    // Use existing SubjectProvider to get user's enrolled subjects
    final user = await _userProfileProvider.getUserProfileById(userId);
    if (user != null) {
      await _subjectProvider.fetchAndFilterSubjects(user);
      return _subjectProvider.filteredSubjects;
    }
    return [];
  }

  Future<List<Subject>> getSubjectsByYear(int year) async {
    // Get all subjects and filter by year
    final allSubjects = await getAllSubjects();
    return allSubjects.where((s) => s.year == year).toList();
  }

  Future<List<Subject>> searchSubjects(String query) async {
    // Use existing SubjectProvider filtering logic
    final allSubjects = await getAllSubjects();
    final lowercaseQuery = query.toLowerCase();
    return allSubjects
        .where(
          (s) =>
              s.name.toLowerCase().contains(lowercaseQuery) ||
              s.englishName.toLowerCase().contains(lowercaseQuery) ||
              (s.description?.toLowerCase().contains(lowercaseQuery) ?? false),
        )
        .toList();
  }

  Future<List<Subject>> getFilteredSubjects({
    String? searchQuery,
    int? year,
    String? department,
    String? level,
  }) async {
    final allSubjects = await _subjectService.getSubjects();
    var filtered = allSubjects;

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final lowercaseQuery = searchQuery.toLowerCase();
      filtered =
          filtered
              .where(
                (s) =>
                    s.name.toLowerCase().contains(lowercaseQuery) ||
                    s.englishName.toLowerCase().contains(lowercaseQuery) ||
                    (s.description?.toLowerCase().contains(lowercaseQuery) ??
                        false),
              )
              .toList();
    }

    if (year != null) {
      filtered = filtered.where((s) => s.year == year).toList();
    }

    if (department != null && department.isNotEmpty) {
      filtered =
          filtered.where((s) => s.departments.contains(department)).toList();
    }

    return filtered;
  }

  Future<bool> enrollUserInSubject(String userId, String subjectId) async {
    try {
      // Use existing UserProfileProvider method to update user's enrolled subjects
      await _userProfileProvider.updateUserEnrolledSubjects(userId, [
        subjectId,
      ]);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> unenrollUserFromSubject(String userId, String subjectId) async {
    try {
      // Get current user's enrolled subjects and remove the subject
      final user = await _userProfileProvider.getUserProfileById(userId);
      if (user != null) {
        final updatedSubjects =
            user.enrolledSubjects.where((id) => id != subjectId).toList();
        await _userProfileProvider.updateUserEnrolledSubjects(
          userId,
          updatedSubjects,
        );
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateUserSubjects(
    String userId,
    List<String> subjectIds,
  ) async {
    try {
      // Use existing UserProfileProvider method to update user's enrolled subjects
      await _userProfileProvider.updateUserEnrolledSubjects(userId, subjectIds);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<Subject>> getPaginatedSubjects({
    int page = 1,
    int limit = 20,
    String? searchQuery,
    int? year,
    String? department,
    String? level,
  }) async {
    // Get all subjects and apply client-side pagination
    final allSubjects = await _subjectService.getSubjects();

    // Apply filters first
    var filteredSubjects = allSubjects;

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final lowercaseQuery = searchQuery.toLowerCase();
      filteredSubjects =
          filteredSubjects
              .where(
                (s) =>
                    s.name.toLowerCase().contains(lowercaseQuery) ||
                    s.englishName.toLowerCase().contains(lowercaseQuery) ||
                    (s.description?.toLowerCase().contains(lowercaseQuery) ??
                        false),
              )
              .toList();
    }

    if (year != null) {
      filteredSubjects = filteredSubjects.where((s) => s.year == year).toList();
    }

    if (department != null && department.isNotEmpty) {
      filteredSubjects =
          filteredSubjects
              .where((s) => s.departments.contains(department))
              .toList();
    }

    // Apply pagination
    final startIndex = (page - 1) * limit;
    final endIndex = startIndex + limit;

    if (startIndex >= filteredSubjects.length) {
      return [];
    }

    return filteredSubjects.sublist(
      startIndex,
      endIndex > filteredSubjects.length ? filteredSubjects.length : endIndex,
    );
  }

  Future<List<Subject>> getCachedSubjects() async {
    // For now, return empty list as cache service doesn't have getSubjects method
    // This could be implemented with SharedPreferences or Hive for local caching
    return [];
  }

  Future<void> cacheSubjects(List<Subject> subjects) async {
    // For now, do nothing as cache service doesn't have cacheSubjects method
    // This could be implemented with SharedPreferences or Hive for local caching
  }

  Future<void> clearSubjectsCache() async {
    await CacheService.instance.clearAllCache();
  }

  Future<List<int>> getAvailableYears() async {
    final subjects = await getAllSubjects();
    final years = subjects.map((s) => s.year).toSet().toList();
    years.sort();
    return years;
  }

  Future<List<String>> getAvailableDepartments() async {
    final subjects = await getAllSubjects();
    final departments = <String>{};
    for (final subject in subjects) {
      departments.addAll(subject.departments);
    }
    final departmentList = departments.toList();
    departmentList.removeWhere((d) => d.isEmpty);
    departmentList.sort();
    return departmentList;
  }

  Future<List<String>> getAvailableLevels() async {
    // Subject model doesn't have level field, return empty list
    return [];
  }
}
