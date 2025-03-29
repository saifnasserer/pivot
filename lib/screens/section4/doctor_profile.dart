import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/models/subject.dart';
import 'package:pivot/screens/section3/profile_details.dart';
import 'package:pivot/screens/section3/profile_widgets/week_tasks.dart';
import 'package:pivot/screens/section4/doctor_categories.dart';
import 'package:pivot/screens/section4/doctor_subjects.dart'
    show buildDoctorSubjectsSlivers;

class DoctorProfile extends StatefulWidget {
  static const String id = 'doctor';
  const DoctorProfile({super.key});

  @override
  State<DoctorProfile> createState() => _DoctorProfileState();
}

class _DoctorProfileState extends State<DoctorProfile> {
  String _currentCategory = 'المواد';

  final Map<String, List<SubjectModel>> _doctorSubjectsData = {
    'Artificial intelligance': [
      SubjectModel(title: 'المحاضرة الاولى', icon: Icons.insert_link_rounded),
      SubjectModel(title: 'المحاضرة الثانية', icon: Icons.insert_link_rounded),
      SubjectModel(title: 'المحاضرة الثالثة', icon: Icons.insert_link_rounded),

      SubjectModel(title: 'المحاضرة الاولى', icon: Icons.insert_link_rounded),
      SubjectModel(title: 'المحاضرة الثانية', icon: Icons.insert_link_rounded),
      SubjectModel(title: 'المحاضرة الثالثة', icon: Icons.insert_link_rounded),
      SubjectModel(title: 'المحاضرة الاولى', icon: Icons.insert_link_rounded),
      SubjectModel(title: 'المحاضرة الثانية', icon: Icons.insert_link_rounded),
      SubjectModel(title: 'المحاضرة الثالثة', icon: Icons.insert_link_rounded),
    ],
    'Machine Learning': [
      SubjectModel(title: 'تحميل الكتاب', icon: Icons.insert_link_rounded),
    ],
  };

  int _selectedSubjectIndex = 0;
  List<String> _subjectCategoryNames = [];

  @override
  void initState() {
    super.initState();
    _subjectCategoryNames = _doctorSubjectsData.keys.toList();
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
  }

  List<Widget> _getCategoryContentSlivers() {
    switch (_currentCategory) {
      case 'المواد':
        return buildDoctorSubjectsSlivers(
          context: context,
          subjectCategories: _subjectCategoryNames,
          selectedSubjectIndex: _selectedSubjectIndex,
          subjectsData: _doctorSubjectsData,
          onCategorySelected: _onSubjectCategorySelected,
        );
      case 'عن الدكتور':
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('About Doctor')),
          ),
        ];
      default:
        return [SliverToBoxAdapter(child: WeekTasksSection())];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                child: ProfileDetails(name: 'احمد طه', meta: 'دكتور'),
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
              SliverToBoxAdapter(child: Divider(indent: 4, endIndent: 1)),
              ..._getCategoryContentSlivers(),
            ],
          ),
        ),
      ),
    );
  }
}
