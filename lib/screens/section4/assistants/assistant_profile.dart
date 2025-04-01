import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/section3/profile_details.dart';
import 'assistant_subjects.dart';
import 'assistant_categories.dart';
import 'package:provider/provider.dart';
import 'package:pivot/providers/section_provider.dart';
import 'package:pivot/screens/models/section_info.dart';
import 'add_edit_section_dialog.dart';

class AssistantProfile extends StatefulWidget {
  static const String id = 'section';
  final bool isAdmin;

  const AssistantProfile({super.key, this.isAdmin = false});

  @override
  State<AssistantProfile> createState() => _AssistantProfileState();
}

class _AssistantProfileState extends State<AssistantProfile> {
  String _currentCategory = 'المواد';

  int _selectedSubjectIndex = 0;
  List<String> _subjectCategoryNames = [];

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      final sectionProvider = Provider.of<SectionProvider>(
        context,
        listen: false,
      );
      setState(() {
        _subjectCategoryNames = sectionProvider.subjectNames;
      });
    });
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
    final sectionProvider = Provider.of<SectionProvider>(context);
    _subjectCategoryNames = sectionProvider.subjectNames;

    if (_selectedSubjectIndex >= _subjectCategoryNames.length) {
      _selectedSubjectIndex = 0;
    }

    final selectedSubjectName =
        _subjectCategoryNames.isNotEmpty &&
                _subjectCategoryNames.length > _selectedSubjectIndex
            ? _subjectCategoryNames[_selectedSubjectIndex]
            : null;

    switch (_currentCategory) {
      case 'المواد':
        final sectionsForSelectedSubject =
            selectedSubjectName != null
                ? sectionProvider.getSectionsForSubject(selectedSubjectName)
                : <SectionInfo>[];

        return buildAssistantSubjects(
          context: context,
          subjectCategories: _subjectCategoryNames,
          selectedSubjectIndex: _selectedSubjectIndex,
          sections: sectionsForSelectedSubject,
          onCategorySelected: _onSubjectCategorySelected,
        );
      case 'عن المعيد':
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('عن المعيد')),
          ),
        ];
      default:
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('Unknown Category')),
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedSubjectName =
        _subjectCategoryNames.isNotEmpty &&
                _subjectCategoryNames.length > _selectedSubjectIndex
            ? _subjectCategoryNames[_selectedSubjectIndex]
            : null;

    return Scaffold(
      appBar: AppBar(),
      floatingActionButton:
      // widget.isAdmin
      FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: () {
          if (selectedSubjectName != null) {
            final sectionProvider = context.read<SectionProvider>();
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AddEditSectionDialog(
                  subjectNames: sectionProvider.subjectNames,
                  initialSubjectName: selectedSubjectName,
                );
              },
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('لازم تحدد الماده الاول')),
            );
            print('Cannot add section: No subject selected or available.');
          }
        },
        tooltip: 'سكشن جديد',
        child: const Icon(Icons.add, color: Colors.white),
      ),
      // : null,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: Responsive.paddingHorizontal(context),
          child: CustomScrollView(
            slivers: [
              // SliverToBoxAdapter(
              //   child: SizedBox(
              //     heigh`t: Responsive.space(context, size: Space.xlarge),
              //   ),
              // ),
              SliverToBoxAdapter(
                child: ProfileDetails(
                  name: 'الشيماء عبدالغفار',
                  meta: 'بشمهندسة',
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: Responsive.space(context, size: Space.large),
                ),
              ),
              SliverToBoxAdapter(
                child: AssistantCategories(
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
