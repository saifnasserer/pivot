import 'package:flutter/material.dart';
import 'package:pivot/models/subject_model.dart';
import 'package:pivot/providers/guide_provider.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/providers/subject_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pivot/widgets/no_internet_message.dart';
import 'dart:developer' as developer;

class SubjectSelectionScreen extends StatefulWidget {
  final List<String> previouslySelectedIds;
  final String? targetUserId; // For Super Admin to edit other users' subjects
  final String? targetUserRole; // Role of the target user being edited

  const SubjectSelectionScreen({
    super.key,
    required this.previouslySelectedIds,
    this.targetUserId,
    this.targetUserRole,
  });

  @override
  _SubjectSelectionScreenState createState() => _SubjectSelectionScreenState();
}

class _SubjectSelectionScreenState extends State<SubjectSelectionScreen> {
  bool _isSaving = false;
  bool _saveSuccess = false;
  final Map<int, bool> _expandedState = {};
  late Set<String> _selectedSubjectIds;
  bool _showEnglish = false; // Language toggle
  static const int maxHours = 18; // Maximum allowed hours

  // Search functionality
  bool _isSearchMode = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    developer.log(
      'SubjectSelectionScreen: initState called',
      name: 'SubjectSelection',
    );
    developer.log(
      'SubjectSelectionScreen: previouslySelectedIds = ${widget.previouslySelectedIds}',
      name: 'SubjectSelection',
    );
    developer.log(
      'SubjectSelectionScreen: targetUserId = ${widget.targetUserId}',
      name: 'SubjectSelection',
    );
    developer.log(
      'SubjectSelectionScreen: targetUserRole = ${widget.targetUserRole}',
      name: 'SubjectSelection',
    );

