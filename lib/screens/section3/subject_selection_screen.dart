import 'package:flutter/material.dart';
import 'package:pivot/services/subject_service.dart';
import 'package:pivot/models/subject_model.dart';
import 'package:pivot/responsive.dart';

class SubjectSelectionScreen extends StatefulWidget {
  final List<String> previouslySelectedIds;

  const SubjectSelectionScreen({Key? key, required this.previouslySelectedIds})
    : super(key: key);

  @override
  _SubjectSelectionScreenState createState() => _SubjectSelectionScreenState();
}

class _SubjectSelectionScreenState extends State<SubjectSelectionScreen> {
  final SubjectService _subjectService = SubjectService();
  late Future<List<Subject>> _subjectsFuture;
  late Set<String> _selectedSubjectIds;

  @override
  void initState() {
    super.initState();
    _subjectsFuture = _subjectService.getSubjects();
    _selectedSubjectIds = Set<String>.from(widget.previouslySelectedIds);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('اختر موادك', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              Navigator.pop(context, _selectedSubjectIds.toList());
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Subject>>(
        future: _subjectsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('خطأ: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا توجد مواد متاحة.'));
          }

          final subjects = snapshot.data!;

          final groupedSubjects = <int, List<Subject>>{};
          for (final subject in subjects) {
            (groupedSubjects[subject.year] ??= []).add(subject);
          }

          final sortedSemesters = groupedSubjects.keys.toList()..sort();

          return ListView.builder(
            itemCount: sortedSemesters.length,
            itemBuilder: (context, index) {
              final semester = sortedSemesters[index];
              final subjectsInSemester = groupedSubjects[semester]!;
              subjectsInSemester.sort((a, b) => a.name.compareTo(b.name));

              return ExpansionTile(
                backgroundColor: Colors.white,
                collapsedBackgroundColor: Colors.white,
                iconColor: Colors.black,
                collapsedIconColor: Colors.black,
                title: Text(
                  'الترم $semester',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.text(context, size: TextSize.heading),
                  ),
                ),
                children:
                    subjectsInSemester.map((subject) {
                      final isSelected = _selectedSubjectIds.contains(
                        subject.id,
                      );
                      return CheckboxListTile(
                        activeColor: Colors.black,
                        title: Text(
                          subject.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.medium,
                            ),
                          ),
                        ),
                        subtitle: Text(
                          'القسم: ${subject.department}',
                          style: TextStyle(
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.small,
                            ),
                          ),
                        ),
                        value: isSelected,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedSubjectIds.add(subject.id);
                            } else {
                              _selectedSubjectIds.remove(subject.id);
                            }
                          });
                        },
                      );
                    }).toList(),
              );
            },
          );
        },
      ),
    );
  }
}
