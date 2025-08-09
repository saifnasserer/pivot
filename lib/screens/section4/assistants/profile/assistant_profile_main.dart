import 'package:flutter/material.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/models/subject_model.dart';
import 'package:pivot/providers/section_provider.dart';
import 'package:pivot/providers/subject_provider.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/section3/profile_widgets/Profile_options.dart';
import 'package:pivot/screens/section3/subject_selection_screen.dart';
import 'package:provider/provider.dart';
import '../add_edit_section_dialog.dart';
import '../assistant_categories.dart';
import 'assistant_profile_content.dart';

class AssistantProfileMain extends StatefulWidget {
  final bool isAdmin;

  const AssistantProfileMain({super.key, this.isAdmin = false});

  @override
  State<AssistantProfileMain> createState() => _AssistantProfileMainState();
}

class _AssistantProfileMainState extends State<AssistantProfileMain>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _profileDetailsKey = GlobalKey();
  String _currentCategory = 'المواد';
  int _selectedSubjectIndex = 0;
  UserProfile? _displayedProfile;
  String? _previousProfileId;
  final bool _isEditingAboutMe = false;
  late TextEditingController _aboutMeController;
  late TabController _subjectTabController;

  @override
  void initState() {
    super.initState();
    _aboutMeController = TextEditingController();
    _subjectTabController = TabController(length: 0, vsync: this);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _aboutMeController.dispose();
    _subjectTabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments = ModalRoute.of(context)?.settings.arguments;
    final userProfileFromProvider =
        Provider.of<UserProfileProvider>(context, listen: false).userProfile;

    UserProfile? newProfile;
    if (arguments != null && arguments is UserProfile) {
      newProfile = arguments;
    } else {
      newProfile = userProfileFromProvider;
    }

    if (newProfile?.id != _previousProfileId) {
      setState(() {
        _displayedProfile = newProfile;
        _previousProfileId = newProfile?.id;
        if (!_isEditingAboutMe) {
          _aboutMeController.text = _displayedProfile?.aboutMe ?? '';
        }
      });

      // Ensure we have the correct profile data before fetching
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && newProfile != null) {
          _fetchInitialData(newProfile);
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      try {
        final userProfileProvider = Provider.of<UserProfileProvider>(
          context,
          listen: false,
        );
        final subjectProvider = Provider.of<SubjectProvider>(
          context,
          listen: false,
        );
        final sectionProvider = Provider.of<SectionProvider>(
          context,
          listen: false,
        );

        print('Starting data fetch for assistant profile');
        // Fetch all users for admin functionality
        userProfileProvider
            .fetchAllUsers(forceAll: true)
            .then((_) {
              print('All users fetched, now fetching subjects');
              // Just fetch and filter subjects - let UI components handle their own state
              subjectProvider
                  .fetchAndFilterSubjects(profileToUse)
                  .then((_) {
                    print('Subjects fetched for ${profileToUse.name}');
                    print(
                      'Filtered subjects count: ${subjectProvider.filteredSubjects.length}',
                    );
                  })
                  .catchError((error) {
                    print('Error fetching subjects: $error');
                  });
            })
            .catchError((error) {
              print('Error fetching all users: $error');
            });

        // Fetch sections for this specific assistant
        sectionProvider
            .fetchSectionsForAssistant(profileToUse.id)
            .then((_) {
              print('Sections fetched for assistant ${profileToUse.id}');
            })
            .catchError((error) {
              print('Error fetching sections: $error');
            });
      } catch (e) {
        print('Provider access error: $e');
      }
    });
  }

  // Update TabController when subjects are loaded
  void _updateSubjectTabController(List<Subject> subjects) {
    if (_subjectTabController.length != subjects.length) {
      _subjectTabController.dispose();
      _subjectTabController = TabController(
        length: subjects.length,
        vsync: this,
        initialIndex: subjects.isNotEmpty ? subjects.length - 1 : 0,
      );
      _subjectTabController.addListener(() {
        if (_subjectTabController.indexIsChanging) {
          _onSubjectSelected(_subjectTabController.index);
        }
      });
    }
  }

  // Get properly initialized TabController for subjects
  TabController _getSubjectTabController(List<Subject> subjects) {
    if (_subjectTabController.length != subjects.length) {
      _subjectTabController.dispose();
      _subjectTabController = TabController(
        length: subjects.length,
        vsync: this,
        initialIndex: subjects.isNotEmpty ? subjects.length - 1 : 0,
      );
      _subjectTabController.addListener(() {
        if (_subjectTabController.indexIsChanging) {
          _onSubjectSelected(_subjectTabController.index);
        }
      });
    }
    return _subjectTabController;
  }

  void _onSubjectSelected(int index) {
    setState(() {
      _selectedSubjectIndex = index;
    });
  }

  // Check if Super Admin should see edit icon
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

  // Handle edit teaching subjects
  Future<void> _editTeachingSubjects() async {
    if (_displayedProfile == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => SubjectSelectionScreen(
              previouslySelectedIds: _displayedProfile!.teachingSubjects,
              targetUserId: _displayedProfile!.id,
              targetUserRole: _displayedProfile!.role,
            ),
      ),
    );

    if (result == true && mounted) {
      // Refresh the displayed profile data
      final userProfileProvider = Provider.of<UserProfileProvider>(
        context,
        listen: false,
      );

      // Fetch updated profile data
      final updatedProfile = await userProfileProvider.getUserProfileById(
        _displayedProfile!.id,
      );
      if (updatedProfile != null) {
        setState(() {
          _displayedProfile = updatedProfile;
        });
        _fetchInitialData(
          _displayedProfile!,
        ); // Re-fetch data for the updated profile
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديث المواد المدرسية بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _onMainCategoryChanged(String category) {
    setState(() {
      _currentCategory = category;
    });
  }

  void _showAddSectionDialog() {
    final subjectProvider = context.watch<SubjectProvider>();
    final subjects = subjectProvider.filteredSubjects;
    if (subjects.isNotEmpty && _subjectTabController.index < subjects.length) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AddEditSectionDialog(
            subjects: subjects,
            autoSelectedSubjectId: subjects[_subjectTabController.index].id,
            targetAssistantId: _displayedProfile?.id,
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء تحديد المادة أولاً')),
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
    final loggedInUser = context.watch<UserProfileProvider>().userProfile;
    final isOwnProfile = loggedInUser?.id == _displayedProfile?.id;
    final subjectProvider = context.watch<SubjectProvider>();
    final subjects = subjectProvider.filteredSubjects; // Use provider directly

    if (_displayedProfile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
        resizeToAvoidBottomInset: true,
        floatingActionButton:
            isOwnProfile
                ? FloatingActionButton(
                  heroTag: 'assistant_profile_fab',
                  onPressed: _showAddSectionDialog,
                  backgroundColor: Colors.black,
                  tooltip: 'إضافة سكشن جديد',
                  child: const Icon(Icons.add, color: Colors.white),
                )
                : null,
        body: SafeArea(
          child: Padding(
            padding: Responsive.paddingHorizontal(context),
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Add top padding for safe area
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
                ...AssistantProfileContent.getCategoryContentSlivers(
                  context,
                  _currentCategory,
                  _displayedProfile!,
                  subjects,
                  _selectedSubjectIndex,
                  _getSubjectTabController,
                  _onSubjectSelected,
                  isOwnProfile,
                  _isEditingAboutMe,
                  _aboutMeController,
                  _profileDetailsKey,
                  (updatedProfile) {
                    setState(() {
                      _displayedProfile = updatedProfile;
                    });
                  },
                ),
                // Add bottom padding for floating action button
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 80, // Space for floating action button
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
