import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/models/lecture_card_model.dart';
import 'package:pivot/screens/section3/profile_widgets/Profile_options.dart';
import 'package:pivot/screens/section3/profile_categories_section.dart';
import 'package:pivot/screens/section3/profile_details.dart';
import 'package:pivot/screens/section3/profile_widgets/schadule.dart'
    show buildCalendar;
import 'package:pivot/screens/section3/profile_widgets/sections.dart';
import 'package:pivot/screens/section3/profile_widgets/subjects.dart'
    show buildSubjectsSlivers;
import 'package:pivot/screens/section3/profile_widgets/week_tasks.dart'
    show buildWeekTasksSlivers;
import 'package:provider/provider.dart';
import 'package:pivot/providers/task_provider.dart';

class Profile extends StatefulWidget {
  static const String id = 'profile';
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final Map<String, List<LectureCardModel>> dayLectures = {
    'السبت': [
      LectureCardModel(
        section: false,
        title: 'الحوسبة عالية الاداء',
        description: 'مدرج 2 الساعه 1ونص',
      ),
      LectureCardModel(
        section: true,
        title: 'سكشن الحوسبة',
        description: 'معمل 3 الساعه 3',
      ),
    ],
    'الاحد': [
      LectureCardModel(
        section: false,
        title: 'هندسة البرمجيات',
        description: 'مدرج 1 الساعه 9 صباحا',
      ),
    ],
    'الاثنين': [
      LectureCardModel(
        section: true,
        title: 'سكشن هندسة البرمجيات',
        description: 'معمل 2 الساعه 11 صباحا',
      ),
    ],
    'الثلاثاء': [],
    'الاربعاء': [
      LectureCardModel(
        section: false,
        title: 'نظم التشغيل',
        description: 'مدرج 3 الساعه 2 ظهرا',
      ),
    ],
    'الخميس': [
      LectureCardModel(
        section: false,
        title: 'نظم التشغيل',
        description: 'مدرج 3 الساعه 2 ظهرا',
      ),
    ],
  };

  // List of days in order (right to left for Arabic)
  final List<String> days = [
    'السبت',
    'الاحد',
    'الاثنين',
    'الثلاثاء',
    'الاربعاء',
    'الخميس',
  ];

  int selectedDayIndex = 0;

  String _currentCategory = 'تاسكات الاسبوع';

  // --- Callback function for day selection ---
  void _onDaySelected(int index) {
    setState(() {
      selectedDayIndex = index;
    });
  }
  // --- End Callback ---

  // --- Modified to return List<Widget> (slivers) ---
  List<Widget> _getCategoryContentSlivers() {
    switch (_currentCategory) {
      case 'تاسكات الاسبوع':
        // Get provider and tasks
        final taskProvider = Provider.of<TaskProvider>(context);
        final allTasks = taskProvider.tasks; // Get all tasks first
        final now = DateTime.now();

        // Filter tasks: Keep only those whose due date is today or in the future
        // We compare dates only, ignoring time, by creating new DateTime objects
        final upcomingTasks =
            allTasks.where((task) {
              final taskDueDate = DateTime(
                task.dueDate.year,
                task.dueDate.month,
                task.dueDate.day,
              );
              final today = DateTime(now.year, now.month, now.day);
              return !taskDueDate.isBefore(
                today,
              ); // Keep if due date is not before today
            }).toList();

        // Call with required arguments
        return buildWeekTasksSlivers(context, upcomingTasks, taskProvider);
      case 'الجدول':
        // buildCalendar already returns List<Widget>
        return buildCalendar(
          selectedDayIndex: selectedDayIndex,
          context: context,
          days: days,
          dayLectures: dayLectures,
          onDaySelected: _onDaySelected, // <-- Pass the callback here
        );
      case 'مواد الترم':
        return buildSubjectsSlivers(context);
      case 'السكاشن':
        return buildSectionsSlivers(context);
      default:
        return [
          const SliverFillRemaining(
            child: Center(child: Text('Unknown Category')),
          ),
        ];
    }
  }
  // --- End Modification ---

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
          // --- Use CustomScrollView for sliver-based layout ---
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: Responsive.space(context, size: Space.small),
                ),
              ),
              const SliverToBoxAdapter(
                child: ProfileDetails(name: 'سيف ناصر ', meta: 'قسم SC'),
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
                      // Reset day index when changing main category if needed
                      // selectedDayIndex = 0;
                    });
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: Responsive.space(context, size: Space.large),
                ),
              ),
              const SliverToBoxAdapter(child: Divider(indent: 4, endIndent: 1)),

              // --- Use spread operator to insert the slivers ---
              ..._getCategoryContentSlivers(),
              // --- End Spread Operator ---
            ],
          ),
          // --- End CustomScrollView ---
        ),
      ),
    );
  }
}
