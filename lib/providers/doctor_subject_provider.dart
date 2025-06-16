import 'package:flutter/foundation.dart';
import 'package:pivot/models/lecture_model.dart';
import 'package:pivot/services/doctor_subject_service.dart';

class DoctorSubjectProvider with ChangeNotifier {
  final DoctorSubjectService _service = DoctorSubjectService();

  Map<String, List<Lecture>> _lecturesByCategory = {};
  List<String> _currentCategories = [];
  bool _isLoading = false;
  String? _error;
  String? _currentDoctorId;

  Map<String, List<Lecture>> get lecturesByCategory => _lecturesByCategory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchLecturesForDoctor(String doctorId, List<String> categories) async {
    _currentDoctorId = doctorId;
    _currentCategories = categories;
    if (doctorId.isEmpty || categories.isEmpty) {
      _lecturesByCategory = {};
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      Map<String, List<Lecture>> newLectures = {};
      for (String category in categories) {
        newLectures[category] = await _service.getLecturesForDoctorCategory(doctorId, category);
      }
      _lecturesByCategory = newLectures;
    } catch (e) {
      _error = 'Failed to fetch lectures: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addLecture(Lecture lecture) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.addLecture(lecture);
      if (_currentDoctorId != null) {
        await fetchLecturesForDoctor(_currentDoctorId!, _currentCategories);
      }
    } catch (e) {
      _error = 'Failed to add lecture: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteLecture(String lectureId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.deleteLecture(lectureId);
      if (_currentDoctorId != null) {
        await fetchLecturesForDoctor(_currentDoctorId!, _currentCategories);
      }
    } catch (e) {
      _error = 'Failed to delete lecture: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addLinkToLecture(String lectureId, Map<String, String> link) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.addLinkToLecture(lectureId, link);
      if (_currentDoctorId != null) {
        await fetchLecturesForDoctor(_currentDoctorId!, _currentCategories);
      }
    } catch (e) {
      _error = 'Failed to add link: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteLinkFromLecture(String lectureId, Map<String, String> link) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.deleteLinkFromLecture(lectureId, link);
      if (_currentDoctorId != null) {
        await fetchLecturesForDoctor(_currentDoctorId!, _currentCategories);
      }
    } catch (e) {
      _error = 'Failed to delete link: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
