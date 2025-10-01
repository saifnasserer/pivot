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

  SectionsNotifier(this._sectionService) : super(const SectionsState());

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
      if (filteredCached.isNotEmpty) {
        state = state.copyWith(sections: filteredCached, isLoading: false);
      }

      // Step 2: Fetch from server in the background
      final sections = await _sectionService.getSectionsForAssistant(
        assistantId,
      );
      await CacheService.instance.cacheSections(sections);

      state = state.copyWith(sections: sections, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to fetch sections: ${e.toString()}',
      );
    }
  }

  // Fetch sections for subjects (for backward compatibility and student views)
  Future<void> fetchSectionsForUserSubjects(List<String> subjectIds) async {
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
      // Step 1: Try to load from cache first, but handle type casting errors
      try {
        final cachedSections = CacheService.instance.getCachedSections();
        final filteredCached =
            cachedSections
                .where((s) => subjectIds.contains(s.subjectId))
                .toList();
        if (filteredCached.isNotEmpty) {
          state = state.copyWith(sections: filteredCached, isLoading: false);
        }
      } catch (cacheError) {
        // Clear the sections cache if there's a type casting issue
        await CacheService.instance.clearSectionsCache();
      }

      // Step 2: Fetch from server in the background
      final sections = await _sectionService.getSectionsForSubjects(subjectIds);
      await CacheService.instance.cacheSections(sections);

      state = state.copyWith(sections: sections, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to fetch sections: ${e.toString()}',
      );
    }
  }

  // Get all sections
  Future<void> getAllSections() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final sections = await _sectionService.getAllSections();
      await CacheService.instance.cacheSections(sections);

      state = state.copyWith(sections: sections, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to fetch sections: ${e.toString()}',
      );
    }
  }

  // Add section
  Future<void> addSection(Section section) async {
    try {
      final newSection = await _sectionService.addSection(section);

      // If we're currently fetching sections for an assistant, refresh the list
      if (state.currentAssistantId != null &&
          section.assistantId == state.currentAssistantId) {
        await fetchSectionsForAssistant(state.currentAssistantId!);
      } else {
        // Otherwise just add to the current list
        final updatedSections = [...state.sections, newSection];
        state = state.copyWith(sections: updatedSections);
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to add section: ${e.toString()}');
    }
  }

  // Update section
  Future<void> updateSection(Section section) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _sectionService.updateSection(section);

      // Refresh based on current filter
      if (state.currentSubjectIds.isNotEmpty) {
        await fetchSectionsForUserSubjects(state.currentSubjectIds);
      } else if (state.currentAssistantId != null) {
        await fetchSectionsForAssistant(state.currentAssistantId!);
      } else {
        await getAllSections();
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update section: ${e.toString()}',
      );
    }
  }

  // Delete section
  Future<void> deleteSection(String sectionId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _sectionService.deleteSection(sectionId);

      // Refresh based on current filter
      if (state.currentSubjectIds.isNotEmpty) {
        await fetchSectionsForUserSubjects(state.currentSubjectIds);
      } else if (state.currentAssistantId != null) {
        await fetchSectionsForAssistant(state.currentAssistantId!);
      } else {
        await getAllSections();
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete section: ${e.toString()}',
      );
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

// Provider
final sectionsProvider =
    StateNotifierProvider.autoDispose<SectionsNotifier, SectionsState>((ref) {
      final service = ref.watch(sectionServiceProvider);
      return SectionsNotifier(service);
    });

// Convenience providers
final sectionsListProvider = Provider.autoDispose<List<Section>>((ref) {
  final state = ref.watch(sectionsProvider);
  return state.sections;
});

final sectionsLoadingProvider = Provider.autoDispose<bool>((ref) {
  final state = ref.watch(sectionsProvider);
  return state.isLoading;
});

final sectionsErrorProvider = Provider.autoDispose<String?>((ref) {
  final state = ref.watch(sectionsProvider);
  return state.error;
});
