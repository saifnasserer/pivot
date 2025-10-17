import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/models/subject_model.dart';
import 'package:pivot/features/subjects/providers/subject_provider.dart';
import 'package:pivot/features/user/providers/user_profile_provider.dart';
import 'package:pivot/features/administration/providers/sections_provider.dart';
import 'package:pivot/services/offline_service.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/features/profile/screens/profile_widgets/Profile_options.dart';
import 'package:pivot/features/subjects/screens/screens.dart';
import 'package:pivot/widgets/offline_banner.dart';
import '../add_edit_section_screen.dart';
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

      // IMPORTANT: Set this profile as the viewed profile in the provider
      // This ensures other components (like sections_tab) know which profile is being viewed
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && profileToShow != null) {
          // Load the profile in the provider (creates separate instance)
          ref
              .read(userProfileProvider.notifier)
              .loadUserProfile(profileToShow.id);
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
        // TODO: Migrate SubjectProvider to Riverpod
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
          SliverFillRemaining(
            child: AssistantSubjectsSection(
              userProfile: userProfile,
              loggedInUser: loggedInUser,
              targetSubject: _targetSubject,
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
    final subjectProvider = ref.read(SubjectProviderProvider);
    final subjects = subjectProvider.filteredSubjects;

    await showAddSectionScreen(
      context: context,
      subjects: subjects,
      autoSelectedSubjectId: _currentSubject!.id,
      targetAssistantId: userProfile.id,
    );

    // The screen handles success messages internally, no need to show here
  }

  void _onBackPressed() async {
    // When navigating back, reload the logged-in user's sections
    // This ensures sections_tab shows the correct data for the logged-in user
    final loggedInUser = ref.read(userProfileProvider).loggedInUserProfile;
    if (loggedInUser != null) {
      // Reload sections for the logged-in user
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
            // Reload sections for the logged-in user first
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
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Offline banner
              Consumer(
                builder: (context, ref, _) {
                  final connectivityStatus = ref.watch(
                    connectivityStatusProvider,
                  );
                  return connectivityStatus.when(
                    data:
                        (isOnline) =>
                            isOnline
                                ? const SizedBox.shrink()
                                : const OfflineBanner(),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  );
                },
              ),
              // Main content
              Expanded(
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
                      // Additional bottom padding
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height:
                              _shouldShowAddSectionButton()
                                  ? 100.0 // Extra space for FAB
                                  : 40.0, // Normal bottom padding
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
