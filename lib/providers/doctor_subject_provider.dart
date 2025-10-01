import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/models/lecture_model.dart';
import 'package:pivot/services/doctor_subject_service.dart';

class DoctorSubjectProvider with ChangeNotifier {
  final DoctorSubjectService _service = DoctorSubjectService();

  List<Lecture> _lectures = [];
  bool _isLoading = false;
  String? _error;
  String? _currentSubjectId;

  // Add subject-specific lecture caching
  final Map<String, List<Lecture>> _lecturesBySubject = {};
  final Map<String, bool> _loadingStates = {};
  final Map<String, String?> _errorStates = {};

  List<Lecture> get lectures => _lectures;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get lectures for a specific subject
  List<Lecture> getLecturesForSubject(String subjectId) {
    return _lecturesBySubject[subjectId] ?? [];
  }

  // Get loading state for a specific subject
  bool isSubjectLoading(String subjectId) {
    return _loadingStates[subjectId] ?? false;
  }

  // Get error state for a specific subject
  String? getSubjectError(String subjectId) {
    return _errorStates[subjectId];
  }

  void _safeNotifyListeners() {
    if (SchedulerBinding.instance.schedulerPhase !=
        SchedulerPhase.persistentCallbacks) {
      notifyListeners();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  Future<void> fetchLecturesForSubject(
    String doctorId,
    String subjectId,
  ) async {
    if (doctorId.isEmpty || subjectId.isEmpty) {
      _lectures = [];
      _safeNotifyListeners();
      return;
    }

    _currentSubjectId = subjectId;

    // Check if already loading or already loaded successfully
    if (_loadingStates[subjectId] == true ||
        (_lecturesBySubject.containsKey(subjectId) &&
            _errorStates[subjectId] == null)) {
      // Use cached data
      _lectures = _lecturesBySubject[subjectId] ?? [];
      _safeNotifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    _loadingStates[subjectId] = true;
    _errorStates[subjectId] = null;
    _safeNotifyListeners();

    try {
      final lectures = await _service.getLecturesForDoctorSubject(
        doctorId,
        subjectId,
      );

      // Sort lectures by creation date (newest first)
      lectures.sort((a, b) {
        final aDate = a.createdAt ?? DateTime(1970);
        final bDate = b.createdAt ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });

      // Cache the lectures for this subject
      _lecturesBySubject[subjectId] = lectures;
      _lectures = lectures;
    } catch (e) {
      _error = 'Failed to fetch lectures: ${e.toString()}';
      _errorStates[subjectId] = e.toString();
    } finally {
      _isLoading = false;
      _loadingStates[subjectId] = false;
      _safeNotifyListeners();
    }
  }

  Future<void> refreshLecturesForSubject(
    String doctorId,
    String subjectId,
  ) async {
    if (doctorId.isEmpty || subjectId.isEmpty) return;

    try {
      final lectures = await _service.getLecturesForDoctorSubject(
        doctorId,
        subjectId,
      );

      // Sort lectures by creation date (newest first)
      lectures.sort((a, b) {
        final aDate = a.createdAt ?? DateTime(1970);
        final bDate = b.createdAt ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });

      // Update cache for this subject
      _lecturesBySubject[subjectId] = lectures;

      // Update current lectures if this is the displayed subject
      if (subjectId == _currentSubjectId) {
        _lectures = lectures;
      }

      _safeNotifyListeners();
    } catch (e) {
      _errorStates[subjectId] = e.toString();
      _safeNotifyListeners();
      print('Failed to refresh lectures for subject $subjectId: $e');
    }
  }

  Future<void> addLecture(Lecture lecture) async {
    try {
      final newLecture = await _service.addLecture(lecture);

      // Add to the subject's cache
      if (_lecturesBySubject.containsKey(newLecture.subjectId)) {
        _lecturesBySubject[newLecture.subjectId]!.insert(0, newLecture);
      } else {
        _lecturesBySubject[newLecture.subjectId] = [newLecture];
      }

      // If this is the currently displayed subject, update current lectures
      if (newLecture.subjectId == _currentSubjectId) {
        _lectures = _lecturesBySubject[newLecture.subjectId]!;
      }

      _safeNotifyListeners();
    } catch (e) {
      _error = 'Failed to add lecture: ${e.toString()}';
      _safeNotifyListeners();
    }
  }

  Future<void> deleteLecture(String lectureId) async {
    try {
      await _service.deleteLecture(lectureId);
      _lectures.removeWhere((lecture) => lecture.id == lectureId);
      _safeNotifyListeners();
    } catch (e) {
      _error = 'Failed to delete lecture: ${e.toString()}';
      _safeNotifyListeners();
    }
  }

  Future<void> addLinkToLecture(
    String lectureId,
    Map<String, String> link,
  ) async {
    try {
      await _service.addLinkToLecture(lectureId, link);
      final index = _lectures.indexWhere((lec) => lec.id == lectureId);
      if (index != -1) {
        _lectures[index].links.add(link);
        _safeNotifyListeners();
      }
    } catch (e) {
      _error = 'Failed to add link: ${e.toString()}';
      _safeNotifyListeners();
    }
  }

  Future<void> deleteLinkFromLecture(
    String lectureId,
    Map<String, String> link,
  ) async {
    try {
      await _service.deleteLinkFromLecture(lectureId, link);
      final index = _lectures.indexWhere((lec) => lec.id == lectureId);
      if (index != -1) {
        _lectures[index].links.removeWhere(
          (item) => item['url'] == link['url'],
        );
        _safeNotifyListeners();
      }
    } catch (e) {
      _error = 'Failed to delete link: ${e.toString()}';
      _safeNotifyListeners();
    }
  }
}

// Legacy provider bridge for Riverpod migration
// TODO: Remove this after DoctorSubjectProvider is fully migrated to Riverpod
final legacyDoctorSubjectProviderProvider = Provider<DoctorSubjectProvider>((
  ref,
) {
  return DoctorSubjectProvider();
});
