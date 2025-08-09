import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:pivot/models/lecture_model.dart';
import 'package:pivot/services/doctor_subject_service.dart';

class DoctorSubjectProvider with ChangeNotifier {
  final DoctorSubjectService _service = DoctorSubjectService();

  List<Lecture> _lectures = [];
  bool _isLoading = false;
  String? _error;
  String? _currentSubjectId;

  List<Lecture> get lectures => _lectures;
  bool get isLoading => _isLoading;
  String? get error => _error;

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
    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      _lectures = await _service.getLecturesForDoctorSubject(
        doctorId,
        subjectId,
      );

      // Sort lectures by creation date (newest first)
      _lectures.sort((a, b) {
        final aDate =
            a.createdAt ?? DateTime(1970); // Fallback for lectures without date
        final bDate =
            b.createdAt ?? DateTime(1970); // Fallback for lectures without date
        return bDate.compareTo(aDate); // Newest first
      });
    } catch (e) {
      _error = 'Failed to fetch lectures: ${e.toString()}';
    } finally {
      _isLoading = false;
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

      // Only update the current list if this is the currently displayed subject
      if (subjectId == _currentSubjectId) {
        // Sort lectures by creation date (newest first)
        lectures.sort((a, b) {
          final aDate =
              a.createdAt ??
              DateTime(1970); // Fallback for lectures without date
          final bDate =
              b.createdAt ??
              DateTime(1970); // Fallback for lectures without date
          return bDate.compareTo(aDate); // Newest first
        });

        _lectures = lectures;
        _safeNotifyListeners();
      }
    } catch (e) {
      // Don't update error state for background refreshes
      print('Failed to refresh lectures for subject $subjectId: $e');
    }
  }

  Future<void> addLecture(Lecture lecture) async {
    try {
      final newLecture = await _service.addLecture(lecture);

      // If the lecture was added to the currently displayed subject, add it to the current list
      if (newLecture.subjectId == _currentSubjectId) {
        _lectures.add(newLecture);
        _safeNotifyListeners();
      }
      // If the lecture was added to a different subject, refresh the lectures for that subject
      else {
        // Refresh the lectures for the subject where the lecture was added
        await refreshLecturesForSubject(lecture.doctorId, newLecture.subjectId);
      }
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
