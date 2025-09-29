import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/subjects/repositories/subjects_repository.dart';
import 'package:pivot/features/subjects/services/subjects_service.dart';
import 'package:pivot/models/subject_model.dart';

final subjectsServiceProvider = Provider<SubjectsService>(
  (ref) => SubjectsService(),
);

final subjectsRepositoryProvider = Provider<SubjectsRepository>((ref) {
  final service = ref.watch(subjectsServiceProvider);
  return SubjectsRepository(service);
});

class SubjectsState {
  final List<Subject> subjects;
  final List<Subject> filteredSubjects;
  final List<Subject> userSubjects;
  final List<int> availableYears;
  final List<String> availableDepartments;
  final List<String> availableLevels;
  final String searchQuery;
  final int? selectedYear;
  final String? selectedDepartment;
  final String? selectedLevel;
  final bool isLoading;
  final bool isSearching;
  final bool isEnrolling;
  final String? error;
  final int currentPage;
  final bool hasMorePages;
  final bool isPaginating;

  const SubjectsState({
    this.subjects = const [],
    this.filteredSubjects = const [],
    this.userSubjects = const [],
    this.availableYears = const [],
    this.availableDepartments = const [],
    this.availableLevels = const [],
    this.searchQuery = '',
    this.selectedYear,
    this.selectedDepartment,
    this.selectedLevel,
    this.isLoading = false,
    this.isSearching = false,
    this.isEnrolling = false,
    this.error,
    this.currentPage = 1,
    this.hasMorePages = true,
    this.isPaginating = false,
  });

  SubjectsState copyWith({
    List<Subject>? subjects,
    List<Subject>? filteredSubjects,
    List<Subject>? userSubjects,
    List<int>? availableYears,
    List<String>? availableDepartments,
    List<String>? availableLevels,
    String? searchQuery,
    int? selectedYear,
    String? selectedDepartment,
    String? selectedLevel,
    bool? isLoading,
    bool? isSearching,
    bool? isEnrolling,
    String? error,
    int? currentPage,
    bool? hasMorePages,
    bool? isPaginating,
  }) => SubjectsState(
    subjects: subjects ?? this.subjects,
    filteredSubjects: filteredSubjects ?? this.filteredSubjects,
    userSubjects: userSubjects ?? this.userSubjects,
    availableYears: availableYears ?? this.availableYears,
    availableDepartments: availableDepartments ?? this.availableDepartments,
    availableLevels: availableLevels ?? this.availableLevels,
    searchQuery: searchQuery ?? this.searchQuery,
    selectedYear: selectedYear ?? this.selectedYear,
    selectedDepartment: selectedDepartment ?? this.selectedDepartment,
    selectedLevel: selectedLevel ?? this.selectedLevel,
    isLoading: isLoading ?? this.isLoading,
    isSearching: isSearching ?? this.isSearching,
    isEnrolling: isEnrolling ?? this.isEnrolling,
    error: error ?? this.error,
    currentPage: currentPage ?? this.currentPage,
    hasMorePages: hasMorePages ?? this.hasMorePages,
    isPaginating: isPaginating ?? this.isPaginating,
  );
}

final subjectsProvider =
    StateNotifierProvider.autoDispose<SubjectsNotifier, SubjectsState>(
      (ref) => SubjectsNotifier(ref),
    );

class SubjectsNotifier extends StateNotifier<SubjectsState> {
  SubjectsNotifier(this._ref) : super(const SubjectsState());

  final Ref _ref;
  late final SubjectsRepository _repo = _ref.read(subjectsRepositoryProvider);
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _checkDisposed() {
    if (_disposed) {
      throw StateError('SubjectsNotifier has been disposed');
    }
  }

  Future<void> initialize() async {
    _checkDisposed();
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Try to load from cache first
      final cachedSubjects = await _repo.getCachedSubjects();
      if (!_disposed && cachedSubjects.isNotEmpty) {
        state = state.copyWith(
          isLoading: false,
          subjects: cachedSubjects,
          filteredSubjects: cachedSubjects,
        );
      }

      if (_disposed) return;

      // Load fresh data
      final subjects = await _repo.getAllSubjects();
      if (_disposed) return;

      final years = await _repo.getAvailableYears();
      if (_disposed) return;

      final departments = await _repo.getAvailableDepartments();
      if (_disposed) return;

      final levels = await _repo.getAvailableLevels();
      if (_disposed) return;

      // Cache the fresh data
      await _repo.cacheSubjects(subjects);
      if (_disposed) return;

      state = state.copyWith(
        isLoading: false,
        subjects: subjects,
        filteredSubjects: subjects,
        availableYears: years,
        availableDepartments: departments,
        availableLevels: levels,
      );
    } catch (e) {
      if (!_disposed) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  }

