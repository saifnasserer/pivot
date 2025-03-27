import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/models/task_model.dart';
import 'package:pivot/screens/section3/profile_categories_section.dart';
import 'package:pivot/screens/section3/week_tasks_section/week_tasks.dart';

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
        // TODO: Replace with Schedule section when created
        return Center(
          child: Text(
            'الجدول سيظهر هنا',
            style: TextStyle(
              fontSize: Responsive.space(context, size: Space.medium),
              color: Colors.black54,
            ),
          ),
        );
      case 'مواد الترم':
        // TODO: Replace with Term Subjects section when created
        return Center(
          child: Text(
            'مواد الترم ستظهر هنا',
            style: TextStyle(
              fontSize: Responsive.space(context, size: Space.medium),
              color: Colors.black54,
            ),
          ),
        );
      case 'السكاشن':
        // TODO: Replace with Sections content when created
        return Center(
          child: Text(
            'السكاشن ستظهر هنا',
            style: TextStyle(
              fontSize: Responsive.space(context, size: Space.medium),
              color: Colors.black54,
            ),
          ),
        );
      default:
        return WeekTasksSection();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // title: Text('الملف الشخصي'),
        // centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
            // Handle back icon press
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert_sharp, color: Colors.black),
            onPressed: () {
              // Handle search icon press
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: Responsive.paddingHorizontal(context),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'SC قسم',
                        style: TextStyle(
                          fontSize: Responsive.space(
                            context,
                            size: Space.medium,
                          ),
                          color: Color(0xffD9D9D9),
                        ),
                      ),
                      Text(
                        'فاطمة بشير',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize:
                              Responsive.space(context, size: Space.xlarge) *
                              1.2,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'فرقة تالتة',
                        style: TextStyle(
                          fontSize: Responsive.space(
                            context,
                            size: Space.medium,
                          ),
                          color: Color(0xffD9D9D9),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: Responsive.space(context, size: Space.large)),
                  Container(
                    width: Responsive.space(context, size: Space.large) * 5,
                    height: Responsive.space(context, size: Space.large) * 5,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                      // image: DecorationImage(
                      //   image: AssetImage('assets/icon.png'),
                      //   fit: BoxFit.cover,
                      // ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: Responsive.space(context, size: Space.large)),
              ProfileCategories(
                onCategoryChanged: (category) {
                  setState(() {
                    _currentCategory = category;
                  });
                },
              ),
              SizedBox(height: Responsive.space(context, size: Space.large)),
              Divider(indent: 4, endIndent: 1),
              Expanded(child: _getCategoryContent()),
            ],
          ),
        ),
      ),
    );
  }
}
