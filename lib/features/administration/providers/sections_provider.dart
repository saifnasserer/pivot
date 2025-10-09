import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/models/section_model.dart';
import 'package:pivot/services/section_service.dart';
import 'package:pivot/services/cache_service.dart';

// Service Provider
final sectionServiceProvider = Provider<SectionService>((ref) {
  return SectionService();
});

// State class
class SectionsState {
  final List<Section> sections;
  final bool isLoading;
  final String? error;
  final String? currentAssistantId;
  final List<String> currentSubjectIds;

  const SectionsState({
    this.sections = const [],
    this.isLoading = false,
    this.error,
    this.currentAssistantId,
    this.currentSubjectIds = const [],
  });

  SectionsState copyWith({
    List<Section>? sections,
    bool? isLoading,
    String? error,
    String? currentAssistantId,
    List<String>? currentSubjectIds,
  }) {
    return SectionsState(
      sections: sections ?? this.sections,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentAssistantId: currentAssistantId ?? this.currentAssistantId,
      currentSubjectIds: currentSubjectIds ?? this.currentSubjectIds,
    );
  }
}

// Notifier
class SectionsNotifier extends StateNotifier<SectionsState> {
  final SectionService _sectionService;

  SectionsNotifier(this._sectionService) : super(const SectionsState()) {
    // Load from cache on startup (local-first approach)
    _loadFromCacheOnly();
  }

  // Load ONLY from cache (no server fetch) - private method for initialization
  void _loadFromCacheOnly() {
    try {
      final cachedSections = CacheService.instance.getCachedSections();
      if (cachedSections.isEmpty) {
        print('📦 SectionsProvider: No cached sections found');
        return;
      }

      print(
        '✅ SectionsProvider: Loaded ${cachedSections.length} sections from cache - Zero server reads',
      );
      state = state.copyWith(sections: cachedSections, isLoading: false);
    } catch (e) {
      print('❌ SectionsProvider: Error loading from cache - $e');
    }
  }

  // Reload from cache (useful when app resumes)
  void reloadFromCache() {
    _loadFromCacheOnly();
  }

