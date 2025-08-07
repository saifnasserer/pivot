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
  bool _isLoadingSections = false;

  @override
  void initState() {
    super.initState();
    // Initial load will be handled in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userProfile = context.read<UserProfileProvider>().userProfile;

    if (userProfile != null && userProfile.enrolledSubjects.isNotEmpty) {
      // Simple loading like subjects tab - just load once when dependencies change
      if (!_hasLoadedSections) {
        // Use post-frame callback to avoid build-time notifyListeners
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
    final sectionProvider = context.read<SectionProvider>();

    // Prevent multiple simultaneous loading calls
    if (_isLoadingSections || sectionProvider.isLoading) {
      return;
    }

    if (userProfile != null && userProfile.enrolledSubjects.isNotEmpty) {
      // Set loading flag
      _isLoadingSections = true;

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
                    _isLoadingSections = false;
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
                    _isLoadingSections = false;
                  });
                }
              });
            }
          });
    } else {
      // Only clear sections if user has no enrolled subjects
      if (userProfile != null && userProfile.enrolledSubjects.isEmpty) {
        context.read<SectionProvider>().resetFilter();
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _hasLoadedSections = true;
            _isLoadingSections = false;
          });
        }
      });
    }
  }

  // Method to reset loading state when tab becomes visible
  void _resetLoadingState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _hasLoadedSections = false;
          _isLoadingSections = false;
        });
      }
    });
  }

  // Method to force reload sections (for manual refresh)
  void _forceReloadSections() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _hasLoadedSections = false;
          _isLoadingSections = false;
        });
        _loadSectionsForUser();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SectionProvider>(
      builder: (context, sectionProvider, child) {
        // Get user profile and enrolled subjects
        final userProfile = context.read<UserProfileProvider>().userProfile;
        final enrolledSubjects = userProfile?.enrolledSubjects ?? [];

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
