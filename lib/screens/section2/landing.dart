import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/section2/categories/SC_report.dart';
import 'package:pivot/screens/section2/categories/todys_report.dart';
import 'package:pivot/screens/section2/categories/week_report.dart';
import 'package:pivot/screens/section2/category_section.dart';
import 'package:pivot/screens/models/card_model.dart';
import 'package:pivot/screens/section3/profile.dart';
import 'package:pivot/screens/section4/doctor_profile.dart';

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
        return Text('AI News');
      case 'اخبار قسم CS':
        return Text('CS News');
      case 'اخبار قسم IS':
        return Text('IS News');
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
                          // Here you can update your content based on the selected category
                          print('Selected category: $category');
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.search),
                      onPressed: () {
                        // Handle search icon press
                        Navigator.pushNamed(context, DoctorProfile.id);
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
