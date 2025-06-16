import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pivot/providers/subject_provider.dart';
import 'package:pivot/models/subject_model.dart';
import 'package:pivot/screens/section2/adminstration/add_edit_subject_dialog.dart';
import 'package:pivot/responsive.dart';

class GlobalSubjectManagementScreen extends StatefulWidget {
  static const String id = 'global_subject_management_screen';

  const GlobalSubjectManagementScreen({super.key});

  @override
  State<GlobalSubjectManagementScreen> createState() =>
      _GlobalSubjectManagementScreenState();
}

class _GlobalSubjectManagementScreenState
    extends State<GlobalSubjectManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SubjectProvider>(context, listen: false).fetchAllSubjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'إدارة المواد',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Consumer<SubjectProvider>(
        builder: (context, subjectProvider, child) {
          if (subjectProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (subjectProvider.error != null) {
            return Center(child: Text('Error: ${subjectProvider.error}'));
          }

          final allSubjects = subjectProvider.allSubjects;

          if (allSubjects.isEmpty) {
            return const Center(child: Text('لم يتم العثور على مواد.'));
          }

          final groupedSubjects = <int, List<Subject>>{};
          for (final subject in allSubjects) {
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
                      return ListTile(
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
                          'الكود: ${subject.code} - القسم: ${subject.department}',
                          style: TextStyle(
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.small,
                            ),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.black),
                              onPressed: () async {
                                final updatedSubject =
                                    await showAddEditSubjectDialog(
                                      context,
                                      subject: subject,
                                    );
                                if (updatedSubject != null) {
                                  try {
                                    await Provider.of<SubjectProvider>(
                                      context,
                                      listen: false,
                                    ).updateSubject(updatedSubject);
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'تم تحديث المادة بنجاح.',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('فشل تحديث المادة: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: Text(
                                          'تأكيد الحذف',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: Responsive.text(
                                              context,
                                              size: TextSize.heading,
                                            ),
                                          ),
                                        ),
                                        content: Text(
                                          'هل أنت متأكد أنك تريد حذف ${subject.name}؟',
                                          style: TextStyle(
                                            fontSize: Responsive.text(
                                              context,
                                              size: TextSize.medium,
                                            ),
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.of(
                                                  context,
                                                ).pop(false),
                                            child: const Text('إلغاء'),
                                          ),
                                          TextButton(
                                            onPressed:
                                                () => Navigator.of(
                                                  context,
                                                ).pop(true),
                                            child: const Text('حذف'),
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                );

                                if (confirm == true) {
                                  try {
                                    await Provider.of<SubjectProvider>(
                                      context,
                                      listen: false,
                                    ).deleteSubject(subject.id);
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('تم حذف المادة بنجاح.'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('فشل حذف المادة: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: () async {
          final newSubject = await showAddEditSubjectDialog(context);
          if (newSubject != null) {
            try {
              await Provider.of<SubjectProvider>(
                context,
                listen: false,
              ).addSubject(newSubject);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تمت إضافة المادة بنجاح.'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('فشل إضافة المادة: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
