import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/models/subject_model.dart';
import 'package:pivot/services/subject_service.dart';
import 'package:pivot/services/cache_service.dart';

class SubjectProvider with ChangeNotifier {
  final SubjectService _subjectService = SubjectService();

  List<Subject> _allSubjects = [];
  List<Subject> _filteredSubjects = [];
  bool _isLoading = false;
  String? _error;
  bool _disposed = false;

  List<Subject> get allSubjects => _allSubjects;
  List<Subject> get filteredSubjects => _filteredSubjects;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final Map<String, List<UserProfile>> _instructorsBySubject = {};
  Map<String, List<UserProfile>> get instructorsBySubject =>
      _instructorsBySubject;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _checkDisposed() {
    if (_disposed) {
      throw StateError('SubjectProvider has been disposed');
    }
  }

  /// Helper method to check if a user is an instructor (professor, miniProfessor, doctor)
  bool _isInstructor(String role) {
    final lowerRole = role.toLowerCase();
    return lowerRole == 'professor' ||
        lowerRole == 'miniprofessor' ||
        role == 'miniProfessor' ||
        lowerRole == 'doctor';
  }

  /// Helper method to check if a user is a student
  bool _isStudent(String role) {
    return role == 'Student';
  }

  void buildInstructorsMap(List<UserProfile> allUsers) {
    _checkDisposed();
    _instructorsBySubject.clear();
    final instructors =
        allUsers.where((user) => _isInstructor(user.role)).toList();

    print('Instructors found:');
    for (final instructor in instructors) {
      print(
        '${instructor.name} (${instructor.role}) teaches: ${instructor.teachingSubjects}',
      );
    }

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
    print('instructorsBySubject map:');
    _instructorsBySubject.forEach((subjectId, instructors) {
      print('Subject $subjectId: ${instructors.map((i) => i.name).toList()}');
    });
    if (!_disposed) {
      notifyListeners();
    }
  }

