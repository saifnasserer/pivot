import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pivot/models/user_profile.dart';
import 'package:pivot/providers/section_provider.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/screens/section3/profile_widgets/sections/sections.dart';

class SectionsTab extends StatefulWidget {
  const SectionsTab({super.key});

  @override
  State<SectionsTab> createState() => _SectionsTabState();
}

class _SectionsTabState extends State<SectionsTab> {
  UserProfile? _previousUserProfile;
  List<String> _previousEnrolledSubjects = [];
  bool _hasLoadedSections = false;

  @override
  void initState() {
    super.initState();
    // Load sections when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadSectionsForUser();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userProfile = context.read<UserProfileProvider>().userProfile;

    if (userProfile != null) {
      final currentEnrolledSubjects = userProfile.enrolledSubjects;

      // Check if we need to reload sections
      bool shouldReload = false;

      // Reload if user profile changed
      if (userProfile != _previousUserProfile) {
        _previousUserProfile = userProfile;
        shouldReload = true;
        print('User profile changed, reloading sections');
      }

      // Reload if enrolled subjects changed
      if (!_areListsEqual(currentEnrolledSubjects, _previousEnrolledSubjects)) {
        _previousEnrolledSubjects = List.from(currentEnrolledSubjects);
        shouldReload = true;
        print('Enrolled subjects changed, reloading sections');
      }

      // Reload if sections haven't been loaded yet
      if (!_hasLoadedSections) {
        shouldReload = true;
        print('Sections not loaded yet, loading sections');
      }

      // Reload if sections are empty but user has enrolled subjects
      final sectionProvider = context.read<SectionProvider>();
      if (currentEnrolledSubjects.isNotEmpty &&
          sectionProvider.sections.isEmpty &&
          !sectionProvider.isLoading) {
        shouldReload = true;
        print('Sections are empty but user has enrolled subjects, reloading');
      }

      if (shouldReload) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _loadSectionsForUser();
          }
        });
      }
    }
  }

  bool _areListsEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  void _loadSectionsForUser() {
    final userProfile = context.read<UserProfileProvider>().userProfile;
    if (userProfile != null) {
      if (userProfile.enrolledSubjects.isNotEmpty) {
        print(
          'Loading sections for user with ${userProfile.enrolledSubjects.length} enrolled subjects',
        );
        // Use post-frame callback to ensure this happens after build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context
                .read<SectionProvider>()
                .fetchSectionsForUserSubjects(userProfile.enrolledSubjects)
                .then((_) {
                  // Mark sections as loaded
                  if (mounted) {
                    setState(() {
                      _hasLoadedSections = true;
                    });
                  }
                });
          }
        });
      } else {
        print('User has no enrolled subjects, clearing sections');
        // Clear sections if user has no enrolled subjects
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.read<SectionProvider>().resetFilter();
            setState(() {
              _hasLoadedSections = true;
            });
          }
        });
      }
    } else {
      print('No user profile found');
    }
  }

  // Method to reset loading state when tab becomes visible
  void _resetLoadingState() {
    setState(() {
      _hasLoadedSections = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SectionProvider>(
      builder: (context, sectionProvider, child) {
        // Get user profile and enrolled subjects
        final userProfile = context.read<UserProfileProvider>().userProfile;
        final enrolledSubjects = userProfile?.enrolledSubjects ?? [];

        // Always ensure sections are loaded when tab is visible
        if (userProfile != null &&
            enrolledSubjects.isNotEmpty &&
            !sectionProvider.isLoading) {
          // Check if sections need to be loaded
          if (!_hasLoadedSections || sectionProvider.sections.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _loadSectionsForUser();
              }
            });
          }
        }

        // Always show loading indicator when loading
        if (sectionProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Show error if there's an error
        if (sectionProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                SizedBox(height: 16),
                Text(
                  'خطأ: ${sectionProvider.error}',
                  style: TextStyle(fontSize: 16, color: Colors.red.shade600),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (userProfile != null && enrolledSubjects.isNotEmpty) {
                      context
                          .read<SectionProvider>()
                          .fetchSectionsForUserSubjects(enrolledSubjects);
                    }
                  },
                  child: Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
        }

        // If user has no enrolled subjects, show appropriate message
        if (enrolledSubjects.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.school_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                SizedBox(height: 16),
                Text(
                  'لا توجد مواد مسجلة',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'يجب التسجيل في المواد أولاً لعرض الأقسام',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // Build sections slivers - this will handle empty state internally
        final sectionSlivers = buildSectionsSlivers(context);

        return CustomScrollView(slivers: sectionSlivers);
      },
    );
  }
}
