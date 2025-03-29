import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/section3/profile_widgets/Profile_options.dart';
import 'package:pivot/screens/section3/profile_categories_section.dart';
import 'package:pivot/screens/section3/profile_details.dart';
import 'package:pivot/screens/section3/profile_widgets/schadule.dart';
import 'package:pivot/screens/section3/profile_widgets/sections.dart';
import 'package:pivot/screens/section3/profile_widgets/subjects.dart';
import 'package:pivot/screens/section3/profile_widgets/week_tasks.dart';

class Profile extends StatefulWidget {
  static const String id = 'profile';
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String _currentCategory = 'تاسكات الاسبوع';

  Widget _getCategoryContent() {
    switch (_currentCategory) {
      case 'تاسكات الاسبوع':
        return WeekTasksSection();
      case 'الجدول':
        return Schadule();
      case 'مواد الترم':
        return SubjectsSection();
      case 'السكاشن':
        return Sections();
      default:
        return WeekTasksSection();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert_sharp, color: Colors.black),
            onPressed: () {
              profile_options(context);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: Responsive.paddingHorizontal(context),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: ProfileDetails(name: 'سيف ناصر', meta: 'قسم SC'),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: Responsive.space(context, size: Space.large),
                ),
              ),
              SliverToBoxAdapter(
                child: ProfileCategories(
                  onCategoryChanged: (category) {
                    setState(() {
                      _currentCategory = category;
                    });
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: Responsive.space(context, size: Space.large),
                ),
              ),
              SliverToBoxAdapter(child: Divider(indent: 4, endIndent: 1)),
              SliverFillRemaining(
                hasScrollBody: false,
                child: _getCategoryContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
