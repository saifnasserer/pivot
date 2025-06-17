import 'package:flutter/foundation.dart';
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

  Future<void> fetchLecturesForSubject(String doctorId, String subjectId) async {
    if (doctorId.isEmpty || subjectId.isEmpty) {
      _lectures = [];
      notifyListeners();
      return;
    }
    _currentSubjectId = subjectId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _lectures = await _service.getLecturesForDoctorSubject(doctorId, subjectId);
    } catch (e) {
      _error = 'Failed to fetch lectures: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addLecture(Lecture lecture) async {
    try {
      final newLecture = await _service.addLecture(lecture);
      if (newLecture.subjectId == _currentSubjectId) {
        _lectures.add(newLecture);
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to add lecture: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> deleteLecture(String lectureId) async {
    try {
      await _service.deleteLecture(lectureId);
      _lectures.removeWhere((lecture) => lecture.id == lectureId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete lecture: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> addLinkToLecture(String lectureId, Map<String, String> link) async {
    try {
      await _service.addLinkToLecture(lectureId, link);
      final index = _lectures.indexWhere((lec) => lec.id == lectureId);
      if (index != -1) {
        _lectures[index].links.add(link);
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to add link: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> deleteLinkFromLecture(String lectureId, Map<String, String> link) async {
    try {
      await _service.deleteLinkFromLecture(lectureId, link);
      final index = _lectures.indexWhere((lec) => lec.id == lectureId);
      if (index != -1) {
        _lectures[index].links.removeWhere((item) => item['url'] == link['url']);
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to delete link: ${e.toString()}';
      notifyListeners();
    }
  }
}
