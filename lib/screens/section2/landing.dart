import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/section2/adminstration/admin_control.dart';
import 'package:pivot/screens/section2/categories/AI_report.dart';
import 'package:pivot/screens/section2/categories/CS_report.dart';
import 'package:pivot/screens/section2/categories/SC_report.dart';
import 'package:pivot/screens/section2/categories/todys_report.dart';
import 'package:pivot/screens/section2/categories/week_report.dart';
import 'package:pivot/screens/section2/category_section.dart';
import 'package:pivot/screens/section3/profile.dart';

import 'categories/IS_report.dart';

class Landing extends StatefulWidget {
  const Landing({super.key});
  static String id = 'landing';

  @override
  State<Landing> createState() => LandingState();
}

class LandingState extends State<Landing> with SingleTickerProviderStateMixin {
  String currentCategory = 'اخبار النهاردة';
  int currentCardIndex = 0;
  PageController pageController = PageController();

  // List of card colors
  final List<Color> cardColors = [
    Color(0xffFFEF86),
    Color(0xffF5BBBC),
    Color(0xff99F16C),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  Widget buildReports() {
    switch (currentCategory) {
      case 'اخبار النهاردة':
        return TodysReport();
      case 'اخبار الاسبوع':
        return WeekReport();
      case 'اخبار قسم SC':
        return SCReport();
      case 'اخبار قسم AI':
        return AIReport();
      case 'اخبار قسم CS':
        return CSReport();
      case 'اخبار قسم IS':
        return ISReport();
      default:
        return TodysReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  vertical: Responsive.space(context, size: Space.medium),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: CategorySection(
                        onCategoryChanged: (category) {
                          setState(() {
                            currentCategory = category;
                          });
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add_circle_outline_rounded),
                      onPressed: () {
                        // Handle profile icon press
                        Navigator.pushNamed(context, AdminControl.id);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.search),
                      onPressed: () {
                        // Handle search icon press
                        // Navigator.pushNamed(context, DoctorProfile.id);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.person_outline_rounded),
                      onPressed: () {
                        // Handle profile icon press
                        Navigator.pushNamed(context, Profile.id);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(
                    Responsive.space(context, size: Space.large),
                  ),
                  child: buildReports(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
