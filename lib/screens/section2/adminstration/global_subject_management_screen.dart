import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pivot/providers/subject_provider.dart';
import 'package:pivot/models/subject_model.dart';
import 'package:pivot/screens/section2/adminstration/add_edit_subject_dialog.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/providers/guide_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

class GlobalSubjectManagementScreen extends StatefulWidget {
  static const String id = 'global_subject_management_screen';

  const GlobalSubjectManagementScreen({super.key});

  @override
  State<GlobalSubjectManagementScreen> createState() =>
      _GlobalSubjectManagementScreenState();
}

class _GlobalSubjectManagementScreenState
    extends State<GlobalSubjectManagementScreen> {
  final Map<int, bool> _expandedState = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SubjectProvider>(context, listen: false).fetchAllSubjects();
      Provider.of<GuideProvider>(context, listen: false).fetchGuideContent();
    });
    for (var subject in Provider.of<SubjectProvider>(context, listen: false).allSubjects) {
      _expandedState[subject.year] = false;
    }
  }

  Widget _buildSubjectCard(Subject subject) {
    return Card(
      elevation: 3.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      color: Colors.white,
      shadowColor: Colors.grey.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.text(context, size: TextSize.medium),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'الكود: ${subject.code}  |  القسم: ${subject.department}',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: Responsive.text(context, size: TextSize.small),
                  ),
                ),
              ],
            ),
            const Spacer(),
            IconButton(
              icon: Icon(Icons.edit, color: Theme.of(context).primaryColor),
              onPressed: () => _editSubject(subject),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () => _deleteSubject(subject),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editSubject(Subject subject) async {
    final updatedSubject = await showAddEditSubjectDialog(
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تحديث المادة بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل تحديث المادة: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteSubject(Subject subject) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من رغبتك في حذف مادة ${subject.name}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حذف'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف المادة بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل حذف المادة: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _addSubject() async {
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
              content: Text('تمت إضافة المادة بنجاح'),
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
  }

  Widget _buildSubjectsManagementTab() {
    return Scaffold(
      body: Consumer<SubjectProvider>(
        builder: (context, subjectProvider, child) {
          if (subjectProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (subjectProvider.error != null) {
            return Center(child: Text('حدث خطأ: ${subjectProvider.error}'));
          }
          if (subjectProvider.allSubjects.isEmpty) {
            return const Center(
              child: Text(
                'لم يتم العثور على مواد. لإضافة مادة جديدة، اضغط على زر +',
              ),
            );
          }

          final groupedSubjects = <int, List<Subject>>{};
          for (final subject in subjectProvider.allSubjects) {
            (groupedSubjects[subject.year] ??= []).add(subject);
          }
          final sortedYears = groupedSubjects.keys.toList()..sort();

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: sortedYears.length,
            itemBuilder: (context, index) {
              final year = sortedYears[index];
              final subjectsInYear = groupedSubjects[year]!;
              subjectsInYear.sort((a, b) => a.name.compareTo(b.name));

              final isExpanded = _expandedState[year] ?? false;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        _expandedState[year] = !isExpanded;
                      });
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: Responsive.space(context, size: Space.small),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'الترم: $year',
                            style: TextStyle(
                              fontSize: Responsive.text(
                                context,
                                size: TextSize.heading,
                              ),
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: Theme.of(context).primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isExpanded)
                    ...subjectsInYear.map(
                      (subject) => _buildSubjectCard(subject),
                    ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSubject,
        label: const Text('إضافة مادة'),
        icon: const Icon(Icons.add),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }

  Widget _buildGuideManagementTab() {
    return Consumer<GuideProvider>(
      builder: (context, guideProvider, child) {
        if (guideProvider.isLoading && guideProvider.guideContent == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (guideProvider.error != null) {
          return Center(child: Text('حدث خطأ: ${guideProvider.error}'));
        }
        if (guideProvider.guideContent == null) {
          return const Center(child: Text('لا يوجد محتوى للدليل.'));
        }

        final guideContent = guideProvider.guideContent!;

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Card(
              elevation: 3.0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('دليل الكلية (PDF)',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    if (guideContent.guidebookUrl.isNotEmpty)
                      ListTile(
                        leading:
                            Icon(Icons.picture_as_pdf, color: Colors.red),
                        title: Text('عرض الدليل الحالي'),
                        onTap: () async {
                          final uri = Uri.parse(guideContent.guidebookUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          }
                        },
                      ),
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.upload_file),
                        label: Text('تحديث ملف الدليل'),
                        onPressed: guideProvider.isLoading
                            ? null
                            : () => guideProvider.updateGuidebook(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 3.0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('صور الخطط المقترحة',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    if (guideContent.planImageUrls.isEmpty)
                      Center(child: Text('لا توجد صور حالياً.')),
                    if (guideContent.planImageUrls.isNotEmpty)
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: guideContent.planImageUrls.length,
                        itemBuilder: (context, index) {
                          final imageUrl =
                              guideContent.planImageUrls[index];
                          return Stack(
                            alignment: Alignment.topLeft,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  placeholder: (context, url) => Center(
                                      child: CircularProgressIndicator()),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                left: 4,
                                child: CircleAvatar(
                                  backgroundColor: Colors.black54,
                                  radius: 16,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: Icon(Icons.close,
                                        color: Colors.white, size: 16),
                                    onPressed: guideProvider.isLoading
                                        ? null
                                        : () => guideProvider
                                            .removePlanImage(imageUrl),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.add_a_photo),
                        label: Text('إضافة صورة خطة'),
                        onPressed: guideProvider.isLoading
                            ? null
                            : () => guideProvider.addPlanImage(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('الإدارة العامة'),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'إدارة المواد'),
                Tab(text: 'إدارة الدليل'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _buildSubjectsManagementTab(),
              _buildGuideManagementTab(),
            ],
          ),
        ),
      ),
    );
  }
}