    _selectedSubjectIds = Set<String>.from(widget.previouslySelectedIds);
    developer.log(
      'SubjectSelectionScreen: _selectedSubjectIds initialized with ${_selectedSubjectIds.length} items',
      name: 'SubjectSelection',
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      developer.log(
        'SubjectSelectionScreen: Post-frame callback executing',
        name: 'SubjectSelection',
      );
      try {
        // For subject selection, we need ALL subjects, not just user's subjects
        final subjectProvider = Provider.of<SubjectProvider>(
          context,
          listen: false,
        );
        developer.log(
          'SubjectSelectionScreen: Calling fetchAllSubjects for subject selection',
          name: 'SubjectSelection',
        );
        subjectProvider.fetchAllSubjects();
        developer.log(
          'SubjectSelectionScreen: fetchAllSubjects called',
          name: 'SubjectSelection',
        );

        Provider.of<GuideProvider>(context, listen: false).fetchGuideContent();
        developer.log(
          'SubjectSelectionScreen: fetchGuideContent called',
          name: 'SubjectSelection',
        );

        // If targetUserId is provided, fetch all users for Super Admin functionality
        if (widget.targetUserId != null) {
          developer.log(
            'SubjectSelectionScreen: Fetching all users for Super Admin',
            name: 'SubjectSelection',
          );
          Provider.of<UserProfileProvider>(
            context,
            listen: false,
          ).fetchAllUsers();
        }
      } catch (e) {
        developer.log(
          'SubjectSelectionScreen: Error in post-frame callback: $e',
          name: 'SubjectSelection',
        );
      }
    });
  }

  @override
  void dispose() {
    developer.log(
      'SubjectSelectionScreen: dispose called',
      name: 'SubjectSelection',
    );
    developer.log(
      'SubjectSelectionScreen: Final selected subjects count: ${_selectedSubjectIds.length}',
      name: 'SubjectSelection',
    );
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleSearchMode() {
    developer.log(
      'SubjectSelectionScreen: _toggleSearchMode called, current _isSearchMode = $_isSearchMode',
      name: 'SubjectSelection',
    );
    setState(() {
      _isSearchMode = !_isSearchMode;
      if (_isSearchMode) {
        _searchFocusNode.requestFocus();
        developer.log(
          'SubjectSelectionScreen: Search mode enabled, focus requested',
          name: 'SubjectSelection',
        );
      } else {
        _searchQuery = '';
        _searchController.clear();
        _searchFocusNode.unfocus();
        developer.log(
          'SubjectSelectionScreen: Search mode disabled, query cleared',
          name: 'SubjectSelection',
        );
      }
    });
  }

  List<Subject> _filterSubjects(List<Subject> subjects) {
    if (_searchQuery.isEmpty) {
      developer.log(
        'SubjectSelectionScreen: _filterSubjects - no search query, returning all ${subjects.length} subjects',
        name: 'SubjectSelection',
      );
      return subjects;
    }

    developer.log(
      'SubjectSelectionScreen: _filterSubjects - searching for "$_searchQuery" in ${subjects.length} subjects',
      name: 'SubjectSelection',
    );
    final filtered =
        subjects.where((subject) {
          final query = _searchQuery.toLowerCase();
          final name =
              _showEnglish
                  ? subject.englishName.toLowerCase()
                  : subject.name.toLowerCase();
          final departments = subject.departments.join(' ').toLowerCase();

          return name.contains(query) || departments.contains(query);
        }).toList();

    developer.log(
      'SubjectSelectionScreen: _filterSubjects - found ${filtered.length} matching subjects',
      name: 'SubjectSelection',
    );
    return filtered;
  }

  int _calculateTotalHours() {
    final subjectProvider = Provider.of<SubjectProvider>(
      context,
      listen: false,
    );
    int totalHours = 0;
    developer.log(
      'SubjectSelectionScreen: _calculateTotalHours - calculating for ${_selectedSubjectIds.length} selected subjects',
      name: 'SubjectSelection',
    );

    for (final subjectId in _selectedSubjectIds) {
      final subject = subjectProvider.allSubjects.firstWhere(
        (s) => s.id == subjectId,
        orElse:
            () => Subject(
              id: '',
              name: '',
              hours: 0,
              year: 1,
              departments: [],
              englishName: '',
            ),
      );
      totalHours += subject.hours;
      developer.log(
        'SubjectSelectionScreen: _calculateTotalHours - subject $subjectId (${subject.name}) has ${subject.hours} hours, total now: $totalHours',
        name: 'SubjectSelection',
      );
    }

    developer.log(
      'SubjectSelectionScreen: _calculateTotalHours - final total: $totalHours hours',
      name: 'SubjectSelection',
    );
    return totalHours;
  }

  bool _canAddSubject(Subject subject) {
    if (_selectedSubjectIds.contains(subject.id)) {
      developer.log(
        'SubjectSelectionScreen: _canAddSubject - subject ${subject.id} (${subject.name}) already selected',
        name: 'SubjectSelection',
      );
      return true;
    }
    final currentHours = _calculateTotalHours();
    final canAdd = (currentHours + subject.hours) <= maxHours;
    developer.log(
      'SubjectSelectionScreen: _canAddSubject - subject ${subject.id} (${subject.name}) with ${subject.hours} hours, current: $currentHours, max: $maxHours, canAdd: $canAdd',
      name: 'SubjectSelection',
    );
    return canAdd;
  }

  void _toggleSubjectSelection(Subject subject) {
    developer.log(
      'SubjectSelectionScreen: _toggleSubjectSelection called for subject ${subject.id} (${subject.name})',
      name: 'SubjectSelection',
    );
    developer.log(
      'SubjectSelectionScreen: _toggleSubjectSelection - current selected count: ${_selectedSubjectIds.length}',
      name: 'SubjectSelection',
    );

    setState(() {
      if (_selectedSubjectIds.contains(subject.id)) {
        _selectedSubjectIds.remove(subject.id);
        developer.log(
          'SubjectSelectionScreen: _toggleSubjectSelection - removed subject ${subject.id} (${subject.name})',
          name: 'SubjectSelection',
        );
      } else {
        if (_canAddSubject(subject)) {
          _selectedSubjectIds.add(subject.id);
          developer.log(
            'SubjectSelectionScreen: _toggleSubjectSelection - added subject ${subject.id} (${subject.name})',
            name: 'SubjectSelection',
          );
        } else {
          developer.log(
            'SubjectSelectionScreen: _toggleSubjectSelection - cannot add subject ${subject.id} (${subject.name}), over limit',
            name: 'SubjectSelection',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'لا يمكن إضافة هذه المادة. الحد الأقصى للساعات هو $maxHours ساعة',
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    });

    developer.log(
      'SubjectSelectionScreen: _toggleSubjectSelection - final selected count: ${_selectedSubjectIds.length}',
      name: 'SubjectSelection',
    );
  }

  Widget _buildSubjectCard(Subject subject) {
    final isSelected = _selectedSubjectIds.contains(subject.id);
    return Container(
      margin: EdgeInsets.only(
        bottom: Responsive.space(context, size: Space.medium),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? Colors.black : Colors.grey[200]!,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _toggleSubjectSelection(subject),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: Responsive.padding(context, size: Space.large),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _showEnglish ? subject.englishName : subject.name,
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
                            'القسم: ${subject.departments.join(', ')}',
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                              fontSize: Responsive.text(
                                context,
                                size: TextSize.small,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: Responsive.space(context, size: Space.small),
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
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? Colors.black : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? Colors.black : Colors.grey[400]!,
                    width: 2,
                  ),
                ),
                child:
                    isSelected
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
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

        return Container(
          padding: Responsive.padding(context, size: Space.large),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
                            width: Responsive.space(
                              context,
                              size: Space.medium,
                            ),
                          ),
                          Text(
                            'لائحة كلية حاصلة على الشهادة الجامعية',
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
                                  fontSize: Responsive.text(
                                    context,
                                    size: TextSize.medium,
                                  ),
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
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
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubjectsList() {
    return Consumer<SubjectProvider>(
      builder: (context, subjectProvider, child) {
        developer.log(
          'SubjectSelectionScreen: _buildSubjectsList - isLoading: ${subjectProvider.isLoading}, error: ${subjectProvider.error}, subjects count: ${subjectProvider.allSubjects.length}',
          name: 'SubjectSelection',
        );

        if (subjectProvider.isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Colors.black),
                SizedBox(height: Responsive.space(context, size: Space.medium)),
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
                SizedBox(height: Responsive.space(context, size: Space.medium)),
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
                SizedBox(height: Responsive.space(context, size: Space.medium)),
                Text(
                  'لا توجد مواد متاحة',
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.medium),
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        final subjects = subjectProvider.allSubjects;
        final filteredSubjects = _filterSubjects(subjects);
        developer.log(
          'SubjectSelectionScreen: _buildSubjectsList - filtered subjects count: ${filteredSubjects.length}',
          name: 'SubjectSelection',
        );

        if (_searchQuery.isNotEmpty && filteredSubjects.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                SizedBox(height: Responsive.space(context, size: Space.medium)),
                Text(
                  'لا توجد نتائج للبحث',
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.medium),
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: Responsive.space(context, size: Space.small)),
                Text(
                  'جرب البحث بكلمات مختلفة',
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
        for (final subject in filteredSubjects) {
          (groupedSubjects[subject.year] ??= []).add(subject);
        }
        final sortedYears = groupedSubjects.keys.toList()..sort();
        developer.log(
          'SubjectSelectionScreen: _buildSubjectsList - grouped subjects by year: ${groupedSubjects.map((k, v) => MapEntry(k, v.length))}',
          name: 'SubjectSelection',
        );
        developer.log(
          'SubjectSelectionScreen: _buildSubjectsList - sorted years: $sortedYears',
          name: 'SubjectSelection',
        );

        return ListView.builder(
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
                                  borderRadius: BorderRadius.circular(8),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                      height: Responsive.space(context, size: Space.medium),
                    ),
                    ...subjectsInYear.map(
                      (subject) => _buildSubjectCard(subject),
                    ),
                  ],
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
      child: NoInternetMessage(
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title:
                _isSearchMode
                    ? TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'ابحث في المواد...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.medium,
                          ),
                        ),
                      ),
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.medium,
                        ),
                        fontWeight: FontWeight.w600,
                      ),
                    )
                    : Text(
                      'اختار كورساتك',
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.heading,
                        ),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            centerTitle: true,
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black),
            leading:
                _isSearchMode
                    ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: _toggleSearchMode,
                    )
                    : null,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(40),
              child: Consumer<SubjectProvider>(
                builder: (context, subjectProvider, child) {
                  final totalHours = _calculateTotalHours();
                  final isOverLimit = totalHours > maxHours;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: isOverLimit ? Colors.red : Colors.grey[600],
                        ),
                        SizedBox(
                          width: Responsive.space(context, size: Space.small),
                        ),
                        Text(
                          'الساعات المختارة: $totalHours / $maxHours',
                          style: TextStyle(
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.small,
                            ),
                            fontWeight: FontWeight.w500,
                            color: isOverLimit ? Colors.red : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            actions: [
              if (!_isSearchMode) ...[
                IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: 'البحث في المواد',
                  onPressed: _toggleSearchMode,
                ),
                IconButton(
                  icon: Icon(_showEnglish ? Icons.language : Icons.translate),
                  tooltip: _showEnglish ? 'عرض بالعربية' : 'Show in English',
                  onPressed: () {
                    setState(() {
                      _showEnglish = !_showEnglish;
                    });
                  },
                ),
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
                                  builder:
                                      (_) => Directionality(
                                        textDirection: TextDirection.rtl,
                                        child: _buildGuideSection(),
                                      ),
                                );
                              },
                    );
                  },
                ),
              ],
            ],
          ),
          body: _buildSubjectsList(),
          floatingActionButton: Container(
            decoration: BoxDecoration(
              color:
                  _saveSuccess
                      ? Colors.green
                      : _calculateTotalHours() > maxHours
                      ? Colors.red
                      : Colors.black,
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
            child: FloatingActionButton(
              heroTag: 'subject_selection_fab',
              onPressed:
                  _isSaving || _calculateTotalHours() > maxHours
                      ? null
                      : () async {
                        developer.log(
                          'SubjectSelectionScreen: Save button pressed',
                          name: 'SubjectSelection',
                        );
                        developer.log(
                          'SubjectSelectionScreen: Selected subjects count: ${_selectedSubjectIds.length}',
                          name: 'SubjectSelection',
                        );
                        developer.log(
                          'SubjectSelectionScreen: Selected subject IDs: $_selectedSubjectIds',
                          name: 'SubjectSelection',
                        );

                        setState(() {
                          _isSaving = true;
                          _saveSuccess = false;
                        });

                        bool success = false;
                        try {
                          final userProfileProvider =
                              Provider.of<UserProfileProvider>(
                                context,
                                listen: false,
                              );
                          final subjectProvider = Provider.of<SubjectProvider>(
                            context,
                            listen: false,
                          );

                          final userRole =
                              userProfileProvider.loggedInUserProfile?.role;
                          developer.log(
                            'SubjectSelectionScreen: Current user role: $userRole',
                            name: 'SubjectSelection',
                          );
                          developer.log(
                            'SubjectSelectionScreen: Target user ID: ${widget.targetUserId}',
                            name: 'SubjectSelection',
                          );
                          developer.log(
                            'SubjectSelectionScreen: Target user role: ${widget.targetUserRole}',
                            name: 'SubjectSelection',
                          );

                          UserProfile? updatedProfile;

                          // If targetUserId is provided, Super Admin is editing another user's subjects
                          if (widget.targetUserId != null &&
                              userRole == 'Super Admin') {
                            developer.log(
                              'SubjectSelectionScreen: Super Admin editing another user\'s subjects',
                              name: 'SubjectSelection',
                            );
                            // Use the targetUserRole parameter instead of fetching from allUsers
                            final targetUserRole = widget.targetUserRole;
                            developer.log(
                              'SubjectSelectionScreen: Target user role: $targetUserRole',
                              name: 'SubjectSelection',
                            );

                            if (targetUserRole == 'Student' ||
                                targetUserRole == 'Admin') {
                              developer.log(
                                'SubjectSelectionScreen: Updating enrolled subjects for target user',
                                name: 'SubjectSelection',
                              );
                              await userProfileProvider
                                  .updateUserEnrolledSubjects(
                                    widget.targetUserId!,
                                    _selectedSubjectIds.toList(),
                                  );
                            } else if (targetUserRole == 'Professor' ||
                                targetUserRole == 'miniProfessor' ||
                                targetUserRole == 'Doctor') {
                              developer.log(
                                'SubjectSelectionScreen: Updating teaching subjects for target user',
                                name: 'SubjectSelection',
                              );
                              await userProfileProvider
                                  .updateUserTeachingSubjects(
                                    widget.targetUserId!,
                                    _selectedSubjectIds.toList(),
                                  );
                            } else {
                              developer.log(
                                'SubjectSelectionScreen: Unknown target user role: $targetUserRole',
                                name: 'SubjectSelection',
                              );
                              throw Exception(
                                'Unknown target user role: $targetUserRole',
                              );
                            }

                            // Update the UI after Super Admin changes
                            developer.log(
                              'SubjectSelectionScreen: Fetching updated data after Super Admin changes',
                              name: 'SubjectSelection',
                            );
                            await userProfileProvider.fetchAllUsers();
                            await subjectProvider.fetchAllSubjects();
                            success = true;
                          } else {
                            // Normal flow - user editing their own subjects
                            developer.log(
                              'SubjectSelectionScreen: Normal flow - user editing their own subjects',
                              name: 'SubjectSelection',
                            );

                            if (userRole == 'Student' ||
                                userRole == 'Admin' ||
                                userRole == 'Super Admin') {
                              developer.log(
                                'SubjectSelectionScreen: Updating enrolled subjects for current user',
                                name: 'SubjectSelection',
                              );
                              updatedProfile = await userProfileProvider
                                  .updateEnrolledSubjects(
                                    _selectedSubjectIds.toList(),
                                  );
                            } else if (userRole == 'Professor' ||
                                userRole == 'miniProfessor' ||
                                userRole == 'Doctor') {
                              developer.log(
                                'SubjectSelectionScreen: Updating teaching subjects for current user',
                                name: 'SubjectSelection',
                              );
                              updatedProfile = await userProfileProvider
                                  .updateTeachingSubjects(
                                    _selectedSubjectIds.toList(),
                                  );
                            } else {
                              // Handle unknown role
                              developer.log(
                                'SubjectSelectionScreen: Unknown user role: $userRole',
                                name: 'SubjectSelection',
                              );
                              throw Exception('Unknown user role: $userRole');
                            }

                            // After updating subjects, fetch the latest user profile to ensure
                            // the UI reflects the changes upon returning to the previous screen.
                            developer.log(
                              'SubjectSelectionScreen: Loading latest user profile',
                              name: 'SubjectSelection',
                            );
                            await userProfileProvider.loadLoggedInUserProfile();
                            success = true;
                          }
                        } catch (e) {
                          developer.log(
                            'SubjectSelectionScreen: Error during save operation: $e',
                            name: 'SubjectSelection',
                          );
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
                            if (success) {
                              developer.log(
                                'SubjectSelectionScreen: Save operation completed successfully',
                                name: 'SubjectSelection',
                              );
                              setState(() {
                                _isSaving = false;
                                _saveSuccess = true;
                              });
                              await Future.delayed(
                                const Duration(milliseconds: 800),
                              );
                              if (mounted) {
                                developer.log(
                                  'SubjectSelectionScreen: Navigating back with success result',
                                  name: 'SubjectSelection',
                                );
                                // Return true to indicate success, allowing the previous screen to react.
                                Navigator.pop(context, true);
                              }
                            } else {
                              developer.log(
                                'SubjectSelectionScreen: Save operation failed',
                                name: 'SubjectSelection',
                              );
                              setState(() {
                                _isSaving = false;
                              });
                            }
                          }
                        }
                      },
              backgroundColor: Colors.transparent,
              elevation: 0,
              child:
                  _isSaving || _calculateTotalHours() > maxHours
                      ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : _saveSuccess
                      ? const Icon(Icons.done_all, color: Colors.white)
                      : const Icon(Icons.check_rounded, color: Colors.white),
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
        ),
      ),
    );
  }
}
