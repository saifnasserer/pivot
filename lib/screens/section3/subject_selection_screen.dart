import 'package:flutter/material.dart';
import 'package:pivot/models/subject_model.dart';
import 'package:pivot/providers/guide_provider.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/providers/subject_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SubjectSelectionScreen extends StatefulWidget {
  final List<String> previouslySelectedIds;

  const SubjectSelectionScreen({
    super.key,
    required this.previouslySelectedIds,
  });

  @override
  _SubjectSelectionScreenState createState() => _SubjectSelectionScreenState();
}

class _SubjectSelectionScreenState extends State<SubjectSelectionScreen> {
  bool _isLoading = false;
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
            if (_selectedSubjectIds.contains(subject.id)) {
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
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.medium,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'القسم: ${subject.department}',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.small,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Checkbox(
                value: isSelected,
                onChanged: (bool? value) {
                  setState(() {
                    final subjectId = subject.id;
                    if (value == true) {
                      _selectedSubjectIds.add(subjectId);
                    } else {
                      _selectedSubjectIds.remove(subjectId);
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
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (guideProvider.error != null) {
          return SizedBox(
            height: 200,
            child: Center(child: Text('خطأ: ${guideProvider.error}')),
          );
        }

        final guideContent = guideProvider.guideContent;
        if (guideContent == null || guideContent.guidebooks.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(child: Text('لا يوجد دليل متاح حالياً.')),
          );
        }

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: guideContent.guidebooks.length,
                  itemBuilder: (context, index) {
                    final guidebook = guideContent.guidebooks[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.picture_as_pdf,
                          color: Colors.red,
                        ),
                        title: Text(
                          guidebook.name,
                          style: TextStyle(
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.medium,
                            ),
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
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

            final yearColors = [
              Colors.blue.withOpacity(0.05),
              Colors.green.withOpacity(0.05),
              Colors.orange.withOpacity(0.05),
              Colors.purple.withOpacity(0.05),
              Colors.red.withOpacity(0.05),
            ];
            final colorIndex = ((year - 1) ~/ 2) % yearColors.length;
            final yearColor = yearColors[colorIndex];

            return Container(
              margin: const EdgeInsets.only(bottom: 12.0),
              decoration: BoxDecoration(
                color: yearColor,
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        _expandedState[year] = !isExpanded;
                      });
                    },
                    borderRadius: BorderRadius.circular(16.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
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
                              color: Colors.black,
                            ),
                          ),
                          Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: Colors.black,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isExpanded)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                      child: Column(
                        children:
                            subjectsInYear
                                .map((subject) => _buildSubjectCard(subject))
                                .toList(),
                      ),
                    ),
                ],
              ),
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
          title: const Text('اختر كورساتك'),
          centerTitle: true,
          actions: [
            Consumer<GuideProvider>(
              builder: (context, guideProvider, child) {
                final hasContent =
                    guideProvider.guideContent != null &&
                    guideProvider.guideContent!.guidebooks.isNotEmpty;
                return IconButton(
                  icon: const Icon(Icons.menu_book_outlined),
                  tooltip: 'عرض دليل الكلية',
                  onPressed:
                      !hasContent
                          ? null
                          : () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                              ),
                              builder: (_) => _buildGuideSection(),
                            );
                          },
                );
              },
            ),
          ],
        ),
        body: _buildSubjectsList(),
        floatingActionButton: FloatingActionButton(
          onPressed: _isLoading
              ? null
              : () async {
                  setState(() {
                    _isLoading = true;
                  });

                  try {
                    final userProfileProvider = Provider.of<UserProfileProvider>(
                      context,
                      listen: false,
                    );
                    final subjectProvider = Provider.of<SubjectProvider>(
                      context,
                      listen: false,
                    );

                    final userRole = userProfileProvider.loggedInUserProfile?.role;
                    UserProfile? updatedProfile;

                    if (userRole == 'Student') {
                      updatedProfile = await userProfileProvider
                          .updateEnrolledSubjects(_selectedSubjectIds.toList());
                    } else if (userRole == 'Professor' ||
                        userRole == 'miniProfessor' ||
                        userRole == 'Doctor') {
                      updatedProfile = await userProfileProvider
                          .updateTeachingSubjects(_selectedSubjectIds.toList());
                    }

                    if (mounted && updatedProfile != null) {
                      await subjectProvider
                          .fetchAndFilterSubjects(updatedProfile);
                    }

                    if (mounted) {
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    // Handle error, maybe show a snackbar
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to update subjects: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  }
                },
          child: _isLoading
              ? const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                )
              : const Icon(Icons.check_rounded),
          backgroundColor: Theme.of(context).primaryColor,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }
}