  Future<void> loadUserSubjects(String userId) async {
    _checkDisposed();
    state = state.copyWith(isLoading: true, error: null);
    try {
      final userSubjects = await _repo.getSubjectsByUser(userId);
      if (!_disposed) {
        state = state.copyWith(isLoading: false, userSubjects: userSubjects);
      }
    } catch (e) {
      if (!_disposed) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  }

  Future<void> searchSubjects(String query) async {
    _checkDisposed();
    if (query.isEmpty) {
      if (!_disposed) {
        state = state.copyWith(
          searchQuery: '',
          filteredSubjects: state.subjects,
          isSearching: false,
        );
      }
      return;
    }

    if (!_disposed) {
      state = state.copyWith(isSearching: true, searchQuery: query);
    }
    try {
      final results = await _repo.searchSubjects(query);
      if (!_disposed) {
        state = state.copyWith(isSearching: false, filteredSubjects: results);
      }
    } catch (e) {
      if (!_disposed) {
        state = state.copyWith(isSearching: false, error: e.toString());
      }
    }
  }

  Future<void> applyFilters({
    String? searchQuery,
    int? year,
    String? department,
    String? level,
  }) async {
    _checkDisposed();
    state = state.copyWith(isLoading: true, error: null);
    try {
      final filteredSubjects = await _repo.getFilteredSubjects(
        searchQuery: searchQuery,
        year: year,
        department: department,
        level: level,
      );

      if (!_disposed) {
        state = state.copyWith(
          isLoading: false,
          filteredSubjects: filteredSubjects,
          searchQuery: searchQuery ?? '',
          selectedYear: year,
          selectedDepartment: department,
          selectedLevel: level,
        );
      }
    } catch (e) {
      if (!_disposed) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  }

  Future<bool> enrollUserInSubject(String userId, String subjectId) async {
    _checkDisposed();
    state = state.copyWith(isEnrolling: true, error: null);
    try {
      final success = await _repo.enrollUserInSubject(userId, subjectId);
      if (success && !_disposed) {
        // Reload user subjects
        await loadUserSubjects(userId);
      }
      if (!_disposed) {
        state = state.copyWith(isEnrolling: false);
      }
      return success;
    } catch (e) {
      if (!_disposed) {
        state = state.copyWith(isEnrolling: false, error: e.toString());
      }
      return false;
    }
  }

  Future<bool> unenrollUserFromSubject(String userId, String subjectId) async {
    _checkDisposed();
    state = state.copyWith(isEnrolling: true, error: null);
    try {
      final success = await _repo.unenrollUserFromSubject(userId, subjectId);
      if (success && !_disposed) {
        // Reload user subjects
        await loadUserSubjects(userId);
      }
      if (!_disposed) {
        state = state.copyWith(isEnrolling: false);
      }
      return success;
    } catch (e) {
      if (!_disposed) {
        state = state.copyWith(isEnrolling: false, error: e.toString());
      }
      return false;
    }
  }

  Future<bool> updateUserSubjects(
    String userId,
    List<String> subjectIds,
  ) async {
    _checkDisposed();
    state = state.copyWith(isEnrolling: true, error: null);
    try {
      final success = await _repo.updateUserSubjects(userId, subjectIds);
      if (success && !_disposed) {
        // Reload user subjects
        await loadUserSubjects(userId);
      }
      if (!_disposed) {
        state = state.copyWith(isEnrolling: false);
      }
      return success;
    } catch (e) {
      if (!_disposed) {
        state = state.copyWith(isEnrolling: false, error: e.toString());
      }
      return false;
    }
  }

  Future<void> loadMoreSubjects() async {
    _checkDisposed();
    if (!state.hasMorePages || state.isPaginating) return;

    state = state.copyWith(isPaginating: true, error: null);
    try {
      final moreSubjects = await _repo.getPaginatedSubjects(
        page: state.currentPage + 1,
        searchQuery: state.searchQuery.isNotEmpty ? state.searchQuery : null,
        year: state.selectedYear,
        department: state.selectedDepartment,
        level: state.selectedLevel,
      );

      if (!_disposed) {
        state = state.copyWith(
          isPaginating: false,
          currentPage: state.currentPage + 1,
          hasMorePages:
              moreSubjects.length >= 20, // Assuming 20 is the page size
          filteredSubjects: [...state.filteredSubjects, ...moreSubjects],
        );
      }
    } catch (e) {
      if (!_disposed) {
        state = state.copyWith(isPaginating: false, error: e.toString());
      }
    }
  }

  void clearFilters() {
    _checkDisposed();
    if (!_disposed) {
      state = state.copyWith(
        searchQuery: '',
        selectedYear: null,
        selectedDepartment: null,
        selectedLevel: null,
        filteredSubjects: state.subjects,
      );
    }
  }

  void clearError() {
    _checkDisposed();
    if (!_disposed) {
      state = state.copyWith(error: null);
    }
  }
}
