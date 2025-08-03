import 'package:flutter/material.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/models/subject_model.dart';
import 'package:pivot/providers/section_provider.dart';
import 'package:pivot/providers/subject_provider.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/section3/profile_widgets/Profile_options.dart';
import 'package:pivot/screens/section3/subject_selection_screen.dart';
import 'package:pivot/screens/section4/doctor_details.dart';
import 'package:pivot/screens/models/section_card.dart';
import 'package:provider/provider.dart';
import 'add_edit_section_dialog.dart';
import 'assistant_categories.dart';

class AssistantProfile extends StatefulWidget {
  final bool isAdmin;

  const AssistantProfile({super.key, this.isAdmin = false});

  @override
  State<AssistantProfile> createState() => _AssistantProfileState();
}

class _AssistantProfileState extends State<AssistantProfile>
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
        sectionProvider.fetchSectionsForUserSubjects(
          _displayedProfile!.teachingSubjects,
        );
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

  Widget _buildSubjectContent(
    Subject subject,
    SectionProvider sectionProvider,
    UserProfile? loggedInUser,
  ) {
    final sectionsForSubject =
        sectionProvider.sections
            .where((s) => s.subjectId == subject.id)
            .toList();

    if (sectionProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (sectionsForSubject.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(
            Responsive.space(context, size: Space.medium),
          ),
          child: Text(
            'لا توجد عناصر في هذه المادة',
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.medium),
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, size: Space.small),
        vertical: Responsive.space(context, size: Space.small),
      ),
      itemCount: sectionsForSubject.length,
      itemBuilder:
          (context, index) => SectionCard(
            section: sectionsForSubject[index],
            subjectName: subject.name,
            isCurrentUserSection:
                false, // We'll handle this differently if needed
          ),
    );
  }

  List<Widget> _getCategoryContentSlivers(BuildContext context) {
    final subjectProvider = context.watch<SubjectProvider>();
    final sectionProvider = context.watch<SectionProvider>();
    final loggedInUser = context.watch<UserProfileProvider>().userProfile;
    final isOwnProfile = loggedInUser?.id == _displayedProfile?.id;

    if (subjectProvider.isLoading || sectionProvider.isLoading) {
      return [
        const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (loggedInUser == null) {
      return [
        const SliverFillRemaining(
          child: Center(child: Text('Authentication error: User not found.')),
        ),
      ];
    }

    final subjects = _localFilteredSubjects;
    if (subjects.isEmpty && _currentCategory == 'المواد') {
      return [
        const SliverFillRemaining(
          child: Center(child: Text('لا يوجد مواد متاحة حالياً')),
        ),
      ];
    }

    if (_selectedSubjectIndex >= subjects.length) {
      _selectedSubjectIndex = 0;
    }

    // final selectedSubject =
    //     subjects.isNotEmpty ? subjects[_selectedSubjectIndex] : null;

    switch (_currentCategory) {
      case 'المواد':
        if (subjects.isEmpty) {
          return [
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('لا توجد مواد متاحة حالياً')),
            ),
          ];
        }

        return [
          // Subjects as tabs using TabBar style
          SliverToBoxAdapter(
            child: Column(
              children: [
                // TabBar for subjects
                if (subjects.isNotEmpty) ...[
                  Builder(
                    builder: (context) {
                      // Get properly initialized TabController
                      final tabController = _getSubjectTabController(subjects);

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(
                            Responsive.space(context, size: Space.large),
                          ),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        child: TabBar(
                          controller: tabController,
                          isScrollable: true,
                          indicator: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              Responsive.space(context, size: Space.large),
                            ),
                            color: Colors.black,
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.black,
                          labelStyle: TextStyle(
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.medium,
                            ),
                            fontWeight: FontWeight.w600,
                            fontFamily: 'NotoSansArabic',
                          ),
                          unselectedLabelStyle: TextStyle(
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.medium,
                            ),
                            fontWeight: FontWeight.w500,
                            fontFamily: 'NotoSansArabic',
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: Responsive.space(
                              context,
                              size: Space.medium,
                            ),
                          ),
                          tabs:
                              subjects
                                  .map((subject) => Tab(text: subject.name))
                                  .toList(),
                        ),
                      );
                    },
                  ),
                  // TabBarView for subject content
                  Builder(
                    builder: (context) {
                      // Get properly initialized TabController
                      final tabController = _getSubjectTabController(subjects);
                      final screenHeight = MediaQuery.of(context).size.height;
                      final availableHeight =
                          screenHeight * 0.5; // Use 50% of screen height

                      return Container(
                        height: availableHeight,
                        child: TabBarView(
                          controller: tabController,
                          children:
                              subjects.map((subject) {
                                return _buildSubjectContent(
                                  subject,
                                  sectionProvider,
                                  loggedInUser,
                                );
                              }).toList(),
                        ),
                      );
                    },
                  ),
                ] else
                  Padding(
                    padding: EdgeInsets.all(
                      Responsive.space(context, size: Space.medium),
                    ),
                    child: Text(
                      'لا توجد مواد متاحة',
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.medium,
                        ),
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: Divider(indent: 4, endIndent: 1)),
        ];
      case 'عن المعيد':
        return [
          // Add DoctorDetails at the top of the about tab
          SliverToBoxAdapter(
            child: Container(
              key: _profileDetailsKey,
              child: DoctorDetails(userProfile: _displayedProfile!),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: Responsive.space(context, size: Space.large),
            ),
          ),
          // Enhanced About Me section
          SliverToBoxAdapter(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: _buildEnhancedAboutSection(
                context,
                _displayedProfile!,
                isOwnProfile,
              ),
            ),
          ),
        ];
      default:
        return [
          const SliverFillRemaining(
            child: Center(child: Text('Unknown Category')),
          ),
        ];
    }
  }

  Widget _buildEnhancedAboutSection(
    BuildContext context,
    UserProfile userProfile,
    bool canEdit,
  ) {
    return Padding(
      padding: Responsive.padding(context, size: Space.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // About Me Section
          _buildAboutMeSection(context, userProfile, canEdit),
        ],
      ),
    );
  }

  Widget _buildAboutMeSection(
    BuildContext context,
    UserProfile userProfile,
    bool canEdit,
  ) {
    return Container(
      padding: Responsive.padding(context, size: Space.medium),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.large),
        ),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'نبذة عن المعيد',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.medium),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (canEdit)
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.black54),
                  onPressed: () {
                    setState(() {
                      _isEditingAboutMe = true;
                    });
                  },
                ),
            ],
          ),
          SizedBox(height: Responsive.space(context, size: Space.small)),
          _isEditingAboutMe
              ? _buildAboutMeEditor(context, userProfile)
              : Text(
                userProfile.aboutMe.isNotEmpty
                    ? userProfile.aboutMe
                    : 'لم يتم تقديمه بعد.',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.small),
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildAboutMeEditor(BuildContext context, UserProfile userProfile) {
    final userProfileProvider = Provider.of<UserProfileProvider>(
      context,
      listen: false,
    );
    return Column(
      children: [
        TextField(
          controller: _aboutMeController,
          maxLines: 5,
          textDirection: TextDirection.rtl,
          decoration: const InputDecoration(
            hintText: '...اكتب عن نفسك',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: Responsive.space(context, size: Space.medium)),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () {
                setState(() {
                  _isEditingAboutMe = false;
                  _aboutMeController.text = userProfile.aboutMe ?? '';
                });
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              child: const Text('حفظ', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                try {
                  await userProfileProvider.updateAboutMe(
                    userProfile.id,
                    _aboutMeController.text,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم الحفظ بنجاح'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    setState(() {
                      _displayedProfile = userProfile.copyWith(
                        aboutMe: _aboutMeController.text,
                      );
                      _isEditingAboutMe = false;
                    });
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('فشل: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ],
    );
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
                backgroundColor: Colors.black,
                onPressed: () {
                  final subjects = _localFilteredSubjects;
                  if (subjects.isNotEmpty &&
                      _selectedSubjectIndex < subjects.length) {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AddEditSectionDialog(
                          subjects: subjects,
                          initialSubjectId: subjects[_selectedSubjectIndex].id,
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
              ..._getCategoryContentSlivers(context),
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
