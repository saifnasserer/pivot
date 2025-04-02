import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
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
import 'package:pivot/providers/schadule_provider.dart';
import 'package:pivot/screens/models/schedule_item.dart';
import 'add_edit_schedule_dialog.dart';

class Profile extends StatefulWidget {
  static const String id = 'profile';
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  int selectedDayIndex = 0;

  String _currentCategory = 'تاسكات الاسبوع';

  void _onDaySelected(int index) {
    setState(() {
      selectedDayIndex = index;
    });
  }

  List<Widget> _getCategoryContentSlivers() {
    final scheduleProvider = Provider.of<ScheduleProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);

    switch (_currentCategory) {
      case 'تاسكات الاسبوع':
        final allTasks = taskProvider.tasks;
        final now = DateTime.now();

        final upcomingTasks =
            allTasks.where((task) {
              final taskDueDate = DateTime(
                task.dueDate.year,
                task.dueDate.month,
                task.dueDate.day,
              );
              final today = DateTime(now.year, now.month, now.day);
              return !taskDueDate.isBefore(today);
            }).toList();

        return buildWeekTasksSlivers(context, upcomingTasks, taskProvider);
      case 'الجدول':
        final days = scheduleProvider.days;
        final validIndex = selectedDayIndex.clamp(
          0,
          days.isEmpty ? 0 : days.length - 1,
        );
        final currentDay = days.isEmpty ? '' : days[validIndex];
        final itemsForSelectedDay =
            days.isEmpty
                ? <ScheduleItem>[]
                : scheduleProvider.getScheduleForDay(currentDay);

        return buildCalendar(
          selectedDayIndex: validIndex,
          context: context,
          days: days,
          dayScheduleItems: itemsForSelectedDay,
          onDaySelected: _onDaySelected,
          handleDelete: (String itemId) {
            scheduleProvider.removeScheduleItem(currentDay, itemId);
          },
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

  @override
  Widget build(BuildContext context) {
    final scheduleProvider = Provider.of<ScheduleProvider>(context);
    final days = scheduleProvider.days;
    final currentSelectedDay =
        days.isNotEmpty &&
                selectedDayIndex >= 0 &&
                selectedDayIndex < days.length
            ? days[selectedDayIndex]
            : null;

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
      floatingActionButton:
          _currentCategory == 'الجدول' && currentSelectedDay != null
              ? FloatingActionButton(
                backgroundColor: Colors.black,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AddEditScheduleDialog(day: currentSelectedDay);
                    },
                  );
                },
                tooltip: 'اضافة محاضرة/سكشن',
                child: const Icon(Icons.add, color: Colors.white),
              )
              : null,
      body: SafeArea(
        child: Padding(
          padding: Responsive.paddingHorizontal(context),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: Responsive.space(context, size: Space.small),
                ),
              ),
              const SliverToBoxAdapter(child: ProfileDetails()),
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
              const SliverToBoxAdapter(child: Divider(indent: 4, endIndent: 1)),

              ..._getCategoryContentSlivers(),
            ],
          ),
        ),
      ),
    );
  }
}
