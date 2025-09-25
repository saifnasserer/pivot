import 'package:flutter/material.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/models/subject_model.dart';
import 'package:pivot/providers/subject_provider.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/section3/profile_widgets/Profile_options.dart';
import 'package:pivot/screens/section3/subject_selection_screen.dart';
import 'package:provider/provider.dart';
import '../add_edit_section_dialog.dart';
import '../assistant_categories.dart';
import 'assistant_about_section.dart';
import 'assistant_subjects_section.dart';

class AssistantProfileMain extends StatefulWidget {
  final bool isAdmin;

  const AssistantProfileMain({super.key, this.isAdmin = false});

  @override
  State<AssistantProfileMain> createState() => _AssistantProfileMainState();
}

class _AssistantProfileMainState extends State<AssistantProfileMain>
    with TickerProviderStateMixin {
  UserProfile? _displayedProfile;
  String? _previousProfileId;
  late ScrollController _scrollController;
  String _currentCategory = 'المواد';
  Subject? _currentSubject;
  Subject?
  _targetSubject; // Subject to navigate to when coming from subject details

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
    Subject? targetSubject;

    // Handle different argument types
    if (argument is UserProfile) {
      profileToShow = argument;
    } else if (argument is Map<String, dynamic>) {
      profileToShow = argument['instructor'] as UserProfile?;
      targetSubject = argument['subject'] as Subject?;
    } else {
      profileToShow = context.watch<UserProfileProvider>().userProfile;
    }

    if (profileToShow != null && profileToShow.id != _previousProfileId) {
      _displayedProfile = profileToShow;
      _previousProfileId = profileToShow.id;

      // Store target subject for later use
      if (targetSubject != null) {
        _targetSubject = targetSubject;
      }

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
      '_fetchInitialData called for assistant: ${userProfile.name} (${userProfile.role})',
    );
    print('Teaching subjects: ${userProfile.teachingSubjects}');

    // Check if this is the logged-in user's own profile
    final loggedInUser = context.read<UserProfileProvider>().userProfile;
    final isOwnProfile = loggedInUser?.id == userProfile.id;
    print('Is own profile: $isOwnProfile');

    // Use logged-in user's profile data when viewing own profile to ensure correct teaching subjects
    final profileToUse = isOwnProfile ? loggedInUser! : userProfile;
    print(
      'Using profile: ${profileToUse.name} with teaching subjects: ${profileToUse.teachingSubjects}',
    );

    // Fetch and filter subjects
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      try {
        final subjectProvider = Provider.of<SubjectProvider>(
          context,
          listen: false,
        );

        print(
          'Calling fetchAndFilterSubjects for assistant: ${profileToUse.name}',
        );
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
            child: AssistantSubjectsSection(
              userProfile: userProfile,
              loggedInUser: loggedInUser,
              targetSubject: _targetSubject,
              onCurrentSubjectChanged: (subject) {
                setState(() {
                  _currentSubject = subject;
                  // Clear target subject after it's been used
                  if (_targetSubject != null) {
                    _targetSubject = null;
                  }
                });
              },
            ),
          ),
        ];
      case 'عن المعيد':
        return [
          SliverToBoxAdapter(
            child: AssistantAboutSection(
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
    final isAssistant = _displayedProfile?.role == 'miniProfessor';

    return isSuperAdmin && isViewingOtherUser && isAssistant;
  }

  bool _shouldShowAddSectionButton() {
    final loggedInUser = context.read<UserProfileProvider>().userProfile;

    if (loggedInUser == null) return false;

    // Only show if user can add sections and we have a current subject selected
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

  Future<void> _showAddSectionDialog() async {
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

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (context) => AddEditSectionDialog(
            subjects: [_currentSubject!],
            autoSelectedSubjectId: _currentSubject!.id,
            targetAssistantId: userProfile.id,
          ),
    );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم إضافة السكاشن إلى مادة "${_currentSubject!.name}" بنجاح',
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
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) {
          // Only restore profile when actually navigating back
          print(
            'Navigating back from assistant profile, restoring logged-in user profile',
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
            _shouldShowAddSectionButton()
                ? FloatingActionButton(
                  heroTag: 'assistant_profile_fab',
                  onPressed: _showAddSectionDialog,
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
                  child: AssistantCategories(
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
