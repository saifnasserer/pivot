import 'package:flutter/material.dart';
import 'package:pivot/models/lecture_model.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/providers/doctor_subject_provider.dart';
import 'package:pivot/providers/subject_provider.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/section4/doctor/add_subject_link_dialog.dart';
import 'package:pivot/screens/section4/doctor/doctor_categories.dart';
import 'package:pivot/screens/section4/doctor_details.dart';
import 'package:pivot/screens/models/category_model.dart';
import 'package:pivot/screens/models/material_links_widget.dart';
import 'package:pivot/screens/section3/profile_widgets/Profile_options.dart';
import 'package:pivot/screens/section3/subject_selection_screen.dart';
import 'package:provider/provider.dart';
import 'package:pivot/widgets/no_internet_message.dart';

class DoctorProfile extends StatefulWidget {
  // = 'doctor';
  const DoctorProfile({super.key});

  @override
  State<DoctorProfile> createState() => _DoctorProfileState();
}

class _DoctorProfileState extends State<DoctorProfile> {
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
      _aboutMeController.text = _displayedProfile?.aboutMe ?? '';

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _fetchInitialData(profileToShow!);
        }
      });
    }
  }

  void _fetchInitialData(UserProfile userProfile) {
    if (!mounted) return;

    // Use a safer approach to access providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      try {
        final subjectProvider = Provider.of<SubjectProvider>(
          context,
          listen: false,
        );
        subjectProvider.fetchAndFilterSubjects(userProfile).then((_) {
          if (mounted) {
            try {
              final subjects = subjectProvider.filteredSubjects;
              if (subjects.isNotEmpty) {
                _onSubjectSelected(0, fetchLectures: true);
              }
            } catch (e) {
              // Provider might be disposed, ignore the error
              print('Provider access error in callback: $e');
            }
          }
        });
      } catch (e) {
        // Provider might be disposed, ignore the error
        print('Provider access error: $e');
      }
    });
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

  void _onSubjectSelected(int index, {bool fetchLectures = true}) {
    setState(() {
      _selectedSubjectIndex = index;
    });
    if (fetchLectures) {
      final subjects = context.read<SubjectProvider>().filteredSubjects;
      if (subjects.isNotEmpty && index < subjects.length) {
        final subjectId = subjects[index].id;
        final doctorId = _displayedProfile!.id;
        context.read<DoctorSubjectProvider>().fetchLecturesForSubject(
          doctorId,
          subjectId,
        );
      }
    }
  }

  Future<void> _showAddLectureDialog() async {
    final userProfile = _displayedProfile;
    final subjects = context.read<SubjectProvider>().filteredSubjects;
    if (userProfile == null) return;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AddSubjectLinkDialog(subjects: subjects),
    );

    if (result != null) {
      final newLecture = Lecture(
        id: '', // Firestore will generate
        title: result['title']!,
        subjectId: result['subjectId']!,
        doctorId: userProfile.id,
        categoryName: 'المحاضرات', // Or determine dynamically
        links: [],
      );
      await context.read<DoctorSubjectProvider>().addLecture(newLecture);
    }
  }

  List<Widget> _getCategoryContentSlivers(BuildContext context) {
    final loggedInUser = context.watch<UserProfileProvider>().userProfile;
    final isOwnProfile = loggedInUser?.id == _displayedProfile?.id;
    final userProfile = _displayedProfile;

    if (userProfile == null) {
      return [const SliverToBoxAdapter(child: SizedBox.shrink())];
    }

    final subjectProvider = context.watch<SubjectProvider>();
    final doctorSubjectProvider = context.watch<DoctorSubjectProvider>();

    switch (_currentCategory) {
      case 'المواد':
        final subjects = subjectProvider.filteredSubjects;

        if (subjectProvider.isLoading) {
          return [
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
          ];
        }

        if (subjects.isEmpty) {
          return [
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('لا توجد مواد متاحة حالياً')),
            ),
          ];
        }

        final lectures = doctorSubjectProvider.lectures;

        return [
          SliverToBoxAdapter(
            child: SizedBox(
              height: Responsive.space(context, size: Space.xlarge) * 1.4,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                reverse: true,
                itemCount: subjects.length,
                itemBuilder: (context, index) {
                  return CategoryButton(
                    selected: _selectedSubjectIndex == index,
                    title: subjects[index].name,
                    onSelected: () => _onSubjectSelected(index),
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: Divider(indent: 4, endIndent: 1)),
          if (doctorSubjectProvider.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (doctorSubjectProvider.error != null)
            SliverFillRemaining(
              child: Center(child: Text(doctorSubjectProvider.error!)),
            )
          else if (lectures.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: Responsive.padding(context, size: Space.medium),
                child: Center(child: Text('لا توجد عناصر في هذه المادة')),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => SubjectModel(
                  lecture: lectures[index],
                  canEdit:
                      loggedInUser?.role != 'Student' &&
                      loggedInUser?.role != 'miniProfessor',
                ),
                childCount: lectures.length,
              ),
            ),
        ];
      case 'عن الدكتور':
        return [
          SliverToBoxAdapter(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child:
                  _isEditingAboutMe
                      ? _buildAboutMeEditor(context, userProfile)
                      : _buildAboutMeDisplay(
                        context,
                        userProfile,
                        isOwnProfile,
                      ),
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

  Widget _buildAboutMeDisplay(
    BuildContext context,
    UserProfile userProfile,
    bool canEdit,
  ) {
    return Padding(
      padding: Responsive.padding(context, size: Space.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'عن الدكتور',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.medium),
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (canEdit)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    setState(() {
                      _isEditingAboutMe = true;
                    });
                  },
                ),
            ],
          ),
          SizedBox(height: Responsive.space(context, size: Space.small)),
          Text(
            userProfile.aboutMe.isNotEmpty
                ? userProfile.aboutMe
                : 'لم يتم تقديمه بعد.',
          ),
        ],
      ),
    );
  }

  Widget _buildAboutMeEditor(BuildContext context, UserProfile userProfile) {
    final userProfileProvider = context.read<UserProfileProvider>();
    final borderRadius = BorderRadius.circular(
      Responsive.space(context, size: Space.large),
    );
    final commonDecoration = InputDecoration(
      border: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: const BorderSide(color: Colors.teal, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 12.0,
      ),
      fillColor: Colors.grey.shade100,
      filled: true,
      labelStyle: TextStyle(color: Colors.grey.shade700),
      hintStyle: TextStyle(color: Colors.grey.shade500),
      alignLabelWithHint: true,
    );
    return Padding(
      padding: Responsive.padding(context, size: Space.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edit About Me',
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.medium),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: Responsive.space(context, size: Space.small)),
          Directionality(
            textDirection: TextDirection.rtl,
            child: TextField(
              controller: _aboutMeController,
              maxLines: 5,
              decoration: commonDecoration.copyWith(
                hintText: 'كلمنا عن نفسك !',
                labelText: 'عن الدكتور',
              ),
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(height: Responsive.space(context, size: Space.medium)),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                ),
                child: const Text('الغاء'),
                onPressed: () {
                  setState(() {
                    _isEditingAboutMe = false;
                    _aboutMeController.text = userProfile.aboutMe;
                  });
                },
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: borderRadius),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
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
                          content: Text('Successfully updated.'),
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
                          content: Text('Failed to update: $e'),
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
    final userProfile = _displayedProfile;
    final loggedInUser = context.watch<UserProfileProvider>().userProfile;
    final isOwnProfile = loggedInUser?.id == userProfile?.id;

    final appBar = AppBar(
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
    );

    if (userProfile == null) {
      return NoInternetMessage(
        child: Scaffold(
          appBar: appBar,
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return NoInternetMessage(
      child: Scaffold(
        backgroundColor: Colors.white,
        floatingActionButton:
            loggedInUser?.role != 'Student' &&
                    loggedInUser?.role != 'miniProfessor' &&
                    _currentCategory == '\u0627\u0644\u0645\u0648\u0627\u062f'
                ? FloatingActionButton(
                  onPressed: _showAddLectureDialog,
                  backgroundColor: Colors.black,
                  child: const Icon(Icons.add),
                )
                : null,
        appBar: appBar,
        body: Padding(
          padding: Responsive.paddingHorizontal(context),
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  key: _profileDetailsKey,
                  child: DoctorDetails(userProfile: userProfile),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: Responsive.space(context, size: Space.large),
                ),
              ),
              SliverToBoxAdapter(
                child: DoctorCategories(
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
}
