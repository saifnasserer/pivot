import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/media/services/materials_service.dart';
import 'package:pivot/features/media/repositories/materials_repository.dart';
import 'package:pivot/models/material_link.dart';
import 'package:pivot/services/offline_service.dart';
import 'package:pivot/services/cache_service.dart';

// Services
final materialsServiceProvider = Provider<MaterialsService>((ref) {
  return MaterialsService();
});

// Repositories
final materialsRepositoryProvider = Provider<MaterialsRepository>((ref) {
  final service = ref.watch(materialsServiceProvider);
  return MaterialsRepository(service);
});

// State classes
class MaterialsState {
  final bool isLoading;
  final String? error;
  final List<MaterialLink> materials;
  final List<MaterialLink> filteredMaterials;
  final Map<String, dynamic>? statistics;
  final String searchQuery;
  final MaterialType? selectedType;
  final String? selectedLectureId;
  final String? selectedSubjectId;
  final String? selectedDoctorId;

  // Pagination fields
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final int pageSize;

  const MaterialsState({
    this.isLoading = false,
    this.error,
    this.materials = const [],
    this.filteredMaterials = const [],
    this.statistics,
    this.searchQuery = '',
    this.selectedType,
    this.selectedLectureId,
    this.selectedSubjectId,
    this.selectedDoctorId,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.pageSize = 20,
  });

  MaterialsState copyWith({
    bool? isLoading,
    String? error,
    List<MaterialLink>? materials,
    List<MaterialLink>? filteredMaterials,
    Map<String, dynamic>? statistics,
    String? searchQuery,
    MaterialType? selectedType,
    String? selectedLectureId,
    String? selectedSubjectId,
    String? selectedDoctorId,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    int? pageSize,
  }) {
    return MaterialsState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      materials: materials ?? this.materials,
      filteredMaterials: filteredMaterials ?? this.filteredMaterials,
      statistics: statistics ?? this.statistics,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedType: selectedType ?? this.selectedType,
      selectedLectureId: selectedLectureId ?? this.selectedLectureId,
      selectedSubjectId: selectedSubjectId ?? this.selectedSubjectId,
      selectedDoctorId: selectedDoctorId ?? this.selectedDoctorId,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}

// Notifier
class MaterialsNotifier extends StateNotifier<MaterialsState> {
  final MaterialsRepository _repository;

  MaterialsNotifier(this._repository) : super(const MaterialsState());

