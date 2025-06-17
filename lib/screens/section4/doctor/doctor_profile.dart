import 'package:flutter/material.dart';
import 'package:pivot/models/lecture_model.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/providers/doctor_subject_provider.dart';
import 'package:pivot/providers/subject_provider.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/models/category_model.dart';
import 'package:pivot/screens/models/material_links_widget.dart';
import 'package:pivot/screens/section3/profile_widgets/Profile_options.dart';
import 'package:pivot/screens/section4/doctor/add_subject_link_dialog.dart';
import 'package:pivot/screens/section4/doctor/doctor_categories.dart';
import 'package:pivot/screens/section4/doctor_details.dart';
import 'package:provider/provider.dart';

class DoctorProfile extends StatefulWidget {
  static const String id = 'doctor';
  const DoctorProfile({super.key});

  @override
  State<DoctorProfile> createState() => _DoctorProfileState();
}

class _DoctorProfileState extends State<DoctorProfile> {
  String _currentCategory = 'المواد';
  int _selectedSubjectIndex = 0;
  UserProfile? _displayedProfile;
  String? _previousProfileId;
  bool _isEditingAboutMe = false;
  late TextEditingController _aboutMeController;

  bool get _canEdit {
    final currentUser = context.read<UserProfileProvider>().userProfile;
    if (currentUser == null) {
      return false;
    }
    final role = currentUser.role;
    const allowedRoles = ['Super Admin', 'Admin', 'Professor'];
    return allowedRoles.contains(role);
  }

  @override
  void initState() {
    super.initState();
    _aboutMeController = TextEditingController();
  }

  @override
  void dispose() {
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
    context.read<SubjectProvider>().fetchAndFilterSubjects(userProfile).then((_) {
      if (mounted) {
        final subjects = context.read<SubjectProvider>().filteredSubjects;
        if (subjects.isNotEmpty) {
          _onSubjectSelected(0, fetchLectures: true);
        }
      }
    });
  }

  void _onMainCategoryChanged(String category) {
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
        context
            .read<DoctorSubjectProvider>()
            .fetchLecturesForSubject(doctorId, subjectId);
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

  List<Widget> _getCategoryContentSlivers() {
    final subjectProvider = context.watch<SubjectProvider>();
    final doctorSubjectProvider = context.watch<DoctorSubjectProvider>();
    final userProfile = _displayedProfile;

    if (userProfile == null) {
      return [const SliverToBoxAdapter(child: SizedBox.shrink())];
    }

    switch (_currentCategory) {
      case 'المواد':
        final subjects = subjectProvider.filteredSubjects;

        if (subjectProvider.isLoading) {
          return [const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))];
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
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (doctorSubjectProvider.error != null)
            SliverFillRemaining(child: Center(child: Text(doctorSubjectProvider.error!)))
          else if (lectures.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: Text('لا توجد عناصر في هذه المادة')),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    SubjectModel(lecture: lectures[index], canEdit: _canEdit),
                childCount: lectures.length,
              ),
            ),
        ];
      case 'حول':
        return [
          SliverToBoxAdapter(
            child: _isEditingAboutMe
                ? _buildAboutMeEditor(context, userProfile)
                : _buildAboutMeDisplay(context, userProfile),
          ),
        ];
      default:
        return [
          const SliverFillRemaining(
            child: Center(child: Text('Content not available.')),
          )
        ];
    }
  }

  Widget _buildAboutMeDisplay(
    BuildContext context,
    UserProfile userProfile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('About Me', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (_canEdit)
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
        const SizedBox(height: 8),
        Text(userProfile.aboutMe.isNotEmpty ? userProfile.aboutMe : 'Not provided yet.'),
      ],
    );
  }

  Widget _buildAboutMeEditor(BuildContext context, UserProfile userProfile) {
    final userProfileProvider = context.read<UserProfileProvider>();
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Edit About Me',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _aboutMeController,
            maxLines: 5,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Tell us about yourself...',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  setState(() {
                    _isEditingAboutMe = false;
                    _aboutMeController.text = userProfile.aboutMe;
                  });
                },
              ),
              ElevatedButton(
                child: const Text('Save'),
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

    final appBar = AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert_sharp, color: Colors.black),
          onPressed: () => profile_options(context),
        ),
      ],
    );

    if (userProfile == null) {
      return Scaffold(
        appBar: appBar,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: _canEdit && _currentCategory == 'المواد'
          ? FloatingActionButton(
              onPressed: _showAddLectureDialog,
              child: const Icon(Icons.add),
            )
          : null,
      appBar: appBar,
      body: SafeArea(
        child: Padding(
          padding: Responsive.paddingHorizontal(context),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: Responsive.space(context, size: Space.xlarge),
                ),
              ),
              SliverToBoxAdapter(
                child: DoctorDetails(userProfile: userProfile),
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
              ..._getCategoryContentSlivers(),
            ],
          ),
        ),
      ),
    );
  }
}
