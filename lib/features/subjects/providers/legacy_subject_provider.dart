import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/models/subject_model.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/services/subject_service.dart';
import 'package:pivot/services/cache_service.dart';

// State class for subjects
class LegacySubjectState {
  final List<Subject> allSubjects;
  final List<Subject> filteredSubjects;
  final bool isLoading;
  final String? error;
  final Map<String, List<UserProfile>> instructorsBySubject;

  LegacySubjectState({
    this.allSubjects = const [],
    this.filteredSubjects = const [],
    this.isLoading = false,
    this.error,
    this.instructorsBySubject = const {},
  });

  LegacySubjectState copyWith({
    List<Subject>? allSubjects,
    List<Subject>? filteredSubjects,
    bool? isLoading,
    String? error,
    Map<String, List<UserProfile>>? instructorsBySubject,
  }) {
    return LegacySubjectState(
      allSubjects: allSubjects ?? this.allSubjects,
      filteredSubjects: filteredSubjects ?? this.filteredSubjects,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      instructorsBySubject: instructorsBySubject ?? this.instructorsBySubject,
    );
  }
}

// StateNotifier
class LegacySubjectNotifier extends StateNotifier<LegacySubjectState> {
  final SubjectService _subjectService = SubjectService();

  LegacySubjectNotifier() : super(LegacySubjectState());

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
    String? userLevel,
    String? userRole,
  }) async {
    // Prevent multiple simultaneous calls
    if (state.isLoading) {
      if (kDebugMode) {
        print(
          '[LegacySubjectProvider] Already loading, skipping duplicate call',
        );
      }
      return;
    }

    // Local-First Approach: Check cache first (unless forcing refresh)
    if (!forceRefresh) {
      // First check if data already exists in state (Riverpod cache)
      if (state.allSubjects.isNotEmpty && state.filteredSubjects.isNotEmpty) {
        if (kDebugMode) {
          print(
            '✅ [LegacySubjectProvider] Using subjects from Riverpod state (${state.allSubjects.length} subjects)',
          );
          print('   💡 Zero Firestore reads needed!');
        }
        return;
      }

      // Check Hive cache (local-first)
      try {
        final cachedSubjects = CacheService.instance.getCachedSubjects();
        if (cachedSubjects.isNotEmpty) {
          if (kDebugMode) {
            print(
              '📦 [LegacySubjectProvider] Loading subjects from Hive cache (${cachedSubjects.length} subjects)',
            );
            print('   ⚡ Instant load - no Firestore read!');
            print('   💡 Cache will refresh only when subjects are updated');
          }

          state = LegacySubjectState(
            allSubjects: cachedSubjects,
            filteredSubjects: cachedSubjects,
            isLoading: false,
          );
          return;
        }
      } catch (cacheError) {
        if (kDebugMode) {
          print('[LegacySubjectProvider] Cache read error: $cacheError');
        }
        // Continue to fetch from Firestore
      }
    }

    // Cache miss or force refresh - fetch from Firestore
    if (kDebugMode) {
      print(
        '🔄 [LegacySubjectProvider] ${forceRefresh ? "Force refreshing" : "First time loading"} subjects from Firestore...',
      );
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      List<Subject> subjects;

      // Determine which subjects to fetch based on user level
      final shouldFilterByLevel =
          userLevel != null &&
          userLevel != 'غير محدد' &&
          userRole != 'Super Admin';

      if (shouldFilterByLevel) {
        final level = int.tryParse(userLevel);
        if (level != null) {
          if (level == 1 || level == 2) {
            // Fetch only first 4 semesters (years 1-4)
            subjects = await _subjectService.getSubjectsByYearRange(1, 4);
            if (kDebugMode) {
              print(
                '📚 [LegacySubjectProvider] Fetching subjects for Level $level (Years 1-4 only)',
              );
            }
          } else if (level == 3 || level == 4) {
            // Fetch only semesters 5 and above
            subjects = await _subjectService.getSubjectsByYearRange(5, 99);
            if (kDebugMode) {
              print(
                '📚 [LegacySubjectProvider] Fetching subjects for Level $level (Years 5+ only)',
              );
            }
          } else {
            // Unknown level, fetch all
            subjects = await _subjectService.getSubjects();
          }
        } else {
          // Invalid level format, fetch all
          subjects = await _subjectService.getSubjects();
        }
      } else {
        // Super Admin or no level filtering - fetch all
        subjects = await _subjectService.getSubjects();
        if (kDebugMode && userRole == 'Super Admin') {
          print(
            '📚 [LegacySubjectProvider] Super Admin: Fetching all subjects',
          );
        }
      }

      // Set filteredSubjects to show all fetched subjects
      state = LegacySubjectState(
        allSubjects: subjects,
        filteredSubjects: subjects,
        isLoading: false,
      );

      // Cache the subjects for future instant access
      if (subjects.isNotEmpty) {
        await CacheService.instance.cacheSubjects(subjects);
        if (kDebugMode) {
          print(
            '✅ [LegacySubjectProvider] Fetched and cached ${subjects.length} subjects',
          );
          print('   💾 Stored in Hive for instant future access');
        }
      }
    } catch (e) {
      // Error - try to use stale cache as fallback
      try {
        final cachedSubjects = CacheService.instance.getCachedSubjects();
        if (cachedSubjects.isNotEmpty) {
          if (kDebugMode) {
            print(
              '⚠️ [LegacySubjectProvider] Firestore error, using cached subjects (${cachedSubjects.length} subjects)',
            );
          }
          state = LegacySubjectState(
            allSubjects: cachedSubjects,
            filteredSubjects: cachedSubjects,
            isLoading: false,
          );
        } else {
          state = state.copyWith(
            isLoading: false,
            error: 'Failed to fetch all subjects: ${e.toString()}',
          );
        }
      } catch (cacheError) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to fetch all subjects: ${e.toString()}',
        );
        if (kDebugMode) {
          print(
            '[LegacySubjectProvider] Cache fallback also failed: $cacheError',
          );
        }
      }
    }
  }

  Future<void> addSubject(Subject subject) async {
    try {
      final newSubject = await _subjectService.addSubject(subject);
      final updatedSubjects = [...state.allSubjects, newSubject];
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

    state = state.copyWith(isLoading: true, error: null);

    try {
      // For admin users, fetch all subjects
      if (userProfile.role == 'Admin' || userProfile.role == 'Super Admin') {
        final subjects = await _subjectService.getSubjects();
        state = LegacySubjectState(
          allSubjects: subjects,
          filteredSubjects: subjects,
          isLoading: false,
        );
      } else {
        List<String> userSubjectIds = [];

        if (_isStudent(userProfile.role)) {
          userSubjectIds = userProfile.enrolledSubjects;
        } else if (_isInstructor(userProfile.role)) {
          userSubjectIds = userProfile.teachingSubjects;
        }

        if (userSubjectIds.isNotEmpty) {
          final subjects = await _subjectService.getSubjectsByIds(
            userSubjectIds,
          );
          state = LegacySubjectState(
            allSubjects: subjects,
            filteredSubjects: subjects,
            isLoading: false,
          );
        } else {
          state = LegacySubjectState(isLoading: false);
        }
      }
    } catch (e) {
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

      if (userSubjectIds.isNotEmpty) {
        final filteredSubjects = await _subjectService.getSubjectsByIds(
          userSubjectIds,
        );
        state = state.copyWith(filteredSubjects: filteredSubjects);
      } else {
        state = state.copyWith(filteredSubjects: []);
      }
    } catch (e) {
      state = state.copyWith(filteredSubjects: []);
    }
  }

  Future<void> fetchSpecificSubjects(List<String> subjectIds) async {
    if (subjectIds.isEmpty) {
      state = LegacySubjectState(isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final subjects = await _subjectService.getSubjectsByIds(subjectIds);
      state = LegacySubjectState(
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
      state = LegacySubjectState(
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
    state = LegacySubjectState(
      allSubjects: subjects,
      filteredSubjects: subjects,
      isLoading: false,
    );

    if (kDebugMode) {
      print(
        '[LegacySubjectProvider] Set ${subjects.length} cached subjects immediately',
      );
    }
  }
}

// Riverpod Provider
final legacySubjectProviderProvider =
    StateNotifierProvider<LegacySubjectNotifier, LegacySubjectState>((ref) {
      return LegacySubjectNotifier();
    });
