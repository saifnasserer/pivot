import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/models/section_model.dart';
import 'package:pivot/services/section_service.dart';
import 'package:pivot/services/cache_service.dart';
import 'package:pivot/services/offline_service.dart';

// Service Provider
final sectionServiceProvider = Provider<SectionService>((ref) {
  return SectionService();
});

// Simplified State class for snapshot-based approach
class SectionsState {
  final List<Section> sections; // Current sections snapshot
  final bool isLoading;
  final String? error;
  final String? currentUserId; // Track which user's sections are loaded

  const SectionsState({
    this.sections = const [],
    this.isLoading = false,
    this.error,
    this.currentUserId,
  });

  SectionsState copyWith({
    List<Section>? sections,
    bool? isLoading,
    String? error,
    String? currentUserId,
  }) {
    return SectionsState(
      sections: sections ?? this.sections,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentUserId: currentUserId ?? this.currentUserId,
    );
  }
}

// Simplified Notifier - Snapshot-based approach
class SectionsNotifier extends StateNotifier<SectionsState> {
  final SectionService _sectionService;

  SectionsNotifier(this._sectionService) : super(const SectionsState());

  /// Load sections for a user (snapshot approach)
  /// 1. Check Hive cache first
  /// 2. If cache exists: use it immediately (zero Firestore reads)
  /// 3. If cache empty: fetch from Firestore and cache
  Future<void> loadSectionsForUser(
    String userId,
    List<String> subjectIds, {
    bool forceRefresh = false,
  }) async {
    print('📊 [SectionsProvider] loadSectionsForUser called');
    print('   User ID: $userId');
    print('   Subject IDs: $subjectIds');
    print('   Force Refresh: $forceRefresh');

    if (subjectIds.isEmpty) {
      print('   ⚠️ No enrolled subjects, clearing sections');
      state = state.copyWith(
        sections: [],
        currentUserId: userId,
        isLoading: false,
      );
      return;
    }

    // Step 1: Try cache first (unless force refresh)
    if (!forceRefresh) {
      final cachedSections = CacheService.instance.getCachedSections();

      if (cachedSections.isNotEmpty) {
        // Filter by enrolled subjects
        final filteredSections =
            cachedSections
                .where((s) => subjectIds.contains(s.subjectId))
                .toList();

        print(
          '   ✅ Using cached sections (${filteredSections.length} sections) - Zero Firestore reads',
        );

        state = state.copyWith(
          sections: filteredSections,
          currentUserId: userId,
          isLoading: false,
        );
        return;
      }
    }

    // Step 2: Check if offline before attempting Firestore fetch
    final offlineService = OfflineService();
    if (offlineService.isOffline) {
      if (kDebugMode) {
        print('   📴 Offline detected - using cache only');
      }

      final cachedSections = CacheService.instance.getCachedSections();
      final filteredSections =
          cachedSections
              .where((s) => subjectIds.contains(s.subjectId))
              .toList();

      if (filteredSections.isEmpty) {
        state = state.copyWith(
          sections: [],
          currentUserId: userId,
          isLoading: false,
          error: 'لا يوجد اتصال بالإنترنت - لا توجد بيانات محفوظة',
        );
      } else {
        state = state.copyWith(
          sections: filteredSections,
          currentUserId: userId,
          isLoading: false,
          error: null,
        );
      }
      return;
    }

    // Step 3: Fetch from Firestore (only when online)
    state = state.copyWith(isLoading: true, error: null, currentUserId: userId);

    try {
      print('   🔄 Online - Fetching sections from Firestore...');
      final sections = await _sectionService.getSectionsForSubjects(subjectIds);

      // Cache the results
      await CacheService.instance.cacheSections(sections);

      print('   ✅ Fetched and cached ${sections.length} sections');

      if (mounted) {
        state = state.copyWith(sections: sections, isLoading: false);
      }
    } catch (e) {
      print('   ❌ Error fetching sections: $e');

      // Fallback to cache if available
      final cachedSections = CacheService.instance.getCachedSections();
      if (cachedSections.isNotEmpty) {
        print('   💡 Using cached sections as fallback');
        final filteredSections =
            cachedSections
                .where((s) => subjectIds.contains(s.subjectId))
                .toList();

        if (mounted) {
          state = state.copyWith(
            sections: filteredSections,
            isLoading: false,
            error: 'Using cached data (offline)',
          );
        }
      } else {
        if (mounted) {
          state = state.copyWith(
            isLoading: false,
            error: 'Failed to load sections: ${e.toString()}',
          );
        }
      }
    }
  }

