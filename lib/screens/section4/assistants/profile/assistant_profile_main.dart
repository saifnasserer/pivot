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
  bool _isEditingAboutMe = false;
  late TextEditingController _aboutMeController;
  late TabController _subjectTabController;
  List<Subject> _localFilteredSubjects = [];

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

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && newProfile != null) {
          _fetchData();
        }
      });
    }
  }

  void _fetchData() {
    if (_displayedProfile == null || !mounted) return;

    // Use a safer approach to access providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      try {
        final subjectProvider = Provider.of<SubjectProvider>(
          context,
          listen: false,
        );
        final sectionProvider = Provider.of<SectionProvider>(
          context,
          listen: false,
        );
        final userProfileProvider = Provider.of<UserProfileProvider>(
          context,
          listen: false,
        );

        // Fetch all users for admin functionality
        userProfileProvider.fetchAllUsers(forceAll: true).then((_) {
          subjectProvider.fetchAndFilterSubjects(_displayedProfile!).then((_) {
            if (mounted) {
              try {
                final subjects = subjectProvider.filteredSubjects;
                setState(() {
                  _localFilteredSubjects = subjects;
                });

                if (subjects.isNotEmpty) {
                  _updateSubjectTabController(subjects);
                  _onSubjectSelected(0);
                }
              } catch (e) {
                print('Provider access error in callback: $e');
              }
            }
          });
        });
        // Fetch sections for this specific assistant
        sectionProvider.fetchSectionsForAssistant(_displayedProfile!.id);
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
        _fetchData();
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

  @override
  Widget build(BuildContext context) {
    final loggedInUser = context.watch<UserProfileProvider>().userProfile;
    final isOwnProfile = loggedInUser?.id == _displayedProfile?.id;

    if (_displayedProfile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      floatingActionButton:
          loggedInUser?.role != 'Student' &&
                  loggedInUser?.role != 'Professor' &&
                  _currentCategory == 'المواد'
              ? FloatingActionButton(
                heroTag: 'assistant_profile_fab',
                backgroundColor: Colors.black,
                onPressed: () {
                  final subjects = _localFilteredSubjects;
                  if (subjects.isNotEmpty &&
                      _subjectTabController.index < subjects.length) {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AddEditSectionDialog(
                          subjects: subjects,
                          autoSelectedSubjectId:
                              subjects[_subjectTabController.index].id,
                          targetAssistantId: _displayedProfile?.id,
                        );
                      },
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('الرجاء تحديد المادة أولاً'),
                      ),
                    );
                  }
                },
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
                  onBackPressed: () => Navigator.pop(context),
                  onEditPressed: _editTeachingSubjects,
                  onMenuPressed: () => profile_options(context),
                ),
              ),
              const SliverToBoxAdapter(child: Divider(indent: 4, endIndent: 1)),
              ...AssistantProfileContent.getCategoryContentSlivers(
                context,
                _currentCategory,
                _displayedProfile!,
                _localFilteredSubjects,
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
    );
  }
}