  // Fetch sections for a specific assistant
  Future<void> fetchSectionsForAssistant(String assistantId) async {
    if (assistantId.isEmpty) {
      state = state.copyWith(sections: [], currentAssistantId: assistantId);
      return;
    }

    state = state.copyWith(
      isLoading: true,
      error: null,
      currentAssistantId: assistantId,
    );

    try {
      // Step 1: Load from cache first
      final cachedSections = CacheService.instance.getCachedSections();
      final filteredCached =
          cachedSections.where((s) => s.assistantId == assistantId).toList();
      if (filteredCached.isNotEmpty && mounted) {
        state = state.copyWith(sections: filteredCached, isLoading: false);
      }

      // Step 2: Fetch from server in the background
      final sections = await _sectionService.getSectionsForAssistant(
        assistantId,
      );
      await CacheService.instance.cacheSections(sections);

      if (mounted) {
        state = state.copyWith(sections: sections, isLoading: false);
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to fetch sections: ${e.toString()}',
        );
      }
    }
  }

  // Fetch sections for subjects (for backward compatibility and student views)
  Future<void> fetchSectionsForUserSubjects(List<String> subjectIds) async {
    if (subjectIds.isEmpty) {
      state = state.copyWith(sections: [], currentSubjectIds: subjectIds);
      return;
    }

    // Store the current subject IDs
    state = state.copyWith(currentSubjectIds: subjectIds);

    try {
      // Step 1: Load from cache first (local-first approach)
      final cachedSections = CacheService.instance.getCachedSections();
      final filteredCached =
          cachedSections
              .where((s) => subjectIds.contains(s.subjectId))
              .toList();

      if (filteredCached.isNotEmpty) {
        // Use cached data immediately
        print(
          '✅ SectionsProvider: Using cached sections for subjects (${filteredCached.length} sections) - Zero server reads',
        );
        if (mounted) {
          state = state.copyWith(sections: filteredCached, isLoading: false);
        }
        return; // Return early with cached data
      }

      // Step 2: Only fetch from server if cache is empty
      print('🔄 SectionsProvider: Fetching sections from server...');
      state = state.copyWith(isLoading: true, error: null);

      final sections = await _sectionService.getSectionsForSubjects(subjectIds);
      await CacheService.instance.cacheSections(sections);

      print('💾 SectionsProvider: Cached ${sections.length} sections');

      if (mounted) {
        state = state.copyWith(sections: sections, isLoading: false);
      }
    } catch (e) {
      print('❌ SectionsProvider: Error fetching sections - $e');
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to fetch sections: ${e.toString()}',
        );
      }
    }
  }

  // Force refresh from server (bypasses cache)
  Future<void> forceRefreshForSubjects(List<String> subjectIds) async {
    if (subjectIds.isEmpty) {
      state = state.copyWith(sections: [], currentSubjectIds: subjectIds);
      return;
    }

    state = state.copyWith(
      isLoading: true,
      error: null,
      currentSubjectIds: subjectIds,
    );

    try {
      print('🔄 SectionsProvider: Force refreshing from server...');
      final sections = await _sectionService.getSectionsForSubjects(subjectIds);
      await CacheService.instance.cacheSections(sections);

      print(
        '💾 SectionsProvider: Updated cache with ${sections.length} sections',
      );

      if (mounted) {
        state = state.copyWith(sections: sections, isLoading: false);
      }
    } catch (e) {
      print('❌ SectionsProvider: Error force refreshing - $e');
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to fetch sections: ${e.toString()}',
        );
      }
    }
  }

  // Get all sections
  Future<void> getAllSections() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final sections = await _sectionService.getAllSections();
      await CacheService.instance.cacheSections(sections);

      if (mounted) {
        state = state.copyWith(sections: sections, isLoading: false);
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to fetch sections: ${e.toString()}',
        );
      }
    }
  }

  // Add section
  Future<void> addSection(Section section) async {
    try {
      print('SectionsProvider: Adding section...');
      print('Current assistant ID: ${state.currentAssistantId}');
      print('Current subject IDs: ${state.currentSubjectIds}');

      final newSection = await _sectionService.addSection(section);

      if (!mounted) {
        print('SectionsProvider: Not mounted, returning early');
        return;
      }

      // Always refresh the list and update cache after adding a section
      if (state.currentAssistantId != null) {
        // If we're viewing an assistant's sections, refresh that assistant's sections
        print(
          'SectionsProvider: Refreshing sections for assistant ${state.currentAssistantId}',
        );
        await fetchSectionsForAssistant(state.currentAssistantId!);
      } else if (state.currentSubjectIds.isNotEmpty) {
        // If we're viewing sections by subject, refresh those
        print(
          'SectionsProvider: Refreshing sections for subjects ${state.currentSubjectIds}',
        );
        await fetchSectionsForUserSubjects(state.currentSubjectIds);
      } else {
        // Otherwise, just add the new section to the current list and update cache
        print('SectionsProvider: Adding section to current list');
        final updatedSections = [...state.sections, newSection];
        await CacheService.instance.cacheSections(updatedSections);
        if (mounted) {
          state = state.copyWith(sections: updatedSections);
        }
      }

      print('SectionsProvider: Section added successfully!');
    } catch (e) {
      print('SectionsProvider: Error adding section: $e');
      if (mounted) {
        state = state.copyWith(error: 'Failed to add section: ${e.toString()}');
      }
      rethrow;
    }
  }

  // Update section
  Future<void> updateSection(Section section) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _sectionService.updateSection(section);

      if (!mounted) return;

      // Refresh based on current filter
      if (state.currentSubjectIds.isNotEmpty) {
        await fetchSectionsForUserSubjects(state.currentSubjectIds);
      } else if (state.currentAssistantId != null) {
        await fetchSectionsForAssistant(state.currentAssistantId!);
      } else {
        await getAllSections();
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to update section: ${e.toString()}',
        );
      }
    }
  }

  // Delete section
  Future<void> deleteSection(String sectionId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _sectionService.deleteSection(sectionId);

      if (!mounted) return;

      // Refresh based on current filter
      if (state.currentSubjectIds.isNotEmpty) {
        await fetchSectionsForUserSubjects(state.currentSubjectIds);
      } else if (state.currentAssistantId != null) {
        await fetchSectionsForAssistant(state.currentAssistantId!);
      } else {
        await getAllSections();
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to delete section: ${e.toString()}',
        );
      }
    }
  }

  // Reset filter
  void resetFilter() {
    state = const SectionsState();
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider - Using persistent provider for better caching
final sectionsProvider = StateNotifierProvider<SectionsNotifier, SectionsState>(
  (ref) {
    final service = ref.watch(sectionServiceProvider);
    return SectionsNotifier(service);
  },
);

// Convenience providers
final sectionsListProvider = Provider<List<Section>>((ref) {
  final state = ref.watch(sectionsProvider);
  return state.sections;
});

final sectionsLoadingProvider = Provider<bool>((ref) {
  final state = ref.watch(sectionsProvider);
  return state.isLoading;
});

final sectionsErrorProvider = Provider<String?>((ref) {
  final state = ref.watch(sectionsProvider);
  return state.error;
});
