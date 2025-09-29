import 'package:pivot/features/subjects/services/subjects_service.dart';
import 'package:pivot/models/subject_model.dart';

class SubjectsRepository {
  SubjectsRepository(this._service);

  final SubjectsService _service;

  Future<List<Subject>> getAllSubjects() => _service.getAllSubjects();

  Future<List<Subject>> getSubjectsByUser(String userId) =>
      _service.getSubjectsByUser(userId);

  Future<List<Subject>> getSubjectsByYear(int year) =>
      _service.getSubjectsByYear(year);

  Future<List<Subject>> searchSubjects(String query) =>
      _service.searchSubjects(query);

  Future<List<Subject>> getFilteredSubjects({
    String? searchQuery,
    int? year,
    String? department,
    String? level,
  }) => _service.getFilteredSubjects(
    searchQuery: searchQuery,
    year: year,
    department: department,
    level: level,
  );

  Future<bool> enrollUserInSubject(String userId, String subjectId) =>
      _service.enrollUserInSubject(userId, subjectId);

  Future<bool> unenrollUserFromSubject(String userId, String subjectId) =>
      _service.unenrollUserFromSubject(userId, subjectId);

  Future<bool> updateUserSubjects(String userId, List<String> subjectIds) =>
      _service.updateUserSubjects(userId, subjectIds);

  Future<List<Subject>> getPaginatedSubjects({
    int page = 1,
    int limit = 20,
    String? searchQuery,
    int? year,
    String? department,
    String? level,
  }) => _service.getPaginatedSubjects(
    page: page,
    limit: limit,
    searchQuery: searchQuery,
    year: year,
    department: department,
    level: level,
  );

  Future<List<Subject>> getCachedSubjects() => _service.getCachedSubjects();

  Future<void> cacheSubjects(List<Subject> subjects) =>
      _service.cacheSubjects(subjects);

  Future<void> clearSubjectsCache() => _service.clearSubjectsCache();

  Future<List<int>> getAvailableYears() => _service.getAvailableYears();

  Future<List<String>> getAvailableDepartments() =>
      _service.getAvailableDepartments();

  Future<List<String>> getAvailableLevels() => _service.getAvailableLevels();
}
