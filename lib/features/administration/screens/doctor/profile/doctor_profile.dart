import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/models/lecture_model.dart';
import 'package:pivot/models/subject_model.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/features/subjects/providers/subject_provider.dart';
import 'package:pivot/features/user/providers/user_profile_provider.dart';
import 'package:pivot/services/doctor_subject_service.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/features/administration/screens/doctor/add_lecture_dialog.dart';
import 'package:pivot/features/administration/screens/doctor/doctor_categories.dart';
import 'package:pivot/features/administration/screens/doctor/profile/about_section.dart';
import 'package:pivot/features/administration/screens/doctor/profile/subjects_section.dart';
import 'package:pivot/features/profile/screens/profile_widgets/Profile_options.dart';
import 'package:pivot/features/subjects/screens/subject_selection_screen.dart';
import 'package:pivot/widgets/no_internet_message.dart';

class DoctorProfile extends ConsumerStatefulWidget {
  const DoctorProfile({super.key});

  @override
  ConsumerState<DoctorProfile> createState() => _DoctorProfileState();
}

class _DoctorProfileState extends ConsumerState<DoctorProfile>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  UserProfile? _displayedProfile;
  String? _previousProfileId;
  late ScrollController _scrollController;
  String _currentCategory = 'المواد';
  Subject? _currentSubject;
  Subject?
  _targetSubject; // Subject to navigate to when coming from subject details

  // Callback to refresh lectures in SubjectsSection
  VoidCallback? _refreshLecturesCallback;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && _displayedProfile != null) {
      // Refresh profile data when app becomes active
      _refreshProfileData();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final argument = ModalRoute.of(context)?.settings.arguments;
    UserProfile? profileToShow;
    Subject? targetSubject;

    // Handle different argument types
    if (argument is UserProfile) {
      profileToShow = argument;
    } else if (argument is Map<String, dynamic>) {
      profileToShow = argument['instructor'] as UserProfile?;
      targetSubject = argument['subject'] as Subject?;
    } else {
      profileToShow = ref.watch(userProfileProvider).userProfile;
    }

    if (profileToShow != null) {
      // Always refresh data when profile is opened
      bool isNewProfile = profileToShow.id != _previousProfileId;

      if (isNewProfile) {
        _displayedProfile = profileToShow;
        _previousProfileId = profileToShow.id;
      }

      // Store target subject for later use
      if (targetSubject != null) {
        _targetSubject = targetSubject;
      }

      // Always fetch fresh data when profile is opened
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && profileToShow != null) {
          // Always refresh profile data when opening
          _refreshProfileData();
        }
      });
    }
  }

  void _fetchInitialData(UserProfile userProfile) {
    if (!mounted) return;

    print(
      '_fetchInitialData called for user: ${userProfile.name} (${userProfile.role})',
    );
    print('Teaching subjects: ${userProfile.teachingSubjects}');

    // Check if this is the logged-in user's own profile
    final loggedInUser = ref.read(userProfileProvider).userProfile;
    final isOwnProfile = loggedInUser?.id == userProfile.id;
    print('Is own profile: $isOwnProfile');
    print('Logged in user ID: ${loggedInUser?.id}');
    print('Displayed profile ID: ${userProfile.id}');

    // Use logged-in user's profile data when viewing own profile to ensure correct teaching subjects
    final profileToUse = isOwnProfile ? loggedInUser! : userProfile;
    print(
      'Using profile: ${profileToUse.name} with teaching subjects: ${profileToUse.teachingSubjects}',
    );

    // Only fetch and filter subjects - let SubjectsSection handle lecture loading
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      try {
        // For now, using legacy provider access
        final subjectProvider = ref.read(SubjectProviderProvider);

        print(
          'Calling fetchAndFilterSubjects for profile: ${profileToUse.name}',
        );
        // Just fetch and filter subjects - no lecture loading here
        ref
            .read(SubjectProviderProvider.notifier)
            .fetchAndFilterSubjects(profileToUse)
            .then((_) {
              print(
                'fetchAndFilterSubjects completed for ${profileToUse.name}',
              );
              print(
                'Filtered subjects count: ${subjectProvider.filteredSubjects.length}',
              );
            })
            .catchError((error) {
              print('Error in fetchAndFilterSubjects: $error');
            });
      } catch (e) {
        print('Provider access error: $e');
      }
    });
  }

  Future<void> _refreshProfileData() async {
    if (!mounted) return;

    // If we don't have a displayed profile yet, get it from the arguments
    String? profileIdToRefresh;
    if (_displayedProfile != null) {
      profileIdToRefresh = _displayedProfile!.id;
    } else {
      // Get profile from arguments for initial load
      final argument = ModalRoute.of(context)?.settings.arguments;
      UserProfile? profileFromArgs;

      if (argument is UserProfile) {
        profileFromArgs = argument;
      } else if (argument is Map<String, dynamic>) {
        profileFromArgs = argument['instructor'] as UserProfile?;
      } else {
        profileFromArgs = ref.read(userProfileProvider).userProfile;
      }

      if (profileFromArgs != null) {
        profileIdToRefresh = profileFromArgs.id;
        // Set the displayed profile first
        setState(() {
          _displayedProfile = profileFromArgs;
        });
      }
    }

    if (profileIdToRefresh == null) return;

    try {
      print(
        '🔄 [DoctorProfile] Refreshing profile data for ID: $profileIdToRefresh',
      );

      // Fetch fresh profile data from Firestore
      final freshProfile = await ref
          .read(userProfileProvider.notifier)
          .getUserProfileById(profileIdToRefresh);

      if (freshProfile != null && mounted) {
        setState(() {
          _displayedProfile = freshProfile;
        });
        print(
          '🔄 [DoctorProfile] Profile data refreshed successfully for: ${freshProfile.name}',
        );

        // Also refresh the subjects data
        _fetchInitialData(freshProfile);
      }
    } catch (e) {
      print('🔄 [DoctorProfile] Error refreshing profile data: $e');
    }
  }

  void _onMainCategoryChanged(String category) {
    setState(() {
      _currentCategory = category;
      // Clear current subject when switching away from subjects
      if (category != 'المواد') {
        _currentSubject = null;
      }
    });
  }

  Future<void> _showAddLectureDialog() async {
    final userProfile = _displayedProfile;
    if (userProfile == null) return;

    // Check if we have a current subject selected
    if (_currentSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار مادة أولاً'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AddLectureDialog(subjectName: _currentSubject!.name),
    );

    if (result != null && result.trim().isNotEmpty) {
      try {
        final newLecture = Lecture(
          id: '',
          title: result.trim(),
          subjectId: _currentSubject!.id,
          doctorId: userProfile.id,
          categoryName: 'المحاضرات',
          links: [],
          createdAt: DateTime.now(),
        );

        // Add lecture using service directly
        final service = DoctorSubjectService();
        await service.addLecture(newLecture);

        // Refresh lectures in UI
        _refreshLecturesCallback?.call();

        // Show success message with subject name
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'تم إضافة المحاضرة إلى مادة "${_currentSubject!.name}" بنجاح',
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  Responsive.space(context, size: Space.large),
                ),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل في إضافة المحاضرة: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  Responsive.space(context, size: Space.large),
                ),
              ),
            ),
          );
        }
      }
    }
  }

  List<Widget> _getCategoryContentSlivers(BuildContext context) {
    final loggedInUser = ref.watch(userProfileProvider).userProfile;
    final isOwnProfile = loggedInUser?.id == _displayedProfile?.id;
    final userProfile = _displayedProfile;

    if (userProfile == null) {
      return [const SliverToBoxAdapter(child: SizedBox.shrink())];
    }

    switch (_currentCategory) {
      case 'المواد':
        return [
          SliverToBoxAdapter(
            child: SubjectsSection(
              userProfile: userProfile,
              loggedInUser: loggedInUser,
              targetSubject: _targetSubject,
              onRefreshCallbackSet: (callback) {
                _refreshLecturesCallback = callback;
              },
              onCurrentSubjectChanged: (subject) {
                setState(() {
                  _currentSubject = subject;
                });
                // Clear target subject after it's been used, but only if we have a subject
                // and the target subject matches the current subject
                if (subject != null &&
                    _targetSubject != null &&
                    subject.id == _targetSubject!.id) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _targetSubject = null;
                      });
                    }
                  });
                }
              },
            ),
          ),
        ];
      case 'عن الدكتور':
        return [
          SliverToBoxAdapter(
            child: AboutSection(
              userProfile: userProfile,
              isOwnProfile: isOwnProfile,
              onProfileUpdated: (updatedProfile) {
                setState(() {
                  _displayedProfile = updatedProfile;
                });
              },
            ),
          ),
        ];
      default:
        return [
          const SliverFillRemaining(
            child: Center(child: Text('لا يوجد محتوى متاح حالياً')),
          ),
        ];
    }
  }

  bool _shouldShowEditIcon() {
    final loggedInUser = ref.watch(userProfileProvider).loggedInUserProfile;
    final isAdminOrSuperAdmin =
        loggedInUser?.role == 'Admin' || loggedInUser?.role == 'Super Admin';
    final isViewingOtherUser = loggedInUser?.id != _displayedProfile?.id;
    final isProfessorOrMiniProfessor =
        _displayedProfile?.role == 'Professor' ||
        _displayedProfile?.role == 'miniProfessor';

    return isAdminOrSuperAdmin &&
        isViewingOtherUser &&
        isProfessorOrMiniProfessor;
  }

  bool _shouldShowAddLectureButton() {
    final loggedInUser = ref.watch(userProfileProvider).userProfile;

    if (loggedInUser == null) return false;

    // Only show if user can add lectures and we have a current subject selected
    return loggedInUser.role != 'Student' &&
        _currentCategory == 'المواد' &&
        _currentSubject != null;
  }

  Future<void> _editTeachingSubjects() async {
    final profile = _displayedProfile;
    if (profile == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => SubjectSelectionScreenWithProviders(
              previouslySelectedIds: profile.teachingSubjects,
              targetUserId: profile.id,
              targetUserRole: profile.role,
            ),
      ),
    );

    if (result == true && mounted) {
      final updatedProfile = await ref
          .read(userProfileProvider.notifier)
          .getUserProfileById(profile.id);
      if (updatedProfile != null) {
        setState(() {
          _displayedProfile = updatedProfile;
        });
        _fetchInitialData(updatedProfile);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديث المواد المدرسية بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _onBackPressed() {
    // Restore logged-in user profile when navigating back
    ref.read(userProfileProvider.notifier).restoreLoggedInUserProfile();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = _displayedProfile;
    final loggedInUser = ref.watch(userProfileProvider).userProfile;
    final isOwnProfile = loggedInUser?.id == userProfile?.id;

    if (userProfile == null) {
      return NoInternetMessage(
        child: Scaffold(
          backgroundColor: Colors.white,
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) {
          // Only restore profile when actually navigating back
          print(
            'Navigating back from doctor profile, restoring logged-in user profile',
          );
          ref.read(userProfileProvider.notifier).restoreLoggedInUserProfile();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        floatingActionButton:
            _shouldShowAddLectureButton()
                ? FloatingActionButton(
                  onPressed: _showAddLectureDialog,
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.add),
                )
                : null,
        body: SafeArea(
          bottom: false,
          child: Padding(
            padding: Responsive.paddingHorizontal(context),
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: Responsive.space(context, size: Space.small),
                  ),
                ),
                SliverToBoxAdapter(
                  child: DoctorCategories(
                    onCategoryChanged: _onMainCategoryChanged,
                    showBackButton: true,
                    showEditButton: _shouldShowEditIcon(),
                    showMenuButton: isOwnProfile,
                    onBackPressed: _onBackPressed,
                    onEditPressed: _editTeachingSubjects,
                    onMenuPressed: () => profile_options(context, ref),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: Divider(indent: 4, endIndent: 1),
                ),
                ..._getCategoryContentSlivers(context),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
