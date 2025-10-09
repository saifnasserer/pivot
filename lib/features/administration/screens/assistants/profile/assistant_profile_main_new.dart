import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/models/subject_model.dart';
import 'package:pivot/features/subjects/providers/subject_provider.dart';
import 'package:pivot/features/user/providers/user_profile_provider.dart';
import 'package:pivot/features/administration/providers/sections_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/features/profile/screens/profile_widgets/Profile_options.dart';
import 'package:pivot/features/subjects/screens/subject_selection_screen.dart';
import '../add_edit_section_dialog.dart';
import '../assistant_categories.dart';
import 'assistant_about_section.dart';
import 'assistant_subjects_section.dart';

class AssistantProfileMain extends ConsumerStatefulWidget {
  final bool isAdmin;

  const AssistantProfileMain({super.key, this.isAdmin = false});

  @override
  ConsumerState<AssistantProfileMain> createState() =>
      _AssistantProfileMainState();
}

class _AssistantProfileMainState extends ConsumerState<AssistantProfileMain>
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
      // Fallback: use loggedInUserProfile if no argument provided (viewing own profile)
      profileToShow = ref.watch(userProfileProvider).loggedInUserProfile;
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
    final loggedInUser = ref.read(userProfileProvider).loggedInUserProfile;
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
        // For now, using legacy provider access
        final subjectProvider = ref.read(SubjectProviderProvider);

        print(
          'Calling fetchAndFilterSubjects for assistant: ${profileToUse.name}',
        );
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

        // Load sections for this assistant (this sets currentUserId to assistant's ID)
        ref
            .read(sectionsProvider.notifier)
            .loadSectionsForAssistant(profileToUse.id);
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
    final loggedInUser = ref.watch(userProfileProvider).loggedInUserProfile;
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
    final loggedInUser = ref.watch(userProfileProvider).loggedInUserProfile;
    final isSuperAdmin = loggedInUser?.role == 'Super Admin';
    final isViewingOtherUser = loggedInUser?.id != _displayedProfile?.id;
    final isAssistant = _displayedProfile?.role == 'miniProfessor';

    return isSuperAdmin && isViewingOtherUser && isAssistant;
  }

  bool _shouldShowAddSectionButton() {
    final loggedInUser = ref.read(userProfileProvider).loggedInUserProfile;

    if (loggedInUser == null) return false;

    // Show if user can add sections and we're in the subjects category
    // Don't check for _currentSubject as it might not be initialized yet
    if (loggedInUser.role == 'Student' || _currentCategory != 'المواد') {
      return false;
    }

    // Check if we have any subjects available
    final subjectProvider = ref.read(SubjectProviderProvider);
    final subjects = subjectProvider.filteredSubjects;

    return subjects.isNotEmpty;
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

  Future<void> _showAddSectionDialog() async {
    final userProfile = _displayedProfile;
    if (userProfile == null) return;

    // Get current subject from the provider if _currentSubject is not set
    final subjectProvider = ref.read(SubjectProviderProvider);
    final subjects = subjectProvider.filteredSubjects;

    if (subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا توجد مواد متاحة'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Use _currentSubject if available, otherwise use the first subject
    final selectedSubject = _currentSubject ?? subjects.first;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (context) => AddEditSectionDialog(
            subjects: subjects,
            autoSelectedSubjectId: selectedSubject.id,
            targetAssistantId: userProfile.id,
          ),
    );

    if (result != null && mounted) {
      // Reload sections for the assistant
      await ref
          .read(sectionsProvider.notifier)
          .loadSectionsForAssistant(userProfile.id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إضافة السكاشن بنجاح'),
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

  void _onBackPressed() async {
    // When navigating back, reload the logged-in user's sections
    // This ensures sections_tab shows the correct data for the logged-in user
    final loggedInUser = ref.read(userProfileProvider).loggedInUserProfile;
    if (loggedInUser != null) {
      // Reload sections for the logged-in user (sets currentUserId back to logged-in user's ID)
      await ref
          .read(sectionsProvider.notifier)
          .loadSectionsForUser(loggedInUser.id, loggedInUser.enrolledSubjects);

      // Load the logged-in user's profile as the viewed profile
      await ref
          .read(userProfileProvider.notifier)
          .loadUserProfile(loggedInUser.id);
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = _displayedProfile;
    final loggedInUser = ref.watch(userProfileProvider).loggedInUserProfile;
    final isOwnProfile = loggedInUser?.id == userProfile?.id;

    if (userProfile == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          // When navigating back, reload the logged-in user's sections and profile
          print('Navigating back from assistant profile');
          final loggedInUser =
              ref.read(userProfileProvider).loggedInUserProfile;
          if (loggedInUser != null) {
            // Reload sections for the logged-in user first (sets currentUserId back)
            await ref
                .read(sectionsProvider.notifier)
                .loadSectionsForUser(
                  loggedInUser.id,
                  loggedInUser.enrolledSubjects,
                );

            // Then load the logged-in user's profile as the viewed profile
            await ref
                .read(userProfileProvider.notifier)
                .loadUserProfile(loggedInUser.id);
          }
          if (mounted) {
            Navigator.of(context).pop();
          }
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