  /// Force refresh sections from Firestore
  Future<void> refreshSections(String userId, List<String> subjectIds) async {
    print('🔄 [SectionsProvider] Force refresh sections');

    // Check if offline before attempting refresh
    final offlineService = OfflineService();
    if (offlineService.isOffline) {
      print('   📴 Cannot refresh while offline - using cached data');
      await loadSectionsForUser(userId, subjectIds, forceRefresh: false);
      return;
    }

    await loadSectionsForUser(userId, subjectIds, forceRefresh: true);
  }

  /// Clear sections cache
  Future<void> clearSectionsCache() async {
    await CacheService.instance.clearSectionsCache();
    state = state.copyWith(sections: []);
  }

  // ===== ADMIN OPERATIONS (for assistants managing sections) =====

  /// Add section (admin operation)
  Future<void> addSection(Section section, {String? loggedInUserId}) async {
    try {
      print('📝 [SectionsProvider] Adding section...');
      final newSection = await _sectionService.addSection(section);

      if (!mounted) return;

      // Update local state
      final updatedSections = [...state.sections, newSection];
      state = state.copyWith(sections: updatedSections);

      // Update cache
      await CacheService.instance.cacheSections(updatedSections);

      print('   ✅ Section added successfully');
    } catch (e) {
      print('   ❌ Error adding section: $e');
      if (mounted) {
        state = state.copyWith(error: 'Failed to add section: ${e.toString()}');
      }
      rethrow;
    }
  }

  /// Update section (admin operation)
  Future<void> updateSection(Section section) async {
    try {
      print('📝 [SectionsProvider] Updating section...');
      await _sectionService.updateSection(section);

      if (!mounted) return;

      // Update local state
      final updatedSections =
          state.sections.map((s) {
            return s.id == section.id ? section : s;
          }).toList();

      state = state.copyWith(sections: updatedSections);

      // Update cache
      await CacheService.instance.cacheSections(updatedSections);

      print('   ✅ Section updated successfully');
    } catch (e) {
      print('   ❌ Error updating section: $e');
      if (mounted) {
        state = state.copyWith(
          error: 'Failed to update section: ${e.toString()}',
        );
      }
      rethrow;
    }
  }

  /// Delete section (admin operation)
  Future<void> deleteSection(String sectionId) async {
    try {
      print('🗑️ [SectionsProvider] Deleting section...');
      await _sectionService.deleteSection(sectionId);

      if (!mounted) return;

      // Update local state
      final updatedSections =
          state.sections.where((s) => s.id != sectionId).toList();
      state = state.copyWith(sections: updatedSections);

      // Update cache
      await CacheService.instance.cacheSections(updatedSections);

      print('   ✅ Section deleted successfully');
    } catch (e) {
      print('   ❌ Error deleting section: $e');
      if (mounted) {
        state = state.copyWith(
          error: 'Failed to delete section: ${e.toString()}',
        );
      }
      rethrow;
    }
  }

  // ===== ASSISTANT-SPECIFIC OPERATIONS =====

  /// Fetch sections for a specific assistant (temporary view)
  Future<void> loadSectionsForAssistant(String assistantId) async {
    print('👤 [SectionsProvider] Loading sections for assistant: $assistantId');

    if (assistantId.isEmpty) {
      state = state.copyWith(
        sections: [],
        isLoading: false,
        currentUserId: null,
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final sections = await _sectionService.getSectionsForAssistant(
        assistantId,
      );

      if (mounted) {
        // Set currentUserId to the assistant ID to track that these are not the logged-in user's sections
        state = state.copyWith(
          sections: sections,
          isLoading: false,
          currentUserId: assistantId,
        );
      }

      print('   ✅ Loaded ${sections.length} sections for assistant');
    } catch (e) {
      print('   ❌ Error loading assistant sections: $e');
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load sections: ${e.toString()}',
        );
      }
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Reset state
  void reset() {
    state = const SectionsState();
  }
}

// Provider - Simplified snapshot-based provider
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
