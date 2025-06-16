import 'package:flutter/material.dart';
import 'package:pivot/models/lecture_model.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/providers/doctor_subject_provider.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/responsive.dart';
import '../../models/material_links_widget.dart';
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
  UserProfile? _previousUserProfile;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userProfile = context.watch<UserProfileProvider>().userProfile;
    if (userProfile != null && userProfile != _previousUserProfile) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _fetchInitialData(userProfile);
        }
      });
      _previousUserProfile = userProfile;
    }
  }

  void _fetchInitialData(UserProfile userProfile) {
    final categories = ['المحاضرات', 'السكاشن']; // Example categories
    context.read<DoctorSubjectProvider>().fetchLecturesForDoctor(
      userProfile.id,
      categories,
    );
  }

  void _onMainCategoryChanged(String category) {
    setState(() {
      _currentCategory = category;
    });
  }

  Future<void> _showAddLectureDialog() async {
    final userProfile = context.read<UserProfileProvider>().userProfile;
    if (userProfile == null) return;

    final title = await showDialog<String>(
      context: context,
      builder: (context) => const AddSubjectLinkDialog(),
    );

    if (title != null && title.isNotEmpty) {
      final newLecture = Lecture(
        id: '', // Firestore will generate
        title: title,
        doctorId: userProfile.id,
        categoryName: 'المحاضرات', // Default or based on a selection
        links: [],
      );
      await context.read<DoctorSubjectProvider>().addLecture(newLecture);
    }
  }

  List<Widget> _getCategoryContentSlivers() {
    final doctorSubjectProvider = context.watch<DoctorSubjectProvider>();
    final userProfile = context.watch<UserProfileProvider>().userProfile;

    if (doctorSubjectProvider.isLoading || userProfile == null) {
      return [
        const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (doctorSubjectProvider.error != null) {
      return [
        SliverFillRemaining(
          child: Center(child: Text(doctorSubjectProvider.error!)),
        ),
      ];
    }

    switch (_currentCategory) {
      case 'المواد':
        final lectures =
            doctorSubjectProvider.lecturesByCategory['المحاضرات'] ?? [];
        return [
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => SubjectModel(lecture: lectures[index]),
              childCount: lectures.length,
            ),
          ),
        ];
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
          const SliverFillRemaining(child: Center(child: Text('مفيش تفاصيل'))),
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
                onPressed: _showAddLectureDialog,
                tooltip: 'إضافة قسم جديد',
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
              // SliverToBoxAdapter(
              //   child: SizedBox(
              //     height: Responsive.space(context, size: Space.large),
              //   ),
              // ),
              const SliverToBoxAdapter(child: Divider(indent: 4, endIndent: 1)),
              ..._getCategoryContentSlivers(),
            ],
          ),
        ),
      ),
    );
  }
}
