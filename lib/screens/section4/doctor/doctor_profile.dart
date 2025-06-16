import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/models/subject.dart';
import 'package:provider/provider.dart';
import 'package:pivot/models/lecture_model.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/providers/doctor_subject_provider.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/screens/section4/doctor/add_subject_link_dialog.dart';
import 'package:pivot/screens/section4/doctor/doctor_categories.dart';
import 'package:pivot/screens/section4/doctor/doctor_subjects.dart'
    show buildDoctorSubjectsSlivers;
import 'package:pivot/screens/section4/doctor_details.dart';
import 'package:pivot/screens/section3/profile_widgets/Profile_options.dart';

class DoctorProfile extends StatefulWidget {
  static const String id = 'doctor';
  const DoctorProfile({super.key});

  @override
  State<DoctorProfile> createState() => _DoctorProfileState();
}

class _DoctorProfileState extends State<DoctorProfile> {
  String _currentCategory = 'المواد';
  int _selectedSubjectIndex = 0;
  UserProfile? _previousUserProfile;

  // TODO: Replace with actual data from a provider or service
  final List<String> _subjectCategoryNames = [
    'Computer Science',
    'Mathematics',
    'Physics',
    'History',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userProfile = context.watch<UserProfileProvider>().userProfile;

    if (userProfile != null && userProfile != _previousUserProfile) {
      _previousUserProfile = userProfile;
      context.read<DoctorSubjectProvider>().fetchLecturesForDoctor(
        userProfile.id,
        _subjectCategoryNames,
      );
    }
  }

  void _onMainCategoryChanged(String category) {
    setState(() {
      _currentCategory = category;
    });
  }

  void _onSubjectCategorySelected(int index) {
    setState(() {
      _selectedSubjectIndex = index;
    });
    final userProfile = context.read<UserProfileProvider>().userProfile;
    if (userProfile != null) {
      final provider = context.read<DoctorSubjectProvider>();
      final category = _subjectCategoryNames[index];
      // Optionally trigger a fetch if data for this category isn't loaded
      if (provider.lecturesByCategory[category] == null) {
        provider.fetchLecturesForDoctor(userProfile.id, [category]);
      }
    }
  }

  Future<void> _showAddLinkDialog() async {
    if (_subjectCategoryNames.isEmpty) return;

    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => const AddSubjectLinkDialog(),
    );

    final userProfile = context.read<UserProfileProvider>().userProfile;
    if (newTitle != null && newTitle.isNotEmpty && userProfile != null) {
      final category = _subjectCategoryNames[_selectedSubjectIndex];
      final newLecture = Lecture(
        id: '', // Firestore will generate this
        title: newTitle,
        doctorId: userProfile.id,
        categoryName: category,
      );
      await context.read<DoctorSubjectProvider>().addLecture(newLecture);
    }
  }

  void _deleteLecture(Lecture lecture) {
    context.read<DoctorSubjectProvider>().deleteLecture(lecture.id);
  }

  List<Widget> _getCategoryContentSlivers() {
    final provider = context.watch<DoctorSubjectProvider>();
    final userProfile = context.watch<UserProfileProvider>().userProfile;

    if (provider.isLoading) {
      return [
        const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (provider.error != null) {
      return [SliverFillRemaining(child: Center(child: Text(provider.error!)))];
    }

    if (userProfile == null) {
      return [
        const SliverFillRemaining(
          child: Center(child: Text('User not found.')),
        ),
      ];
    }

    // Convert Lecture models to SubjectModel widgets
    final subjectsData = provider.lecturesByCategory.map((category, lectures) {
      return MapEntry(
        category,
        lectures
            .map(
              (lecture) => SubjectModel(
                lecture: lecture, // Pass the whole lecture object
              ),
            )
            .toList(),
      );
    });

    switch (_currentCategory) {
      case 'المواد':
        return buildDoctorSubjectsSlivers(
          context: context,
          subjectCategories: _subjectCategoryNames,
          selectedSubjectIndex: _selectedSubjectIndex,
          subjectsData: subjectsData,
          onCategorySelected: _onSubjectCategorySelected,
          onLectureDeleted: _deleteLecture,
        );
      case 'عن الدكتور':
        return [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                userProfile.aboutMe.isEmpty
                    ? 'لا يوجد معلومات متاحة.'
                    : userProfile.aboutMe,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
          ),
        ];
      default:
        return [
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('مفيش تفاصيل')),
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = context.watch<UserProfileProvider>().userProfile;

    final appBar = AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (userProfile != null)
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
      floatingActionButton:
          _currentCategory == 'المواد'
              ? FloatingActionButton(
                backgroundColor: Colors.black,
                onPressed: _showAddLinkDialog,
                tooltip: 'إضافة رابط جديد للمادة',
                child: const Icon(Icons.add, color: Colors.white),
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
              SliverToBoxAdapter(
                child: SizedBox(
                  height: Responsive.space(context, size: Space.large),
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
