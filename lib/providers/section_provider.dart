import 'package:flutter/foundation.dart';
import 'package:pivot/models/section_model.dart';
import 'package:pivot/services/section_service.dart';

class SectionProvider with ChangeNotifier {
  final SectionService _sectionService = SectionService();

  List<Section> _sections = [];
  List<String> _currentSubjectIds = [];
  bool _isLoading = false;
  String? _error;

  List<Section> get sections => _sections;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchSectionsForUserSubjects(List<String> subjectIds) async {
    _currentSubjectIds = subjectIds;
    if (subjectIds.isEmpty) {
      _sections = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _sections = await _sectionService.getSectionsForSubjects(subjectIds);
    } catch (e) {
      _error = 'Failed to fetch sections: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addSection(Section section) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _sectionService.addSection(section);
      await fetchSectionsForUserSubjects(_currentSubjectIds);
    } catch (e) {
      _error = 'Failed to add section: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateSection(Section section) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _sectionService.updateSection(section);
      await fetchSectionsForUserSubjects(_currentSubjectIds);
    } catch (e) {
      _error = 'Failed to update section: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteSection(String sectionId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _sectionService.deleteSection(sectionId);
      await fetchSectionsForUserSubjects(_currentSubjectIds);
    } catch (e) {
      _error = 'Failed to delete section: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
