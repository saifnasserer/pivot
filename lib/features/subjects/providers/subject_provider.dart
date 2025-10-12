import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/models/subject_model.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/services/subject_service.dart';
import 'package:pivot/services/cache_service.dart';
import 'package:pivot/services/offline_service.dart';

// State class for subjects
class SubjectState {
  final List<Subject> allSubjects;
  final List<Subject> filteredSubjects;
  final bool isLoading;
  final String? error;
  final Map<String, List<UserProfile>> instructorsBySubject;

  SubjectState({
    this.allSubjects = const [],
    this.filteredSubjects = const [],
    this.isLoading = false,
    this.error,
    this.instructorsBySubject = const {},
  });

  SubjectState copyWith({
    List<Subject>? allSubjects,
    List<Subject>? filteredSubjects,
    bool? isLoading,
    String? error,
    Map<String, List<UserProfile>>? instructorsBySubject,
  }) {
    return SubjectState(
      allSubjects: allSubjects ?? this.allSubjects,
      filteredSubjects: filteredSubjects ?? this.filteredSubjects,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      instructorsBySubject: instructorsBySubject ?? this.instructorsBySubject,
    );
  }
}

// StateNotifier
class SubjectNotifier extends StateNotifier<SubjectState> {
  final SubjectService _subjectService = SubjectService();

  SubjectNotifier() : super(SubjectState()) {
    // Load from cache on startup (local-first)
    _loadFromCacheOnly();
  }

  // Load ONLY from cache (no server fetch) - private method for initialization
  void _loadFromCacheOnly() {
    try {
      final cachedSubjects = CacheService.instance.getCachedSubjects();
      if (cachedSubjects.isEmpty) {
        if (kDebugMode) {
          print('📦 SubjectProvider: No cached subjects found');
        }
        return;
      }

      if (kDebugMode) {
        print(
          '✅ SubjectProvider: Loaded ${cachedSubjects.length} subjects from cache - Zero server reads',
        );
      }
      state = SubjectState(
        allSubjects: cachedSubjects,
        filteredSubjects: cachedSubjects,
        isLoading: false,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ SubjectProvider: Error loading from cache - $e');
      }
    }
  }

  // Reload from cache (useful when app resumes)
  void reloadFromCache() {
    _loadFromCacheOnly();
  }

  /// Helper method to check if a user is an instructor
  bool _isInstructor(String role) {
    final lowerRole = role.toLowerCase();
    return lowerRole == 'professor' ||
        lowerRole == 'miniprofessor' ||
        role == 'miniProfessor' ||
        lowerRole == 'doctor';
  }

  /// Helper method to check if a user is a student
  bool _isStudent(String role) {
    return role == 'Student' || role == 'Admin' || role == 'Super Admin';
  }

  void buildInstructorsMap(List<UserProfile> allUsers) {
    final Map<String, List<UserProfile>> instructorsBySubject = {};
    final instructors =
        allUsers.where((user) => _isInstructor(user.role)).toList();

    for (final instructor in instructors) {
      for (final subjectId in instructor.teachingSubjects) {
        if (instructorsBySubject.containsKey(subjectId)) {
          if (!instructorsBySubject[subjectId]!.any(
            (u) => u.id == instructor.id,
          )) {
            instructorsBySubject[subjectId]!.add(instructor);
          }
        } else {
          instructorsBySubject[subjectId] = [instructor];
        }
      }
    }

    state = state.copyWith(instructorsBySubject: instructorsBySubject);
  }

