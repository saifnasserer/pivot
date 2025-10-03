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
  bool _hasLoadedSections = false;
  UserProfile? _previousUserProfile;
  List<String> _previousEnrolledSubjects = [];
  Map<String, String> _previousAssistantPreferences = {};

  @override
  void initState() {
    super.initState();
    // Sections will auto-load through Riverpod
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userProfileState = ref.read(userProfileProvider);
    final userProfile = userProfileState.userProfile;
    final loggedInUser = userProfileState.loggedInUserProfile;

    // Determine which profile to use based on context
    final targetProfile = _getTargetProfile(userProfile, loggedInUser);

    if (targetProfile != null) {
      // Check if we need to reload due to profile changes
      final shouldReload = _shouldReloadDueToProfileChange(targetProfile);

      if (shouldReload) {
        print('🔄 SectionsTab: Profile changed, reloading...');
        // Reset loading state and reload
        _hasLoadedSections = false;
        _updatePreviousProfile(targetProfile);

        // Force refresh of data providers when switching profiles
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _refreshDataProviders(targetProfile);
            if (targetProfile.enrolledSubjects.isNotEmpty) {
              _loadSectionsForUser(targetProfile);
            } else {
              setState(() {
                _hasLoadedSections = true;
              });
            }
          }
        });
      } else if (!_hasLoadedSections) {
        _updatePreviousProfile(targetProfile);
        // Initial load
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _refreshDataProviders(targetProfile);
            if (targetProfile.enrolledSubjects.isNotEmpty) {
              _loadSectionsForUser(targetProfile);
            } else {
              setState(() {
                _hasLoadedSections = true;
              });
            }
          }
        });
      }
    }
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

  bool _shouldReloadDueToProfileChange(UserProfile currentProfile) {
    // Check if enrolled subjects changed
    if (!_areListsEqual(
      _previousEnrolledSubjects,
      currentProfile.enrolledSubjects,
    )) {
      return true;
    }

    // Check if assistant preferences changed
    if (!_areMapsEqual(
      _previousAssistantPreferences,
      currentProfile.assistantPreferences,
    )) {
      return true;
    }

    // Check if user profile itself changed (different instance)
    if (_previousUserProfile != currentProfile) {
      return true;
    }

    return false;
  }

  void _updatePreviousProfile(UserProfile profile) {
    _previousUserProfile = profile;
    _previousEnrolledSubjects = List.from(profile.enrolledSubjects);
    _previousAssistantPreferences = Map.from(profile.assistantPreferences);
  }

  bool _areListsEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  bool _areMapsEqual(Map<String, String> map1, Map<String, String> map2) {
    if (map1.length != map2.length) return false;
    for (final key in map1.keys) {
      if (map1[key] != map2[key]) return false;
    }
    return true;
  }

  void _loadSectionsForUser(UserProfile userProfile) {
    final sectionsState = ref.read(sectionsProvider);
    final hasData = sectionsState.sections.isNotEmpty;

    // Prevent multiple simultaneous loading calls
    if (sectionsState.isLoading) {
      return;
    }

    if (userProfile.enrolledSubjects.isNotEmpty) {
      // Only fetch if data is not already loaded
      if (!hasData && !sectionsState.isLoading) {
        print('🔄 SectionsTab: Fetching sections...');
        ref
            .read(sectionsProvider.notifier)
            .fetchSectionsForUserSubjects(userProfile.enrolledSubjects)
            .then((_) {
              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _hasLoadedSections = true;
                    });
                  }
                });
              }
            })
            .catchError((error) {
              print('❌ SectionsTab: Fetch error - $error');
              if (mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _hasLoadedSections = true;
                    });
                  }
                });
              }
            });
      } else if (hasData) {
        print(
          '✅ SectionsTab: Reusing data from WeekTasks (${sectionsState.sections.length} sections) - Zero reads',
        );
        setState(() {
          _hasLoadedSections = true;
        });
      }
    } else {
      ref.read(sectionsProvider.notifier).resetFilter();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _hasLoadedSections = true;
          });
        }
      });
    }
  }

  void _refreshDataProviders(UserProfile targetProfile) {
    try {
      // Refresh subjects
      ref.read(subjectsProvider.notifier).fetchAndFilterSubjects(targetProfile);

      // Clear and reload sections for the target profile
      if (targetProfile.enrolledSubjects.isNotEmpty) {
        ref
            .read(sectionsProvider.notifier)
            .fetchSectionsForUserSubjects(targetProfile.enrolledSubjects);
      } else {
        ref.read(sectionsProvider.notifier).resetFilter();
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    final sectionsState = ref.watch(sectionsProvider);
    final userProfileState = ref.watch(userProfileProvider);

    try {
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
                  final userProfile = userProfileState.userProfile;
                  final loggedInUser = userProfileState.loggedInUserProfile;
                  final targetProfile = _getTargetProfile(
                    userProfile,
                    loggedInUser,
                  );

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
