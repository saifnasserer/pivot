import 'package:flutter/material.dart';
import 'package:pivot/models/lecture_model.dart';
import 'package:pivot/models/subject_model.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/providers/doctor_subject_provider.dart';
import 'package:pivot/providers/subject_provider.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/section4/doctor/add_lecture_dialog.dart';
import 'package:pivot/screens/section4/doctor/doctor_categories.dart';
import 'package:pivot/screens/section4/doctor/profile/about_section.dart';
import 'package:pivot/screens/section4/doctor/profile/subjects_section.dart';
import 'package:pivot/screens/section3/profile_widgets/Profile_options.dart';
import 'package:pivot/screens/section3/subject_selection_screen.dart';
import 'package:provider/provider.dart';
import 'package:pivot/widgets/no_internet_message.dart';

class DoctorProfile extends StatefulWidget {
  const DoctorProfile({super.key});

  @override
  State<DoctorProfile> createState() => _DoctorProfileState();
}

class _DoctorProfileState extends State<DoctorProfile>
    with TickerProviderStateMixin {
  UserProfile? _displayedProfile;
  String? _previousProfileId;
  late ScrollController _scrollController;
  String _currentCategory = 'المواد';
  Subject? _currentSubject;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final argument = ModalRoute.of(context)?.settings.arguments;
    UserProfile? profileToShow;

    if (argument is UserProfile) {
      profileToShow = argument;
    } else {
      profileToShow = context.watch<UserProfileProvider>().userProfile;
    }

    if (profileToShow != null && profileToShow.id != _previousProfileId) {
      _displayedProfile = profileToShow;
      _previousProfileId = profileToShow.id;

      // Ensure we have the correct profile data before fetching
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && profileToShow != null) {
          _fetchInitialData(profileToShow);
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
    final loggedInUser = context.read<UserProfileProvider>().userProfile;
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
        final subjectProvider = Provider.of<SubjectProvider>(
          context,
          listen: false,
        );

        print(
          'Calling fetchAndFilterSubjects for profile: ${profileToUse.name}',
        );
        // Just fetch and filter subjects - no lecture loading here
        subjectProvider
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

        await context.read<DoctorSubjectProvider>().addLecture(newLecture);

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
    final loggedInUser = context.watch<UserProfileProvider>().userProfile;
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
              onCurrentSubjectChanged: (subject) {
                setState(() {
                  _currentSubject = subject;
                });
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
    final loggedInUser =
        context.watch<UserProfileProvider>().loggedInUserProfile;
    final isSuperAdmin = loggedInUser?.role == 'Super Admin';
    final isViewingOtherUser = loggedInUser?.id != _displayedProfile?.id;
    final isProfessorOrMiniProfessor =
        _displayedProfile?.role == 'Professor' ||
        _displayedProfile?.role == 'miniProfessor';

    return isSuperAdmin && isViewingOtherUser && isProfessorOrMiniProfessor;
  }

  bool _shouldShowAddLectureButton() {
    final loggedInUser = context.read<UserProfileProvider>().userProfile;

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
            (context) => SubjectSelectionScreen(
              previouslySelectedIds: profile.teachingSubjects,
              targetUserId: profile.id,
              targetUserRole: profile.role,
            ),
      ),
    );

    if (result == true && mounted) {
      final userProfileProvider = Provider.of<UserProfileProvider>(
        context,
        listen: false,
      );

      final updatedProfile = await userProfileProvider.getUserProfileById(
        profile.id,
      );
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
    final userProfileProvider = Provider.of<UserProfileProvider>(
      context,
      listen: false,
    );
    userProfileProvider.restoreLoggedInUserProfile();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = _displayedProfile;
    final loggedInUser = context.watch<UserProfileProvider>().userProfile;
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
          final userProfileProvider = Provider.of<UserProfileProvider>(
            context,
            listen: false,
          );
          userProfileProvider.restoreLoggedInUserProfile();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        floatingActionButton:
            _shouldShowAddLectureButton()
                ? FloatingActionButton(
                  heroTag: 'doctor_profile_fab',
                  onPressed: _showAddLectureDialog,
                  backgroundColor: Colors.black,
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
                    onMenuPressed: () => profile_options(context),
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
