import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/tasks/providers/tasks_provider.dart';
import 'package:pivot/features/subjects/providers/subjects_provider.dart';
import 'package:pivot/features/administration/providers/sections_provider.dart';
import 'package:pivot/models/user_profile.dart';

/// Service to preload data for better user experience
/// Eliminates loading times when navigating between screens
class DataPreloaderService {
  static final DataPreloaderService _instance =
      DataPreloaderService._internal();
  factory DataPreloaderService() => _instance;
  DataPreloaderService._internal();

  /// Preload all data needed for week_tasks screen
  /// This should be called when user opens profile to eliminate loading time
  static Future<void> preloadWeekTasksData(
    WidgetRef ref,
    UserProfile user,
  ) async {
    try {
      print('🚀 DataPreloader: Starting preload for user ${user.id}');

      // Get current states to avoid redundant fetches
      final tasksState = ref.read(tasksProvider);
      final subjectsState = ref.read(subjectsProvider);
      final sectionsState = ref.read(sectionsProvider);

      // Create list of futures for parallel execution
      final futures = <Future>[];

      // Only fetch tasks if not already loaded
      if (tasksState.tasks.isEmpty && !tasksState.isLoading) {
        futures.add(ref.read(tasksProvider.notifier).getAllTasks());
        print('📋 DataPreloader: Scheduling tasks fetch');
      } else {
        print(
          '📋 DataPreloader: Tasks already loaded (${tasksState.tasks.length} items)',
        );
      }

      // Only fetch subjects if not already loaded
      if (subjectsState.filteredSubjects.isEmpty && !subjectsState.isLoading) {
        futures.add(
          ref.read(subjectsProvider.notifier).fetchAndFilterSubjects(user),
        );
        print('📚 DataPreloader: Scheduling subjects fetch');
      } else {
        print(
          '📚 DataPreloader: Subjects already loaded (${subjectsState.filteredSubjects.length} items)',
        );
      }

      // Only fetch sections if not already loaded and user has enrolled subjects
      if (user.enrolledSubjects.isNotEmpty &&
          sectionsState.sections.isEmpty &&
          !sectionsState.isLoading) {
        futures.add(
          ref
              .read(sectionsProvider.notifier)
              .fetchSectionsForUserSubjects(user.enrolledSubjects),
        );
        print(
          '🏫 DataPreloader: Scheduling sections fetch for ${user.enrolledSubjects.length} subjects',
        );
      } else if (user.enrolledSubjects.isEmpty) {
        print(
          '🏫 DataPreloader: No enrolled subjects, skipping sections fetch',
        );
      } else {
        print(
          '🏫 DataPreloader: Sections already loaded (${sectionsState.sections.length} items)',
        );
      }

      // Execute all fetches in parallel if needed
      if (futures.isNotEmpty) {
        print(
          '⚡ DataPreloader: Executing ${futures.length} parallel fetches...',
        );
        await Future.wait(futures);
        print('✅ DataPreloader: All data preloaded successfully');
      } else {
        print(
          '✅ DataPreloader: All data already available - zero reads needed',
        );
      }
    } catch (e) {
      print('❌ DataPreloader: Error during preload - $e');
      // Don't throw - let individual screens handle their own loading states
    }
  }

  /// Preload data for specific user subjects
  /// Useful for targeted preloading
  static Future<void> preloadSubjectData(
    WidgetRef ref,
    List<String> subjectIds,
  ) async {
    try {
      final sectionsState = ref.read(sectionsProvider);

      if (subjectIds.isNotEmpty &&
          sectionsState.sections.isEmpty &&
          !sectionsState.isLoading) {
        print(
          '🎯 DataPreloader: Preloading sections for ${subjectIds.length} subjects',
        );
        await ref
            .read(sectionsProvider.notifier)
            .fetchSectionsForUserSubjects(subjectIds);
      }
    } catch (e) {
      print('❌ DataPreloader: Error preloading subject data - $e');
    }
  }

  /// Check if data is ready for week_tasks screen
  /// Returns true if all required data is available
  static bool isWeekTasksDataReady(WidgetRef ref, UserProfile user) {
    final tasksState = ref.read(tasksProvider);
    final subjectsState = ref.read(subjectsProvider);
    final sectionsState = ref.read(sectionsProvider);

    // Check if we have the essential data
    final hasTasks = tasksState.tasks.isNotEmpty || tasksState.isLoading;
    final hasSubjects =
        subjectsState.filteredSubjects.isNotEmpty || subjectsState.isLoading;
    final hasSections =
        sectionsState.sections.isNotEmpty ||
        sectionsState.isLoading ||
        user.enrolledSubjects.isEmpty;

    final isReady = hasTasks && hasSubjects && hasSections;

    if (isReady) {
      print(
        '✅ DataPreloader: Week tasks data is ready (T:${tasksState.tasks.length}, S:${subjectsState.filteredSubjects.length}, Sec:${sectionsState.sections.length})',
      );
    } else {
      print(
        '⏳ DataPreloader: Week tasks data not ready (T:$hasTasks, S:$hasSubjects, Sec:$hasSections)',
      );
    }

    return isReady;
  }

  /// Background refresh - keeps data fresh without blocking UI
  static Future<void> backgroundRefresh(WidgetRef ref) async {
    try {
      print('🔄 DataPreloader: Starting background refresh...');

      final futures = <Future>[];

      // Only refresh if data is stale
      if (ref.read(tasksProvider.notifier).isDataStale) {
        futures.add(ref.read(tasksProvider.notifier).backgroundRefresh());
      }

      if (ref.read(subjectsProvider.notifier).isDataStale) {
        futures.add(ref.read(subjectsProvider.notifier).backgroundRefresh());
      }

      if (futures.isNotEmpty) {
        await Future.wait(futures);
        print('✅ DataPreloader: Background refresh completed');
      } else {
        print('✅ DataPreloader: No stale data found - skipping refresh');
      }
    } catch (e) {
      print('❌ DataPreloader: Background refresh failed - $e');
    }
  }

  /// Get data readiness status for debugging
  static Map<String, dynamic> getDataStatus(WidgetRef ref, UserProfile user) {
    final tasksState = ref.read(tasksProvider);
    final subjectsState = ref.read(subjectsProvider);
    final sectionsState = ref.read(sectionsProvider);

    return {
      'tasks': {
        'count': tasksState.tasks.length,
        'loading': tasksState.isLoading,
        'error': tasksState.error,
        'stale': ref.read(tasksProvider.notifier).isDataStale,
      },
      'subjects': {
        'count': subjectsState.filteredSubjects.length,
        'loading': subjectsState.isLoading,
        'error': subjectsState.error,
        'stale': ref.read(subjectsProvider.notifier).isDataStale,
      },
      'sections': {
        'count': sectionsState.sections.length,
        'loading': sectionsState.isLoading,
        'error': sectionsState.error,
      },
      'user': {
        'enrolledSubjects': user.enrolledSubjects.length,
        'section': user.section,
      },
      'ready': isWeekTasksDataReady(ref, user),
    };
  }
}

/// Provider for data preloader service
final dataPreloaderProvider = Provider<DataPreloaderService>((ref) {
  return DataPreloaderService();
});
