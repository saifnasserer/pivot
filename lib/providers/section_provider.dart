import 'package:flutter/foundation.dart';
import 'package:pivot/models/section_model.dart';
import 'package:pivot/services/section_service.dart';
import 'package:pivot/services/cache_service.dart';

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
      // Step 1: Load from cache first
      final cachedSections = CacheService.instance.getCachedSections();
      final filteredCached =
          cachedSections
              .where((s) => subjectIds.contains(s.subjectId))
              .toList();
      if (filteredCached.isNotEmpty) {
        _sections = filteredCached;
        _isLoading = false;
        notifyListeners();
      }

      // Step 2: Fetch from server in the background
      _sections = await _sectionService.getSectionsForSubjects(subjectIds);
      await CacheService.instance.cacheSections(_sections);
    } catch (e) {
      _error = 'Failed to fetch sections: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addSection(Section section) async {
    try {
      final newSection = await _sectionService.addSection(section);
      _sections.add(newSection);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add section: ${e.toString()}';
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