  // Get all materials
  Future<void> getAllMaterials() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final materials = await _repository.getAllMaterials();
      state = state.copyWith(
        isLoading: false,
        materials: materials,
        filteredMaterials: materials,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Get materials by type
  Future<void> getMaterialsByType(MaterialType type) async {
    state = state.copyWith(isLoading: true, error: null, selectedType: type);
    try {
      final materials = await _repository.getMaterialsByType(type);
      state = state.copyWith(
        isLoading: false,
        materials: materials,
        filteredMaterials: materials,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Get materials by lecture ID
  Future<void> getMaterialsByLectureId(String lectureId) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      selectedLectureId: lectureId,
      currentPage: 0,
      hasMore: true,
    );

    final cacheKey = 'lecture_$lectureId';

    // Check if offline before attempting fetch
    final offlineService = OfflineService();
    if (offlineService.isOffline) {
      print('📴 [MaterialsProvider] Offline - checking cache for materials');

      // Try to load from cache
      final cachedMaterialsJson = CacheService.instance.getCachedMaterials(
        cacheKey,
      );

      if (cachedMaterialsJson.isEmpty) {
        print('   ⚠️ No cached materials found');
        state = state.copyWith(
          isLoading: false,
          materials: [],
          filteredMaterials: [],
          error: null, // Don't show error, just empty list with offline banner
        );
      } else {
        print('   ✅ Found ${cachedMaterialsJson.length} cached materials');
        final materials =
            cachedMaterialsJson
                .map((json) => MaterialLink.fromMap(json))
                .toList();

        state = state.copyWith(
          isLoading: false,
          materials: materials,
          filteredMaterials: materials,
          hasMore: false,
          currentPage: 1,
        );
      }
      return;
    }

    try {
      print(
        '🌐 [MaterialsProvider] Online - Fetching materials from Firestore...',
      );
      final materials = await _repository.getMaterialsByLectureId(lectureId);

      // Cache the materials
      final materialsJson = materials.map((m) => m.toLegacyMap()).toList();
      await CacheService.instance.cacheMaterials(cacheKey, materialsJson);

      state = state.copyWith(
        isLoading: false,
        materials: materials,
        filteredMaterials: materials,
        hasMore: materials.length >= state.pageSize,
        currentPage: 1,
      );
    } catch (e) {
      print('❌ [MaterialsProvider] Error fetching materials: $e');

      // Try cache as fallback
      final cachedMaterialsJson = CacheService.instance.getCachedMaterials(
        cacheKey,
      );
      if (cachedMaterialsJson.isNotEmpty) {
        print('   💡 Using cached materials as fallback');
        final materials =
            cachedMaterialsJson
                .map((json) => MaterialLink.fromMap(json))
                .toList();

        state = state.copyWith(
          isLoading: false,
          materials: materials,
          filteredMaterials: materials,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          materials: [],
          filteredMaterials: [],
          error: e.toString(),
        );
      }
    }
  }

  // Load more materials by lecture ID (pagination)
  Future<void> loadMoreMaterialsByLectureId() async {
    if (state.isLoadingMore ||
        !state.hasMore ||
        state.selectedLectureId == null) {
      return;
    }

    state = state.copyWith(isLoadingMore: true, error: null);
    try {
      // Since the repository doesn't support pagination yet, we'll simulate it
      // by slicing the existing materials list
      final allMaterials = await _repository.getMaterialsByLectureId(
        state.selectedLectureId!,
      );

      // Calculate what materials to show
      final startIndex = state.currentPage * state.pageSize;
      final endIndex = (state.currentPage + 1) * state.pageSize;

      if (startIndex >= allMaterials.length) {
        state = state.copyWith(isLoadingMore: false, hasMore: false);
        return;
      }

      final newMaterials = allMaterials.sublist(
        startIndex,
        endIndex > allMaterials.length ? allMaterials.length : endIndex,
      );

      final updatedMaterials = [...state.materials, ...newMaterials];

      state = state.copyWith(
        isLoadingMore: false,
        materials: updatedMaterials,
        filteredMaterials: _applyFiltersToList(updatedMaterials),
        currentPage: state.currentPage + 1,
        hasMore: endIndex < allMaterials.length,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  // Search materials
  Future<void> searchMaterials(String query) async {
    state = state.copyWith(isLoading: true, error: null, searchQuery: query);
    try {
      final materials = await _repository.searchMaterials(query);
      state = state.copyWith(
        isLoading: false,
        materials: materials,
        filteredMaterials: materials,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Get materials statistics
  Future<void> getMaterialsStatistics() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final statistics = await _repository.getMaterialsStatistics();
      state = state.copyWith(isLoading: false, statistics: statistics);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Get recent materials
  Future<void> getRecentMaterials({int limit = 10}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final materials = await _repository.getRecentMaterials(limit: limit);
      state = state.copyWith(
        isLoading: false,
        materials: materials,
        filteredMaterials: materials,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Get popular materials
  Future<void> getPopularMaterials({int limit = 10}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final materials = await _repository.getPopularMaterials(limit: limit);
      state = state.copyWith(
        isLoading: false,
        materials: materials,
        filteredMaterials: materials,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Add material to lecture
  Future<bool> addMaterialToLecture(
    String lectureId,
    MaterialLink materialLink,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _repository.addMaterialToLecture(
        lectureId,
        materialLink,
      );
      if (success) {
        // Refresh materials if this is the current lecture
        if (lectureId == state.selectedLectureId) {
          await getMaterialsByLectureId(lectureId);
        }
      }
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Remove material from lecture
  Future<bool> removeMaterialFromLecture(
    String lectureId,
    MaterialLink materialLink,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _repository.removeMaterialFromLecture(
        lectureId,
        materialLink,
      );
      if (success) {
        // Refresh materials if this is the current lecture
        if (lectureId == state.selectedLectureId) {
          await getMaterialsByLectureId(lectureId);
        }
      }
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Update material in lecture
  Future<bool> updateMaterialInLecture(
    String lectureId,
    MaterialLink oldMaterial,
    MaterialLink newMaterial,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _repository.updateMaterialInLecture(
        lectureId,
        oldMaterial,
        newMaterial,
      );
      if (success) {
        // Refresh materials if this is the current lecture
        if (lectureId == state.selectedLectureId) {
          await getMaterialsByLectureId(lectureId);
        }
      }
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Get materials by subject
  Future<void> getMaterialsBySubject(String subjectId) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      selectedSubjectId: subjectId,
    );
    try {
      final materials = await _repository.getMaterialsBySubject(subjectId);
      state = state.copyWith(
        isLoading: false,
        materials: materials,
        filteredMaterials: materials,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Get materials by doctor
  Future<void> getMaterialsByDoctor(String doctorId) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      selectedDoctorId: doctorId,
    );
    try {
      final materials = await _repository.getMaterialsByDoctor(doctorId);
      state = state.copyWith(
        isLoading: false,
        materials: materials,
        filteredMaterials: materials,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Filter materials locally
  void filterMaterials({String? query, MaterialType? type}) {
    List<MaterialLink> filtered = state.materials;

    // Filter by search query
    if (query != null && query.isNotEmpty) {
      final lowercaseQuery = query.toLowerCase();
      filtered =
          filtered.where((material) {
            return material.displayTitle.toLowerCase().contains(
                  lowercaseQuery,
                ) ||
                material.url.toLowerCase().contains(lowercaseQuery) ||
                (material.description?.toLowerCase().contains(lowercaseQuery) ??
                    false);
          }).toList();
    }

    // Filter by type
    if (type != null) {
      filtered = filtered.where((material) => material.type == type).toList();
    }

    state = state.copyWith(
      filteredMaterials: filtered,
      searchQuery: query ?? state.searchQuery,
      selectedType: type ?? state.selectedType,
    );
  }

  // Clear filters
  void clearFilters() {
    state = state.copyWith(
      filteredMaterials: state.materials,
      searchQuery: '',
      selectedType: null,
    );
  }

  // Rate a material
  Future<void> rateMaterial(
    String lectureId,
    MaterialLink material,
    String userId,
    double rating,
  ) async {
    try {
      await _repository.rateMaterial(lectureId, material, userId, rating);

      // Refresh materials if this is the current lecture
      if (lectureId == state.selectedLectureId && mounted) {
        await getMaterialsByLectureId(lectureId);
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(error: e.toString());
      }
      rethrow;
    }
  }

  // ============ ASSISTANT MATERIALS METHODS ============

  // Get materials by subject and assistant
  Future<void> getMaterialsBySubjectAndAssistant(
    String subjectId,
    String assistantId,
  ) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      selectedSubjectId: subjectId,
      selectedDoctorId: assistantId, // Reusing this field for assistantId
      currentPage: 0,
      hasMore: true,
    );

    final cacheKey = 'assistant_${subjectId}_$assistantId';

    // Check if offline before attempting fetch
    final offlineService = OfflineService();
    if (offlineService.isOffline) {
      print('📴 [MaterialsProvider] Offline - checking cache for materials');

      // Try to load from cache
      final cachedMaterialsJson = CacheService.instance.getCachedMaterials(
        cacheKey,
      );

      if (cachedMaterialsJson.isEmpty) {
        print('   ⚠️ No cached materials found');
        state = state.copyWith(
          isLoading: false,
          materials: [],
          filteredMaterials: [],
          error: null, // Don't show error, just empty list with offline banner
        );
      } else {
        print('   ✅ Found ${cachedMaterialsJson.length} cached materials');
        final materials =
            cachedMaterialsJson
                .map((json) => MaterialLink.fromMap(json))
                .toList();

        state = state.copyWith(
          isLoading: false,
          materials: materials,
          filteredMaterials: materials,
          hasMore: false,
          currentPage: 1,
        );
      }
      return;
    }

    try {
      print(
        '🌐 [MaterialsProvider] Online - Fetching assistant materials from Firestore...',
      );
      final materials = await _repository.getMaterialsBySubjectAndAssistant(
        subjectId,
        assistantId,
      );

      // Cache the materials
      final materialsJson = materials.map((m) => m.toLegacyMap()).toList();
      await CacheService.instance.cacheMaterials(cacheKey, materialsJson);

      state = state.copyWith(
        isLoading: false,
        materials: materials,
        filteredMaterials: materials,
        hasMore: materials.length >= state.pageSize,
        currentPage: 1,
      );
    } catch (e) {
      print('❌ [MaterialsProvider] Error fetching materials: $e');

      // Try cache as fallback
      final cachedMaterialsJson = CacheService.instance.getCachedMaterials(
        cacheKey,
      );
      if (cachedMaterialsJson.isNotEmpty) {
        print('   💡 Using cached materials as fallback');
        final materials =
            cachedMaterialsJson
                .map((json) => MaterialLink.fromMap(json))
                .toList();

        state = state.copyWith(
          isLoading: false,
          materials: materials,
          filteredMaterials: materials,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          materials: [],
          filteredMaterials: [],
          error: e.toString(),
        );
      }
    }
  }

  // Load more materials by subject and assistant (pagination)
  Future<void> loadMoreMaterialsBySubjectAndAssistant() async {
    if (state.isLoadingMore ||
        !state.hasMore ||
        state.selectedSubjectId == null ||
        state.selectedDoctorId == null) {
      return;
    }

    state = state.copyWith(isLoadingMore: true, error: null);
    try {
      final allMaterials = await _repository.getMaterialsBySubjectAndAssistant(
        state.selectedSubjectId!,
        state.selectedDoctorId!,
      );

      final startIndex = state.currentPage * state.pageSize;
      final endIndex = (state.currentPage + 1) * state.pageSize;

      if (startIndex >= allMaterials.length) {
        state = state.copyWith(isLoadingMore: false, hasMore: false);
        return;
      }

      final newMaterials = allMaterials.sublist(
        startIndex,
        endIndex > allMaterials.length ? allMaterials.length : endIndex,
      );

      final updatedMaterials = [...state.materials, ...newMaterials];

      state = state.copyWith(
        isLoadingMore: false,
        materials: updatedMaterials,
        filteredMaterials: _applyFiltersToList(updatedMaterials),
        currentPage: state.currentPage + 1,
        hasMore: endIndex < allMaterials.length,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  // Helper method to apply current filters to a list
  List<MaterialLink> _applyFiltersToList(List<MaterialLink> materials) {
    List<MaterialLink> filtered = materials;

    // Filter by search query
    if (state.searchQuery.isNotEmpty) {
      final lowercaseQuery = state.searchQuery.toLowerCase();
      filtered =
          filtered.where((material) {
            return material.displayTitle.toLowerCase().contains(
                  lowercaseQuery,
                ) ||
                material.url.toLowerCase().contains(lowercaseQuery) ||
                (material.description?.toLowerCase().contains(lowercaseQuery) ??
                    false);
          }).toList();
    }

    // Filter by type
    if (state.selectedType != null) {
      filtered =
          filtered
              .where((material) => material.type == state.selectedType)
              .toList();
    }

    return filtered;
  }

  // Add material to subject-assistant
  Future<bool> addMaterialToSubjectAssistant(
    String subjectId,
    String assistantId,
    MaterialLink materialLink,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _repository.addMaterialToSubjectAssistant(
        subjectId,
        assistantId,
        materialLink,
      );
      if (success) {
        // Refresh materials
        await getMaterialsBySubjectAndAssistant(subjectId, assistantId);
      }
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Remove material from subject-assistant
  Future<bool> removeMaterialFromSubjectAssistant(
    String subjectId,
    String assistantId,
    MaterialLink materialLink,
  ) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _repository.removeMaterialFromSubjectAssistant(
        subjectId,
        assistantId,
        materialLink,
      );
      if (success) {
        // Refresh materials
        await getMaterialsBySubjectAndAssistant(subjectId, assistantId);
      }
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Rate material in subject-assistant context
  Future<void> rateMaterialInSubjectAssistant(
    String subjectId,
    String assistantId,
    MaterialLink material,
    String userId,
    double rating,
  ) async {
    try {
      await _repository.rateMaterialInSubjectAssistant(
        subjectId,
        assistantId,
        material,
        userId,
        rating,
      );

      // Refresh materials
      if (mounted) {
        await getMaterialsBySubjectAndAssistant(subjectId, assistantId);
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(error: e.toString());
      }
      rethrow;
    }
  }
}

// Providers
final materialsProvider =
    AutoDisposeStateNotifierProvider<MaterialsNotifier, MaterialsState>((ref) {
      final repository = ref.watch(materialsRepositoryProvider);
      return MaterialsNotifier(repository);
    });

// Convenience providers for specific data
final materialsListProvider = AutoDisposeProvider<List<MaterialLink>>((ref) {
  final state = ref.watch(materialsProvider);
  return state.materials;
});

final filteredMaterialsProvider = AutoDisposeProvider<List<MaterialLink>>((
  ref,
) {
  final state = ref.watch(materialsProvider);
  return state.filteredMaterials;
});

final materialsStatisticsProvider = AutoDisposeProvider<Map<String, dynamic>?>((
  ref,
) {
  final state = ref.watch(materialsProvider);
  return state.statistics;
});

final materialsSearchQueryProvider = AutoDisposeProvider<String>((ref) {
  final state = ref.watch(materialsProvider);
  return state.searchQuery;
});

final materialsSelectedTypeProvider = AutoDisposeProvider<MaterialType?>((ref) {
  final state = ref.watch(materialsProvider);
  return state.selectedType;
});
