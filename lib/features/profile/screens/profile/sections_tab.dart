import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pivot/models/user_profile.dart';
import 'package:pivot/providers/section_provider.dart';
import 'package:pivot/providers/subject_provider.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/features/profile/screens/profile_widgets/sections/sections.dart';

class SectionsTab extends StatefulWidget {
  const SectionsTab({super.key});

  @override
  State<SectionsTab> createState() => _SectionsTabState();
}

class _SectionsTabState extends State<SectionsTab> {
  bool _hasLoadedSections = false;
  UserProfile? _previousUserProfile;
  List<String> _previousEnrolledSubjects = [];
  Map<String, String> _previousAssistantPreferences = {};

  @override
  void initState() {
    super.initState();
    // Set up profile restoration listener
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final userProfileProvider = context.read<UserProfileProvider>();
        userProfileProvider.setOnProfileRestored(() {
          if (mounted) {
            final loggedInUser = userProfileProvider.loggedInUserProfile;
            if (loggedInUser != null) {
              _hasLoadedSections = false;
              _updatePreviousProfile(loggedInUser);
              _refreshDataProviders(loggedInUser);
              if (loggedInUser.enrolledSubjects.isNotEmpty) {
                _loadSectionsForUser(loggedInUser);
              }
            }
          }
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userProfileProvider = context.read<UserProfileProvider>();
    final userProfile = userProfileProvider.userProfile;
    final loggedInUser = userProfileProvider.loggedInUserProfile;

    // Determine which profile to use based on context
    final targetProfile = _getTargetProfile(userProfile, loggedInUser);

    if (targetProfile != null) {
      // Check if we need to reload due to profile changes
      final shouldReload = _shouldReloadDueToProfileChange(targetProfile);

      if (shouldReload) {
        // Reset loading state and reload
        _hasLoadedSections = false;
        _updatePreviousProfile(targetProfile);

        // Force refresh of data providers when switching profiles
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _refreshDataProviders(targetProfile);
            if (targetProfile.enrolledSubjects.isNotEmpty) {
              _loadSectionsForUser(targetProfile);
            }
          }
        });
      } else if (!_hasLoadedSections &&
          targetProfile.enrolledSubjects.isNotEmpty) {
        // Initial load
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _refreshDataProviders(targetProfile);
            _loadSectionsForUser(targetProfile);
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
    final sectionProvider = context.read<SectionProvider>();

    // Prevent multiple simultaneous loading calls
    if (sectionProvider.isLoading) {
      return;
    }

    if (userProfile.enrolledSubjects.isNotEmpty) {
      context
          .read<SectionProvider>()
          .fetchSectionsForUserSubjects(userProfile.enrolledSubjects)
          .then((_) {
            // Mark sections as loaded
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
            if (mounted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _hasLoadedSections =
                        true; // Mark as loaded even on error to prevent infinite retries
                  });
                }
              });
            }
          });
    } else {
      // Only clear sections if user has no enrolled subjects
      if (userProfile.enrolledSubjects.isEmpty) {
        context.read<SectionProvider>().resetFilter();
      }
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
      final subjectProvider = context.read<SubjectProvider>();
      final sectionProvider = context.read<SectionProvider>();

      // Refresh subject provider with the target profile
      subjectProvider.fetchAndFilterSubjects(targetProfile);

      // Clear and reload sections for the target profile
      if (targetProfile.enrolledSubjects.isNotEmpty) {
        sectionProvider.fetchSectionsForUserSubjects(
          targetProfile.enrolledSubjects,
        );
      } else {
        sectionProvider.resetFilter();
      }
    } catch (e) {
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SectionProvider>(
      builder: (context, sectionProvider, child) {
        try {
          if (sectionProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (sectionProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red.shade300,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'خطأ: ${sectionProvider.error}',
                    style: TextStyle(fontSize: 16, color: Colors.red.shade600),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final userProfileProvider =
                          context.read<UserProfileProvider>();
                      final userProfile = userProfileProvider.userProfile;
                      final loggedInUser =
                          userProfileProvider.loggedInUserProfile;
                      final targetProfile = _getTargetProfile(
                        userProfile,
                        loggedInUser,
                      );

                      if (targetProfile != null &&
                          targetProfile.enrolledSubjects.isNotEmpty) {
                        context
                            .read<SectionProvider>()
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
          final sectionSlivers = buildSectionsSlivers(context);

          return CustomScrollView(slivers: sectionSlivers);
        } catch (e) {
          return const Center(child: Text('لا يمكن تحميل الأقسام حالياً'));
        }
      },
    );
  }
}
