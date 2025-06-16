import 'package:flutter/foundation.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/models/subject_model.dart';
import 'package:pivot/services/subject_service.dart';

class SubjectProvider with ChangeNotifier {
  final SubjectService _subjectService = SubjectService();

  List<Subject> _allSubjects = [];
  List<Subject> _filteredSubjects = [];
  bool _isLoading = false;
  String? _error;

  List<Subject> get allSubjects => _allSubjects;
  List<Subject> get filteredSubjects => _filteredSubjects;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Map<String, List<UserProfile>> _instructorsBySubject = {};
  Map<String, List<UserProfile>> get instructorsBySubject =>
      _instructorsBySubject;

  void buildInstructorsMap(List<UserProfile> allUsers) {
    _instructorsBySubject.clear();
    final instructors =
        allUsers
            .where(
              (user) =>
                  user.role.toLowerCase() == 'professor' ||
                  user.role.toLowerCase() == 'miniprofessor' ||
                  user.role.toLowerCase() == 'doctor',
            )
            .toList();

    for (final instructor in instructors) {
      for (final subjectId in instructor.teachingSubjects) {
        if (_instructorsBySubject.containsKey(subjectId)) {
          if (!_instructorsBySubject[subjectId]!.any(
            (u) => u.id == instructor.id,
          )) {
            _instructorsBySubject[subjectId]!.add(instructor);
          }
        } else {
          _instructorsBySubject[subjectId] = [instructor];
        }
      }
    }
    notifyListeners();
  }

  Future<void> fetchAllSubjects() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _allSubjects = await _subjectService.getSubjects();
    } catch (e) {
      _error = 'Failed to fetch all subjects: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addSubject(Subject subject) async {
    try {
      final newSubject = await _subjectService.addSubject(subject);
      _allSubjects.add(newSubject);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add subject: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateSubject(Subject subject) async {
    try {
      await _subjectService.updateSubject(subject);
      final index = _allSubjects.indexWhere((s) => s.id == subject.id);
      if (index != -1) {
        _allSubjects[index] = subject;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update subject: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteSubject(String subjectId) async {
    try {
      await _subjectService.deleteSubject(subjectId);
      _allSubjects.removeWhere((s) => s.id == subjectId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete subject: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> fetchAndFilterSubjects(UserProfile? userProfile) async {
    if (userProfile == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _allSubjects = await _subjectService.getSubjects();

      List<String> userSubjectIds = [];
      if (userProfile.role == 'Student') {
        userSubjectIds = userProfile.enrolledSubjects;
      } else if (userProfile.role.toLowerCase() == 'professor' ||
          userProfile.role.toLowerCase() == 'miniprofessor' ||
          userProfile.role.toLowerCase() == 'doctor') {
        userSubjectIds = userProfile.teachingSubjects;
      }

      if (userSubjectIds.isNotEmpty) {
        _filteredSubjects =
            _allSubjects
                .where((subject) => userSubjectIds.contains(subject.id))
                .toList();
      } else {
        // If the user has no subjects, show an empty list.
        _filteredSubjects = [];
      }
    } catch (e) {
      _error = 'Failed to fetch subjects: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
