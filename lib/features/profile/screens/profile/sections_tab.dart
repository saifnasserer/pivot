import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/user/providers/user_profile_provider.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/features/administration/providers/sections_provider.dart';
import 'package:pivot/features/subjects/providers/subjects_provider.dart';
import 'package:pivot/features/profile/screens/profile_widgets/sections/sections.dart';

class SectionsTab extends ConsumerStatefulWidget {
  const SectionsTab({super.key});

  @override
  ConsumerState<SectionsTab> createState() => _SectionsTabState();
}

class _SectionsTabState extends ConsumerState<SectionsTab> {
  bool _hasInitialized = false;
  String? _lastProfileId; // Track profile changes
  List<String>? _lastEnrolledSubjects; // Track enrolled subjects changes
  Map<String, String>? _lastAssistantPreferences; // Track assistant preferences

  @override
  void initState() {
    super.initState();
    // Load sections on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasInitialized) {
        _initializeSections();
      }
    });
  }

  void _initializeSections() {
    final userProfileState = ref.read(userProfileProvider);
    final sectionsState = ref.read(sectionsProvider);
    final targetProfile = _getTargetProfile(
      userProfileState.userProfile,
      userProfileState.loggedInUserProfile,
    );

    if (targetProfile != null) {
      final hasSections = sectionsState.sections.isNotEmpty;

      print(
        '📊 SectionsTab: hasSections=$hasSections, isLoading=${sectionsState.isLoading}',
      );
      print('📊 SectionsTab: ${sectionsState.sections.length} sections cached');

      // Fetch if no data and not loading
      if (!hasSections && !sectionsState.isLoading) {
        print('🔄 SectionsTab: Fetching sections...');
        _refreshDataProviders(targetProfile);
        if (targetProfile.enrolledSubjects.isNotEmpty) {
          _loadSectionsForUser(targetProfile);
        }
      } else if (hasSections) {
        print(
          '✅ SectionsTab: Reusing cached sections (${sectionsState.sections.length} total) - Zero reads',
        );
      }

      _hasInitialized = true;
    }
  }

  @override
  void didUpdateWidget(SectionsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh when widget updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeSections();
      }
    });
  }

  UserProfile? _getTargetProfile(
    UserProfile? userProfile,
    UserProfile? loggedInUser,
  ) {
    // If we're viewing someone else's profile, show their sections
    if (userProfile != null &&
        loggedInUser != null &&
        userProfile.id != loggedInUser.id) {
      return userProfile;
    }

    // Otherwise, show logged-in user's sections
    return loggedInUser;
  }

  // Helper method to compare lists (like subjects_tab.dart)
  bool _listsEqual(List<String>? list1, List<String> list2) {
    if (list1 == null) return false;
    if (list1.length != list2.length) return false;

    final set1 = list1.toSet();
    final set2 = list2.toSet();

    return set1.containsAll(set2) && set2.containsAll(set1);
  }

  // Helper method to compare maps
  bool _mapsEqual(Map<String, String>? map1, Map<String, String> map2) {
    if (map1 == null) return false;
    if (map1.length != map2.length) return false;

    for (final key in map1.keys) {
      if (map1[key] != map2[key]) return false;
    }
    return true;
  }

  void _loadSectionsForUser(UserProfile userProfile) {
    final sectionsState = ref.read(sectionsProvider);

    // Prevent multiple simultaneous loading calls
    if (sectionsState.isLoading) {
      print('⏳ SectionsTab: Already loading, skipping...');
      return;
    }

    if (userProfile.enrolledSubjects.isNotEmpty) {
      // Check if we already have sections for these subjects in cache/state
      final hasRelevantData = sectionsState.sections.any(
        (s) => userProfile.enrolledSubjects.contains(s.subjectId),
      );

      if (hasRelevantData) {
        // We have data, just filter it locally
        print(
          '✅ SectionsTab: Using cached sections (${sectionsState.sections.length} total) - Zero server reads',
        );
      } else {
        // No relevant data, fetch from server (provider will check cache first)
        print('📦 SectionsTab: Fetching sections for subjects...');
        ref
            .read(sectionsProvider.notifier)
            .fetchSectionsForUserSubjects(userProfile.enrolledSubjects)
            .catchError((error) {
              print('❌ SectionsTab: Fetch error - $error');
            });
      }
    } else {
      // No enrolled subjects
      ref.read(sectionsProvider.notifier).resetFilter();
    }
  }

  void _refreshDataProviders(UserProfile targetProfile) {
    try {
      // Only refresh subjects provider here
      // Sections will be loaded by _loadSectionsForUser() to avoid duplicate fetches
      ref.read(subjectsProvider.notifier).fetchAndFilterSubjects(targetProfile);
    } catch (e) {
      print('❌ SectionsTab: Error refreshing data providers - $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final sectionsState = ref.watch(sectionsProvider);
    final userProfileState = ref.watch(userProfileProvider);

    try {
      // Get the correct profile to use
      final userProfile = userProfileState.userProfile;
      final loggedInUser = userProfileState.loggedInUserProfile;
      final targetProfile = _getTargetProfile(userProfile, loggedInUser);

      // Check if profile or enrolled subjects or preferences changed (without triggering refresh in build)
      if (targetProfile != null && _hasInitialized) {
        final currentProfileId = targetProfile.id;
        final currentEnrolledSubjects = targetProfile.enrolledSubjects;
        final currentAssistantPreferences = targetProfile.assistantPreferences;

        // Only refresh if profile ID, enrolled subjects, or assistant preferences actually changed
        if (_lastProfileId != currentProfileId ||
            !_listsEqual(_lastEnrolledSubjects, currentEnrolledSubjects) ||
            !_mapsEqual(
              _lastAssistantPreferences,
              currentAssistantPreferences,
            )) {
          // Update tracking variables FIRST to prevent infinite loop
          _lastProfileId = currentProfileId;
          _lastEnrolledSubjects = List.from(currentEnrolledSubjects);
          _lastAssistantPreferences = Map.from(currentAssistantPreferences);

          // Schedule refresh for next frame
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              print('🔄 SectionsTab: Profile changed, refreshing...');
              _refreshDataProviders(targetProfile);
              if (targetProfile.enrolledSubjects.isNotEmpty) {
                _loadSectionsForUser(targetProfile);
              }
            }
          });
        }
      } else if (targetProfile != null) {
        // Initialize tracking on first build
        _lastProfileId = targetProfile.id;
        _lastEnrolledSubjects = List.from(targetProfile.enrolledSubjects);
        _lastAssistantPreferences = Map.from(
          targetProfile.assistantPreferences,
        );
      }

      if (sectionsState.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (sectionsState.error != null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              SizedBox(height: 16),
              Text(
                'خطأ: ${sectionsState.error}',
                style: TextStyle(fontSize: 16, color: Colors.red.shade600),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (targetProfile != null &&
                      targetProfile.enrolledSubjects.isNotEmpty) {
                    ref
                        .read(sectionsProvider.notifier)
                        .fetchSectionsForUserSubjects(
                          targetProfile.enrolledSubjects,
                        );
                  }
                },
                child: Text('إعادة المحاولة'),
              ),
            ],
          ),
        );
      }

      // Build sections slivers - this will handle all states internally
      final sectionSlivers = buildSectionsSlivers(context, ref);

      return CustomScrollView(slivers: sectionSlivers);
    } catch (e) {
      return const Center(child: Text('لا يمكن تحميل الأقسام حالياً'));
    }
  }
}
