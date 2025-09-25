import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pivot/providers/subject_provider.dart';
import 'package:pivot/screens/section2/adminstration/add_edit_subject_dialog.dart';
import 'package:pivot/providers/guide_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/models/subject_model.dart';

import 'package:pivot/widgets/unified_dialog.dart';

class GlobalSubjectManagementScreen extends StatefulWidget {
  // = 'global_subject_management_screen';

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
    for (var subject
        in Provider.of<SubjectProvider>(context, listen: false).allSubjects) {
      _expandedState[subject.year] = false;
    }
  }

  Widget _buildSubjectCard(Subject subject) {
    return Container(
      margin: EdgeInsets.only(
        bottom: Responsive.space(context, size: Space.medium),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: Responsive.padding(context, size: Space.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subject Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AutoSizeText(
                        subject.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.medium,
                          ),
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.small),
                      ),
                      Row(
                        children: [
                          ...subject.departments.map(
                            (dep) => Container(
                              margin: EdgeInsets.only(right: 4),
                              padding: EdgeInsets.symmetric(
                                horizontal: Responsive.space(
                                  context,
                                  size: Space.small,
                                ),
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                dep,
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontSize: Responsive.text(
                                    context,
                                    size: TextSize.small,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: Responsive.space(
                                context,
                                size: Space.small,
                              ),
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'ساعات: ${subject.hours}',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                                fontSize: Responsive.text(
                                  context,
                                  size: TextSize.small,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Action Buttons
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.edit,
                        color: Colors.black87,
                        size: 20,
                      ),
                      onPressed: () => _editSubject(subject),
                      tooltip: 'تعديل المادة',
                    ),
                    SizedBox(
                      height: Responsive.space(context, size: Space.small),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.red,
                        size: 20,
                      ),
                      onPressed: () => _deleteSubject(subject),
                      tooltip: 'حذف المادة',
                    ),
                  ],
                ),
              ],
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
            SnackBar(
              content: Text('تم تحديث المادة ${subject.name} بنجاح'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل تحديث المادة: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteSubject(Subject subject) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => UnifiedDialog(
            title: 'تأكيد الحذف',
            subtitle: 'حذف مادة ${subject.name}',
            content: Container(
              padding: Responsive.padding(context, size: Space.medium),
              child: Row(
                children: [
                  Icon(
                    Icons.delete_forever,
                    color: Colors.red,
                    size: Responsive.text(context, size: TextSize.heading),
                  ),
                  SizedBox(
                    width: Responsive.space(context, size: Space.medium),
                  ),
                  Expanded(
                    child: Text(
                      'هل أنت متأكد من رغبتك في حذف مادة ${subject.name}؟ لا يمكن التراجع عن هذا الإجراء وستتم إزالة جميع البيانات المرتبطة بها.',
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.medium,
                        ),
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            confirmText: 'حذف المادة',
            confirmIcon: Icons.delete_forever,
            onConfirm: () => Navigator.of(context).pop(true),
            onCancel: () => Navigator.of(context).pop(false),
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
            SnackBar(
              content: Text('تم حذف المادة ${subject.name} بنجاح'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل حذف المادة: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
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
            SnackBar(
              content: Text('تمت إضافة المادة ${newSubject.name} بنجاح'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل إضافة المادة: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    }
  }

  Widget _buildSubjectsManagementTab() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<SubjectProvider>(
        builder: (context, subjectProvider, child) {
          if (subjectProvider.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.black),
                  SizedBox(
                    height: Responsive.space(context, size: Space.medium),
                  ),
                  Text(
                    'جاري تحميل المواد...',
                    style: TextStyle(
                      fontSize: Responsive.text(context, size: TextSize.medium),
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }
          if (subjectProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  SizedBox(
                    height: Responsive.space(context, size: Space.medium),
                  ),
                  Text(
                    'حدث خطأ: ${subjectProvider.error}',
                    style: TextStyle(
                      fontSize: Responsive.text(context, size: TextSize.medium),
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          if (subjectProvider.allSubjects.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.menu_book_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  SizedBox(
                    height: Responsive.space(context, size: Space.medium),
                  ),
                  Text(
                    'لم يتم العثور على مواد',
                    style: TextStyle(
                      fontSize: Responsive.text(context, size: TextSize.medium),
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(
                    height: Responsive.space(context, size: Space.small),
                  ),
                  Text(
                    'لإضافة مادة جديدة، اضغط على زر +',
                    style: TextStyle(
                      fontSize: Responsive.text(context, size: TextSize.small),
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          final groupedSubjects = <int, List<Subject>>{};
          for (final subject in subjectProvider.allSubjects) {
            (groupedSubjects[subject.year] ??= []).add(subject);
          }
          final sortedYears = groupedSubjects.keys.toList()..sort();

          return Column(
            children: [
              // Subjects List
              Expanded(
                child: ListView.builder(
                  padding: Responsive.padding(context, size: Space.large),
                  itemCount: sortedYears.length,
                  itemBuilder: (context, index) {
                    final year = sortedYears[index];
                    final subjectsInYear = groupedSubjects[year]!;
                    subjectsInYear.sort((a, b) => a.name.compareTo(b.name));

                    final isExpanded = _expandedState[year] ?? false;

                    return Container(
                      margin: EdgeInsets.only(
                        bottom: Responsive.space(context, size: Space.large),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Year Header
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  setState(() {
                                    _expandedState[year] = !isExpanded;
                                  });
                                },
                                child: Padding(
                                  padding: Responsive.padding(
                                    context,
                                    size: Space.medium,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: Responsive.padding(
                                          context,
                                          size: Space.small,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.grade,
                                          color: Colors.black87,
                                          size: 20,
                                        ),
                                      ),
                                      SizedBox(
                                        width: Responsive.space(
                                          context,
                                          size: Space.medium,
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'الترم $year',
                                              style: TextStyle(
                                                fontSize: Responsive.text(
                                                  context,
                                                  size: TextSize.medium,
                                                ),
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            Text(
                                              '${subjectsInYear.length} مادة',
                                              style: TextStyle(
                                                fontSize: Responsive.text(
                                                  context,
                                                  size: TextSize.small,
                                                ),
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        isExpanded
                                            ? Icons.expand_less
                                            : Icons.expand_more,
                                        color: Colors.black87,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Subjects in Year
                          if (isExpanded) ...[
                            SizedBox(
                              height: Responsive.space(
                                context,
                                size: Space.medium,
                              ),
                            ),
                            ...subjectsInYear.map(
                              (subject) => _buildSubjectCard(subject),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          heroTag: 'global_subject_management_fab',
          onPressed: _addSubject,
          label: Text(
            'إضافة مادة',
            style: TextStyle(
              color: Colors.white,
              fontSize: Responsive.text(context, size: TextSize.medium),
              fontWeight: FontWeight.bold,
            ),
          ),
          icon: Icon(Icons.add, color: Colors.white),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }

  Widget _buildGuideManagementTab() {
    return Consumer<GuideProvider>(
      builder: (context, guideProvider, child) {
        if (guideProvider.isLoading && guideProvider.guideContent == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.black),
                SizedBox(height: Responsive.space(context, size: Space.medium)),
                Text(
                  'جاري تحميل الأدلة...',
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.medium),
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }
        if (guideProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                SizedBox(height: Responsive.space(context, size: Space.medium)),
                Text(
                  'حدث خطأ: ${guideProvider.error}',
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.medium),
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        if (guideProvider.guideContent == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.picture_as_pdf_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                SizedBox(height: Responsive.space(context, size: Space.medium)),
                Text(
                  'لا يوجد محتوى للدليل',
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.medium),
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        final guideContent = guideProvider.guideContent!;

        return ListView(
          padding: Responsive.padding(context, size: Space.large),
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: Responsive.padding(context, size: Space.large),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: Responsive.padding(
                            context,
                            size: Space.small,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.picture_as_pdf,
                            color: Colors.black87,
                            size: 24,
                          ),
                        ),
                        SizedBox(
                          width: Responsive.space(context, size: Space.medium),
                        ),
                        Text(
                          'أدلة القسم',
                          style: TextStyle(
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.heading,
                            ),
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(
                      height: Responsive.space(context, size: Space.medium),
                    ),

                    if (guideContent.guidebooks.isEmpty)
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.folder_open,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            SizedBox(
                              height: Responsive.space(
                                context,
                                size: Space.small,
                              ),
                            ),
                            Text(
                              'لا توجد أدلة متاحة حالياً',
                              style: TextStyle(
                                fontSize: Responsive.text(
                                  context,
                                  size: TextSize.medium,
                                ),
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (guideContent.guidebooks.isNotEmpty)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: guideContent.guidebooks.length,
                        itemBuilder: (context, index) {
                          final guidebook = guideContent.guidebooks[index];
                          return Container(
                            margin: EdgeInsets.only(
                              bottom: Responsive.space(
                                context,
                                size: Space.small,
                              ),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: ListTile(
                              leading: Container(
                                padding: Responsive.padding(
                                  context,
                                  size: Space.small,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.picture_as_pdf,
                                  color: Colors.black87,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                guidebook.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: Responsive.text(
                                    context,
                                    size: TextSize.medium,
                                  ),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Container(
                                decoration: BoxDecoration(
                                  color: Colors.red[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 18,
                                  ),
                                  onPressed:
                                      guideProvider.isLoading
                                          ? null
                                          : () => guideProvider.removeGuidebook(
                                            guidebook,
                                          ),
                                  tooltip: 'حذف الدليل',
                                ),
                              ),
                              onTap: () async {
                                final uri = Uri.parse(guidebook.url);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                }
                              },
                            ),
                          );
                        },
                      ),

                    SizedBox(
                      height: Responsive.space(context, size: Space.medium),
                    ),

                    Center(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextButton.icon(
                          icon: const Icon(
                            Icons.upload_file,
                            color: Colors.white,
                          ),
                          label: Text(
                            'إضافة دليل جديد (PDF)',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: Responsive.text(
                                context,
                                size: TextSize.medium,
                              ),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed:
                              guideProvider.isLoading
                                  ? null
                                  : () => guideProvider.addGuidebook(),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              vertical: Responsive.space(
                                context,
                                size: Space.medium,
                              ),
                            ),
                          ),
                        ),
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

  Widget _buildStatTile(
    BuildContext context,
    IconData icon,
    String title,
    String value,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: Responsive.padding(context, size: Space.medium),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: Responsive.space(context, size: Space.small)),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: Responsive.text(context, size: TextSize.medium),
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.small),
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(
              'الإدارة العامة',
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.heading),
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black),
            bottom: TabBar(
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: Colors.black,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.menu_book, size: 20),
                      SizedBox(
                        width: Responsive.space(context, size: Space.small),
                      ),
                      Text('إدارة المواد'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.picture_as_pdf, size: 20),
                      SizedBox(
                        width: Responsive.space(context, size: Space.small),
                      ),
                      Text('إدارة الدليل'),
                    ],
                  ),
                ),
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
