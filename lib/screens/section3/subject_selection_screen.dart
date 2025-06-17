import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pivot/models/subject_model.dart';
import 'package:pivot/providers/guide_provider.dart';
import 'package:pivot/providers/subject_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SubjectSelectionScreen extends StatefulWidget {
  final List<String> previouslySelectedIds;

  const SubjectSelectionScreen({super.key, required this.previouslySelectedIds});

  @override
  _SubjectSelectionScreenState createState() => _SubjectSelectionScreenState();
}

class _SubjectSelectionScreenState extends State<SubjectSelectionScreen> {
  final Map<int, bool> _expandedState = {};
  late Set<String> _selectedSubjectIds;

  @override
  void initState() {
    super.initState();
    _selectedSubjectIds = Set<String>.from(widget.previouslySelectedIds);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SubjectProvider>(context, listen: false).fetchAllSubjects();
      Provider.of<GuideProvider>(context, listen: false).fetchGuideContent();
    });
  }

  Widget _buildSubjectCard(Subject subject) {
    final isSelected = _selectedSubjectIds.contains(subject.id);
    return Card(
      elevation: 3.0,
      color: Colors.white,
      shadowColor: Colors.grey.withOpacity(0.2),
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color:
              isSelected ? Theme.of(context).primaryColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedSubjectIds.remove(subject.id);
            } else {
              _selectedSubjectIds.add(subject.id);
            }
          });
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize:
                            Responsive.text(context, size: TextSize.medium),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'القسم: ${subject.department}',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize:
                            Responsive.text(context, size: TextSize.small),
                      ),
                    ),
                  ],
                ),
              ),
              Checkbox(
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
                activeColor: Theme.of(context).primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuideSection() {
    return Consumer<GuideProvider>(
      builder: (context, guideProvider, child) {
        if (guideProvider.isLoading && guideProvider.guideContent == null) {
          return const SizedBox.shrink(); // Don't show loading indicator here
        }
        if (guideProvider.error != null ||
            guideProvider.guideContent == null ||
            (guideProvider.guideContent!.guidebookUrl.isEmpty &&
                guideProvider.guideContent!.planImageUrls.isEmpty)) {
          return const SizedBox.shrink(); // Don't show anything if error or no content
        }

        final guideContent = guideProvider.guideContent!;

        return Card(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          elevation: 4.0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'دليل الكلية والخطط المقترحة',
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.heading),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (guideContent.guidebookUrl.isNotEmpty)
                  ListTile(
                    leading:
                        const Icon(Icons.picture_as_pdf, color: Colors.red),
                    title: const Text('تحميل دليل الكلية'),
                    trailing: const Icon(Icons.launch),
                    onTap: () async {
                      final uri = Uri.parse(guideContent.guidebookUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                  ),
                if (guideContent.guidebookUrl.isNotEmpty &&
                    guideContent.planImageUrls.isNotEmpty)
                  const Divider(height: 24),
                if (guideContent.planImageUrls.isNotEmpty)
                  SizedBox(
                    height: 150,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: guideContent.planImageUrls.length,
                      itemBuilder: (context, index) {
                        final imageUrl = guideContent.planImageUrls[index];
                        return Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: CachedNetworkImage(
                              imageUrl: imageUrl,
                              width: 100,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.error),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubjectsList() {
    return Consumer<SubjectProvider>(
      builder: (context, subjectProvider, child) {
        if (subjectProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (subjectProvider.error != null) {
          return Center(child: Text('خطأ: ${subjectProvider.error}'));
        }
        if (subjectProvider.allSubjects.isEmpty) {
          return const Center(child: Text('لا توجد مواد متاحة.'));
        }

        final subjects = subjectProvider.allSubjects;
        final groupedSubjects = <int, List<Subject>>{};
        for (final subject in subjects) {
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
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'الترم: $year',
                          style: TextStyle(
                            fontSize: Responsive.text(context,
                                size: TextSize.heading),
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        Icon(
                          isExpanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                          color: Theme.of(context).primaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
                if (isExpanded)
                  ...subjectsInYear
                      .map((subject) => _buildSubjectCard(subject)),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('اختر موادك'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () {
                Navigator.pop(context, _selectedSubjectIds.toList());
              },
            ),
          ],
        ),
        body: Column(
          children: [
            _buildGuideSection(),
            Expanded(
              child: _buildSubjectsList(),
            ),
          ],
        ),
      ),
    );
  }
}
