import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pivot/models/section_model.dart';
import 'package:pivot/services/section_service.dart';
import 'package:pivot/services/cache_service.dart';

class SectionProvider with ChangeNotifier {
  final SectionService _sectionService = SectionService();

  List<Section> _sections = [];
  String? _currentAssistantId;
  List<String> _currentSubjectIds = [];
  bool _isLoading = false;
  String? _error;
  bool _disposed = false;

  List<Section> get sections => _sections;
  bool get isLoading => _isLoading;
  String? get error => _error;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  // Fetch sections for a specific assistant
  Future<void> fetchSectionsForAssistant(String assistantId) async {
    _currentAssistantId = assistantId;
    if (assistantId.isEmpty) {
      _sections = [];
      _safeNotifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      // Step 1: Load from cache first
      final cachedSections = CacheService.instance.getCachedSections();
      final filteredCached =
          cachedSections.where((s) => s.assistantId == assistantId).toList();
      if (filteredCached.isNotEmpty) {
        _sections = filteredCached;
        _isLoading = false;
        _safeNotifyListeners();
      }

      // Step 2: Fetch from server in the background
      _sections = await _sectionService.getSectionsForAssistant(assistantId);
      await CacheService.instance.cacheSections(_sections);
    } catch (e) {
      _error = 'Failed to fetch sections: ${e.toString()}';
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  // Fetch sections for subjects (for backward compatibility and student views)
  Future<void> fetchSectionsForUserSubjects(List<String> subjectIds) async {
    _currentSubjectIds = subjectIds;
    if (subjectIds.isEmpty) {
      _sections = [];
      _safeNotifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      // Step 1: Try to load from cache first, but handle type casting errors
      try {
        final cachedSections = CacheService.instance.getCachedSections();
        final filteredCached =
            cachedSections
                .where((s) => subjectIds.contains(s.subjectId))
                .toList();
        if (filteredCached.isNotEmpty) {
          _sections = filteredCached;
          _isLoading = false;
          _safeNotifyListeners();
        }
      } catch (cacheError) {
        print('Cache error, clearing sections cache: $cacheError');
        // Clear the sections cache if there's a type casting issue
        await CacheService.instance.clearSectionsCache();
      }

      // Step 2: Fetch from server in the background
      _sections = await _sectionService.getSectionsForSubjects(subjectIds);
      await CacheService.instance.cacheSections(_sections);
    } catch (e) {
      _error = 'Failed to fetch sections: ${e.toString()}';
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  Future<void> addSection(Section section) async {
    try {
      final newSection = await _sectionService.addSection(section);

      // If we're currently fetching sections for an assistant, refresh the list
      if (_currentAssistantId != null &&
          section.assistantId == _currentAssistantId) {
        await fetchSectionsForAssistant(_currentAssistantId!);
      } else {
        // Otherwise just add to the current list
        _sections.add(newSection);
        _safeNotifyListeners();
      }
    } catch (e) {
      _error = 'Failed to add section: ${e.toString()}';
      _safeNotifyListeners();
    }
  }

  Future<void> updateSection(Section section) async {
    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      await _sectionService.updateSection(section);
      await fetchSectionsForUserSubjects(_currentSubjectIds);
    } catch (e) {
      _error = 'Failed to update section: ${e.toString()}';
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  Future<void> deleteSection(String sectionId) async {
    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      await _sectionService.deleteSection(sectionId);
      await fetchSectionsForUserSubjects(_currentSubjectIds);
    } catch (e) {
      _error = 'Failed to delete section: ${e.toString()}';
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  void resetFilter() {
    _currentAssistantId = null;
    _currentSubjectIds = [];
    _sections = [];
    // Use post-frame callback to avoid build-time notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed) {
        notifyListeners();
      }
    });
  }
}
