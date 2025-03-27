import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/section2/category_section.dart';
import 'package:pivot/screens/section2/models/card_model.dart';

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

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
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
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.person_outline_rounded),
                      onPressed: () {
                        // Handle profile icon press
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
                  child: PageView.builder(
                    controller: pageController,
                    scrollDirection: Axis.vertical,
                    itemCount: cardColors.length,
                    itemBuilder: (context, index) {
                      return CardModel(color: cardColors[index]);
                    },
                    onPageChanged: (index) {
                      setState(() {
                        currentCardIndex = index;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