  Future<void> fetchAllSubjects() async {
    _checkDisposed();
    _isLoading = true;
    _error = null;
    if (!_disposed) {
      notifyListeners();
    }

    try {
      // Step 1: Load from cache first
      final cachedSubjects = CacheService.instance.getCachedSubjects();
      if (cachedSubjects.isNotEmpty) {
        _allSubjects = cachedSubjects;
        if (!_disposed) {
          notifyListeners();
        }
      }

      // Step 2: Fetch from server in the background
      _allSubjects = await _subjectService.getSubjects();
      await CacheService.instance.cacheSubjects(_allSubjects);
    } catch (e) {
      _error = 'Failed to fetch all subjects: ${e.toString()}';
    } finally {
      _isLoading = false;
      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  Future<void> addSubject(Subject subject) async {
    _checkDisposed();
    try {
      final newSubject = await _subjectService.addSubject(subject);
      _allSubjects.add(newSubject);
      if (!_disposed) {
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to add subject: ${e.toString()}';
      if (!_disposed) {
        notifyListeners();
      }
      rethrow;
    }
  }

  Future<void> updateSubject(Subject subject) async {
    _checkDisposed();
    try {
      await _subjectService.updateSubject(subject);
      final index = _allSubjects.indexWhere((s) => s.id == subject.id);
      if (index != -1) {
        _allSubjects[index] = subject;
        if (!_disposed) {
          notifyListeners();
        }
      }
    } catch (e) {
      _error = 'Failed to update subject: ${e.toString()}';
      if (!_disposed) {
        notifyListeners();
      }
      rethrow;
    }
  }

  Future<void> deleteSubject(String subjectId) async {
    _checkDisposed();
    try {
      await _subjectService.deleteSubject(subjectId);
      _allSubjects.removeWhere((s) => s.id == subjectId);
      if (!_disposed) {
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to delete subject: ${e.toString()}';
      if (!_disposed) {
        notifyListeners();
      }
      rethrow;
    }
  }

  Future<void> fetchAndFilterSubjects(UserProfile? userProfile) async {
    _checkDisposed();
    if (userProfile == null) return;

    print(
      'fetchAndFilterSubjects called for user: ${userProfile.name} (${userProfile.role})',
    );
    print('User teaching subjects: ${userProfile.teachingSubjects}');

    _isLoading = true;
    _error = null;
    if (!_disposed) {
      notifyListeners();
    }

    try {
      // For admin users or when we want to show all subjects, fetch all
      if (userProfile.role == 'Admin' || userProfile.role == 'Super Admin') {
        print('User is admin, fetching all subjects');
        _allSubjects = await _subjectService.getSubjects();
        _filteredSubjects = _allSubjects;
      } else {
        List<String> userSubjectIds = [];
        print(
          'User role: "${userProfile.role}" (length: ${userProfile.role.length})',
        );
        print('Role check results:');
        print('  Is instructor: ${_isInstructor(userProfile.role)}');
        print('  Is student: ${_isStudent(userProfile.role)}');

        if (_isStudent(userProfile.role)) {
          userSubjectIds = userProfile.enrolledSubjects;
          print('User is student, enrolled subjects: $userSubjectIds');
        } else if (_isInstructor(userProfile.role)) {
          userSubjectIds = userProfile.teachingSubjects;
          print(
            'User is instructor (professor/doctor/miniProfessor), teaching subjects: $userSubjectIds',
          );
        } else {
          print('User role not recognized: ${userProfile.role}');
          print(
            'Available roles for filtering: professor, miniprofessor, miniProfessor, doctor, student',
          );
        }

        print('Final userSubjectIds: $userSubjectIds');

        if (userSubjectIds.isNotEmpty) {
          // For non-admin users, only fetch the subjects they need
          print('Fetching specific subjects for non-admin user');
          _filteredSubjects = await _subjectService.getSubjectsByIds(
            userSubjectIds,
          );

          // For compatibility with other parts of the app that expect allSubjects,
          // we'll set allSubjects to the same as filteredSubjects for non-admin users
          _allSubjects = _filteredSubjects;

          print('Fetched ${_filteredSubjects.length} subjects for user');
          print(
            'Filtered subjects: ${_filteredSubjects.map((s) => '${s.id}:${s.name}').toList()}',
          );
        } else {
          // If the user has no subjects, show an empty list.
          print('User has no subjects, showing empty list');
          _filteredSubjects = [];
          _allSubjects = [];
        }
      }
    } catch (e) {
      _error = 'Failed to fetch subjects: ${e.toString()}';
      print('Error in fetchAndFilterSubjects: $e');
    } finally {
      _isLoading = false;
      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  /// Optimized method to fetch only specific subjects by IDs
  Future<void> fetchSpecificSubjects(List<String> subjectIds) async {
    _checkDisposed();
    if (subjectIds.isEmpty) {
      _filteredSubjects = [];
      _allSubjects = [];
      if (!_disposed) {
        notifyListeners();
      }
      return;
    }

    _isLoading = true;
    _error = null;
    if (!_disposed) {
      notifyListeners();
    }

    try {
      print('Fetching specific subjects by IDs: $subjectIds');
      _filteredSubjects = await _subjectService.getSubjectsByIds(subjectIds);
      // For consistency, set allSubjects to the same as filteredSubjects
      _allSubjects = _filteredSubjects;
      print('Fetched ${_filteredSubjects.length} specific subjects');
    } catch (e) {
      _error = 'Failed to fetch specific subjects: ${e.toString()}';
      print('Error in fetchSpecificSubjects: $e');
    } finally {
      _isLoading = false;
      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  Future<void> fetchAllSubjectsWithoutFilter() async {
    _checkDisposed();
    _isLoading = true;
    _error = null;
    if (!_disposed) {
      notifyListeners();
    }

    try {
      _allSubjects = await _subjectService.getSubjects();
      _filteredSubjects = _allSubjects; // Show all subjects
    } catch (e) {
      _error = 'Failed to fetch subjects: ${e.toString()}';
    } finally {
      _isLoading = false;
      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  void resetFilter() {
    _checkDisposed();
    // For non-admin users, filteredSubjects and allSubjects are the same
    // For admin users, this will show all subjects
    _filteredSubjects = _allSubjects;
    // Use post-frame callback to avoid build-time notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed) {
        notifyListeners();
      }
    });
  }
}
