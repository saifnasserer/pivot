import 'package:flutter/material.dart';
import 'package:pivot/models/section_model.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/providers/section_provider.dart';
import 'package:pivot/providers/subject_provider.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/section3/profile_widgets/Profile_options.dart';
import 'package:pivot/screens/section3/subject_selection_screen.dart';
import 'package:pivot/screens/section4/doctor_details.dart';
import 'package:provider/provider.dart';
import 'add_edit_section_dialog.dart';
import 'assistant_categories.dart';
import 'assistant_subjects.dart';

class AssistantProfile extends StatefulWidget {
  // = 'section';
  final bool isAdmin;

  const AssistantProfile({super.key, this.isAdmin = false});

  @override
  State<AssistantProfile> createState() => _AssistantProfileState();
}

class _AssistantProfileState extends State<AssistantProfile> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _profileDetailsKey = GlobalKey();
  String _currentCategory = 'المواد';
  int _selectedSubjectIndex = 0;
  UserProfile? _displayedProfile;
  String? _previousProfileId;
  bool _isEditingAboutMe = false;
  late TextEditingController _aboutMeController;

  @override
  void initState() {
    super.initState();
    _aboutMeController = TextEditingController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _aboutMeController.dispose();
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

        subjectProvider.fetchAndFilterSubjects(_displayedProfile!);
        sectionProvider.fetchSectionsForUserSubjects(
          _displayedProfile!.teachingSubjects,
        );
      } catch (e) {
        // Provider might be disposed, ignore the error
        print('Provider access error: $e');
      }
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
    Future.delayed(const Duration(milliseconds: 50), () {
      final context = _profileDetailsKey.currentContext;
      if (context != null) {
        final box = context.findRenderObject() as RenderBox;
        _scrollController.animateTo(
          box.size.height + Responsive.space(context, size: Space.large),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
    setState(() {
      _currentCategory = category;
    });
  }

  void _onSubjectCategorySelected(int index) {
    setState(() {
      _selectedSubjectIndex = index;
    });
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

    final subjects = subjectProvider.filteredSubjects;
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

    final selectedSubject =
        subjects.isNotEmpty ? subjects[_selectedSubjectIndex] : null;

    switch (_currentCategory) {
      case 'المواد':
        final sectionsForSelectedSubject =
            selectedSubject != null
                ? sectionProvider.sections
                    .where((s) => s.subjectId == selectedSubject.id)
                    .toList()
                : [];

        return buildAssistantSubjects(
          context: context,
          subjects: subjects,
          selectedSubjectIndex: _selectedSubjectIndex,
          sections: sectionsForSelectedSubject.cast<Section>(),
          onCategorySelected: _onSubjectCategorySelected,
          loggedInUser: loggedInUser,
        );
      case 'عن المعيد':
        return [
          _isEditingAboutMe
              ? _buildAboutMeEditor(context, _displayedProfile!)
              : _buildAboutMeDisplay(context, _displayedProfile, isOwnProfile),
        ];
      default:
        return [
          const SliverFillRemaining(
            child: Center(child: Text('Unknown Category')),
          ),
        ];
    }
  }

  Widget _buildAboutMeDisplay(
    BuildContext context,
    UserProfile? userProfile,
    bool canEdit,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.all(Responsive.space(context, size: Space.medium)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              userProfile?.aboutMe ?? 'لا يوجد معلومات متاحة.',
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (canEdit)
              Align(
                alignment: Alignment.bottomRight,
                child: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    setState(() {
                      _isEditingAboutMe = true;
                    });
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutMeEditor(BuildContext context, UserProfile userProfile) {
    final userProfileProvider = Provider.of<UserProfileProvider>(
      context,
      listen: false,
    );
    return SliverToBoxAdapter(
      child: Column(
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loggedInUser = context.watch<UserProfileProvider>().userProfile;
    final subjects = context.watch<SubjectProvider>().filteredSubjects;
    final isOwnProfile = loggedInUser?.id == _displayedProfile?.id;

    final selectedSubject =
        subjects.isNotEmpty && _selectedSubjectIndex < subjects.length
            ? subjects[_selectedSubjectIndex]
            : null;
    if (_displayedProfile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Show edit icon for Super Admin viewing Professor/miniProfessor
          if (_shouldShowEditIcon())
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.black),
              tooltip: 'تعديل المواد المدرسية',
              onPressed: _editTeachingSubjects,
            ),
          // Show three-dot menu only for own profile
          if (isOwnProfile)
            IconButton(
              icon: const Icon(Icons.more_vert_sharp, color: Colors.black),
              onPressed: () => profile_options(context),
            ),
        ],
      ),
      floatingActionButton:
          loggedInUser?.role != 'Student' &&
                  loggedInUser?.role != 'Professor' &&
                  _currentCategory == 'المواد'
              ? FloatingActionButton(
                backgroundColor: Colors.black,
                onPressed: () {
                  if (selectedSubject != null) {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AddEditSectionDialog(
                          subjects: subjects,
                          initialSubjectId: selectedSubject.id,
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: Responsive.paddingHorizontal(context),
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  key: _profileDetailsKey,
                  child: DoctorDetails(userProfile: _displayedProfile!),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: Responsive.space(context, size: Space.medium),
                ),
              ),
              SliverToBoxAdapter(
                child: AssistantCategories(
                  onCategoryChanged: _onMainCategoryChanged,
                ),
              ),
              const SliverToBoxAdapter(child: Divider(indent: 4, endIndent: 1)),
              ..._getCategoryContentSlivers(context),
            ],
          ),
        ),
      ),
    );
  }
}