  Future<void> fetchAllSubjects({
    bool forceRefresh = false,
    String? userRole,
    bool forceAllSubjects = false, // For Super Admin operations
  }) async {
    // Prevent multiple simultaneous calls
    if (state.isLoading) {
      if (kDebugMode) {
        print('⏳ SubjectProvider: Already loading, skipping...');
      }
      return;
    }

    // If not forcing refresh and we already have ALL subjects cached, use them
    if (!forceRefresh) {
      final cachedSubjects = CacheService.instance.getCachedSubjects();
      if (cachedSubjects.isNotEmpty) {
        // Check if state already has these subjects (avoid redundant updates)
        if (state.allSubjects.length == cachedSubjects.length) {
          if (kDebugMode) {
            print(
              '✅ SubjectProvider: Using cached subjects (${cachedSubjects.length}) - Zero server reads',
            );
          }
          // Make sure both allSubjects and filteredSubjects contain all subjects
          if (state.filteredSubjects.length != cachedSubjects.length) {
            state = state.copyWith(filteredSubjects: cachedSubjects);
          }
          return;
        }

        // Update state with cached subjects
        if (kDebugMode) {
          print(
            '📦 SubjectProvider: Loading ${cachedSubjects.length} subjects from cache - Zero server reads',
          );
        }
        state = SubjectState(
          allSubjects: cachedSubjects,
          filteredSubjects: cachedSubjects,
          isLoading: false,
        );
        return;
      }
    }

    // Check if offline before server fetch
    final offlineService = OfflineService();
    if (offlineService.isOffline) {
      if (kDebugMode) {
        print('📴 SubjectProvider: Offline - cannot fetch, using empty state');
      }
      state = state.copyWith(
        isLoading: false,
        error: null, // Don't show error, offline banner will show
      );
      return;
    }

    // Fetch from server (first time or force refresh)
    if (kDebugMode) {
      print(
        '🔄 SubjectProvider: ${forceRefresh ? "Force refreshing" : "Fetching"} subjects from server...',
      );
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Fetch ALL subjects from Firestore
      final subjects = await _subjectService.getSubjects();

      if (kDebugMode) {
        print(
          '📚 SubjectProvider: Fetched ${subjects.length} subjects from server',
        );
      }

      // Cache the subjects for future instant access
      if (subjects.isNotEmpty) {
        await CacheService.instance.cacheSubjects(subjects);
        if (kDebugMode) {
          print('💾 SubjectProvider: Cached ${subjects.length} subjects');
        }
      }

      // Update state with ALL subjects
      state = SubjectState(
        allSubjects: subjects,
        filteredSubjects: subjects,
        isLoading: false,
      );
    } catch (e) {
      // Error - try to use stale cache as fallback
      if (kDebugMode) {
        print('❌ SubjectProvider: Server error - $e');
      }

      try {
        final cachedSubjects = CacheService.instance.getCachedSubjects();
        if (cachedSubjects.isNotEmpty) {
          if (kDebugMode) {
            print(
              '⚠️ SubjectProvider: Using stale cache (${cachedSubjects.length} subjects)',
            );
          }
          state = SubjectState(
            allSubjects: cachedSubjects,
            filteredSubjects: cachedSubjects,
            isLoading: false,
          );
        } else {
          state = state.copyWith(
            isLoading: false,
            error: 'Failed to fetch subjects: ${e.toString()}',
          );
        }
      } catch (cacheError) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to fetch subjects: ${e.toString()}',
        );
        if (kDebugMode) {
          print('❌ SubjectProvider: Cache fallback failed - $cacheError');
        }
      }
    }
  }

  Future<void> addSubject(Subject subject) async {
    try {
      final newSubject = await _subjectService.addSubject(subject);
      final updatedSubjects = [...state.allSubjects, newSubject];

      // Update cache
      await CacheService.instance.cacheSubjects(updatedSubjects);

      state = state.copyWith(allSubjects: updatedSubjects);
    } catch (e) {
      state = state.copyWith(error: 'Failed to add subject: ${e.toString()}');
      rethrow;
    }
  }

  Future<void> updateSubject(Subject subject) async {
    try {
      await _subjectService.updateSubject(subject);
      final updatedSubjects =
          state.allSubjects.map((s) {
            return s.id == subject.id ? subject : s;
          }).toList();

      // Update cache
      await CacheService.instance.cacheSubjects(updatedSubjects);

      state = state.copyWith(allSubjects: updatedSubjects);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to update subject: ${e.toString()}',
      );
      rethrow;
    }
  }

  Future<void> deleteSubject(String subjectId) async {
    try {
      await _subjectService.deleteSubject(subjectId);
      final updatedSubjects =
          state.allSubjects.where((s) => s.id != subjectId).toList();

      // Update cache
      await CacheService.instance.cacheSubjects(updatedSubjects);

      state = state.copyWith(allSubjects: updatedSubjects);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to delete subject: ${e.toString()}',
      );
      rethrow;
    }
  }

  Future<void> fetchAndFilterSubjects(UserProfile? userProfile) async {
    if (userProfile == null) return;

    // For admin users, just fetch all subjects (they use the same method)
    if (userProfile.role == 'Admin' || userProfile.role == 'Super Admin') {
      await fetchAllSubjects();
      return;
    }

    // For students and instructors, filter from cache/state
    List<String> userSubjectIds = [];

    if (_isStudent(userProfile.role)) {
      userSubjectIds = userProfile.enrolledSubjects;
    } else if (_isInstructor(userProfile.role)) {
      userSubjectIds = userProfile.teachingSubjects;
    }

    if (userSubjectIds.isEmpty) {
      state = state.copyWith(filteredSubjects: []);
      return;
    }

    try {
      // First, check if we have all subjects in cache
      final cachedSubjects = CacheService.instance.getCachedSubjects();

      if (cachedSubjects.isNotEmpty) {
        // Filter from cache
        final filteredFromCache =
            cachedSubjects.where((s) => userSubjectIds.contains(s.id)).toList();

        if (kDebugMode) {
          print(
            '✅ SubjectProvider: Filtered ${filteredFromCache.length} subjects from cache - Zero server reads',
          );
        }

        state = state.copyWith(
          allSubjects: cachedSubjects, // Keep all subjects
          filteredSubjects: filteredFromCache, // Show only user's subjects
          isLoading: false,
        );
        return;
      }

      // No cache, fetch specific subjects from server
      if (kDebugMode) {
        print(
          '🔄 SubjectProvider: Fetching ${userSubjectIds.length} subjects from server...',
        );
      }

      state = state.copyWith(isLoading: true, error: null);

      final subjects = await _subjectService.getSubjectsByIds(userSubjectIds);

      state = SubjectState(
        allSubjects: subjects,
        filteredSubjects: subjects,
        isLoading: false,
      );

      if (kDebugMode) {
        print(
          '📚 SubjectProvider: Fetched ${subjects.length} filtered subjects',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ SubjectProvider: Error fetching filtered subjects - $e');
      }
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to fetch subjects: ${e.toString()}',
      );
    }
  }

  Future<void> updateFilteredSubjectsOnly(UserProfile? userProfile) async {
    if (userProfile == null) return;

    try {
      List<String> userSubjectIds = [];

      if (_isStudent(userProfile.role)) {
        userSubjectIds = userProfile.enrolledSubjects;
      } else if (_isInstructor(userProfile.role)) {
        userSubjectIds = userProfile.teachingSubjects;
      }

      if (userSubjectIds.isEmpty) {
        state = state.copyWith(filteredSubjects: []);
        return;
      }

      // Try to filter from existing state first (most efficient)
      if (state.allSubjects.isNotEmpty) {
        final filtered =
            state.allSubjects
                .where((s) => userSubjectIds.contains(s.id))
                .toList();

        if (kDebugMode) {
          print(
            '✅ SubjectProvider: Filtered ${filtered.length} subjects from state - Zero reads',
          );
        }
        state = state.copyWith(filteredSubjects: filtered);
        return;
      }

      // Try to filter from cache
      final cachedSubjects = CacheService.instance.getCachedSubjects();
      if (cachedSubjects.isNotEmpty) {
        final filtered =
            cachedSubjects.where((s) => userSubjectIds.contains(s.id)).toList();

        if (kDebugMode) {
          print(
            '✅ SubjectProvider: Filtered ${filtered.length} subjects from cache - Zero reads',
          );
        }
        state = state.copyWith(
          allSubjects: cachedSubjects,
          filteredSubjects: filtered,
        );
        return;
      }

      // Last resort: fetch from server
      if (kDebugMode) {
        print('🔄 SubjectProvider: Fetching filtered subjects from server...');
      }

      final filteredSubjects = await _subjectService.getSubjectsByIds(
        userSubjectIds,
      );
      state = state.copyWith(filteredSubjects: filteredSubjects);
    } catch (e) {
      if (kDebugMode) {
        print('❌ SubjectProvider: Error updating filtered subjects - $e');
      }
      state = state.copyWith(filteredSubjects: []);
    }
  }

  Future<void> fetchSpecificSubjects(List<String> subjectIds) async {
    if (subjectIds.isEmpty) {
      state = SubjectState(isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final subjects = await _subjectService.getSubjectsByIds(subjectIds);
      state = SubjectState(
        allSubjects: subjects,
        filteredSubjects: subjects,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to fetch specific subjects: ${e.toString()}',
      );
    }
  }

  Future<void> fetchAllSubjectsWithoutFilter() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final subjects = await _subjectService.getSubjects();
      state = SubjectState(
        allSubjects: subjects,
        filteredSubjects: subjects,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to fetch subjects: ${e.toString()}',
      );
    }
  }

  void resetFilter() {
    state = state.copyWith(filteredSubjects: state.allSubjects);
  }

  void setCachedSubjects(List<Subject> subjects) {
    state = SubjectState(
      allSubjects: subjects,
      filteredSubjects: subjects,
      isLoading: false,
    );

    if (kDebugMode) {
      print(
        '[SubjectProvider] Set ${subjects.length} cached subjects immediately',
      );
    }
  }

  /// Clear the current state to force fresh data fetch
  void clearCache() {
    state = SubjectState();
    if (kDebugMode) {
      print('[SubjectProvider] Cache cleared - next fetch will be fresh');
    }
  }
}

// Riverpod Provider
final SubjectProviderProvider =
    StateNotifierProvider<SubjectNotifier, SubjectState>((ref) {
      return SubjectNotifier();
    });
