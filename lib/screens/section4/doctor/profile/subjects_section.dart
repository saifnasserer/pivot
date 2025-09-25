import 'package:flutter/material.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/models/subject_model.dart';
import 'package:pivot/providers/doctor_subject_provider.dart';
import 'package:pivot/providers/subject_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/models/material_links_widget.dart';
import 'package:provider/provider.dart';

class SubjectsSection extends StatefulWidget {
  final UserProfile userProfile;
  final UserProfile? loggedInUser;
  final Function(Subject?)? onCurrentSubjectChanged;

  const SubjectsSection({
    super.key,
    required this.userProfile,
    this.loggedInUser,
    this.onCurrentSubjectChanged,
  });

  @override
  State<SubjectsSection> createState() => _SubjectsSectionState();
}

class _SubjectsSectionState extends State<SubjectsSection>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<Subject> _previousSubjects = [];
  String? _previousDoctorId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 0, vsync: this);
    _previousDoctorId = widget.userProfile.id;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkForUpdates();
  }

  void _checkForUpdates() {
    final subjectProvider = context.watch<SubjectProvider>();
    final subjects = subjectProvider.filteredSubjects;
    final currentDoctorId = widget.userProfile.id;

    // Check if doctor has changed
    if (_previousDoctorId != currentDoctorId) {
      _previousDoctorId = currentDoctorId;
      print('Doctor changed to $currentDoctorId');
    }

    // Check if subjects have changed - more efficient comparison
    bool subjectsChanged = false;
    if (_previousSubjects.length != subjects.length) {
      subjectsChanged = true;
    } else {
      // Compare only IDs for efficiency
      for (int i = 0; i < subjects.length; i++) {
        if (i >= _previousSubjects.length ||
            subjects[i].id != _previousSubjects[i].id) {
          subjectsChanged = true;
          break;
        }
      }
    }

    if (subjectsChanged) {
      _previousSubjects = List.from(subjects);
      _updateTabController();
      print('Subjects changed, updating tab controller');
    }
  }

  void _updateTabController() {
    final subjectProvider = context.read<SubjectProvider>();
    final subjects = subjectProvider.filteredSubjects;

    // Only update if the number of subjects actually changed
    if (_tabController.length != subjects.length) {
      // Remove the old listener before disposing
      _tabController.removeListener(_onTabChanged);
      _tabController.dispose();

      _tabController = TabController(
        length: subjects.length,
        vsync: this,
        initialIndex: subjects.isNotEmpty ? subjects.length - 1 : 0,
      );

      // Add listener to detect tab changes (including swiping)
      _tabController.addListener(_onTabChanged);

      // Load initial lectures for the last subject only if we have subjects
      if (subjects.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _loadLecturesForSubject(subjects.length - 1);
            _notifyCurrentSubjectChanged();
          }
        });
      }
    }
  }

  void _onTabChanged() {
    // Only load lectures if the tab actually changed and we're not in the middle of a swipe
    if (_tabController.indexIsChanging) {
      return;
    }

    // Load lectures for the current subject
    _loadLecturesForSubject(_tabController.index);

    // Notify parent about current subject change
    _notifyCurrentSubjectChanged();
  }

  void _notifyCurrentSubjectChanged() {
    final subjectProvider = context.read<SubjectProvider>();
    final subjects = subjectProvider.filteredSubjects;

    if (subjects.isNotEmpty && _tabController.index < subjects.length) {
      final currentSubject = subjects[_tabController.index];
      widget.onCurrentSubjectChanged?.call(currentSubject);
    } else {
      widget.onCurrentSubjectChanged?.call(null);
    }
  }

  Subject? getCurrentSubject() {
    final subjectProvider = context.read<SubjectProvider>();
    final subjects = subjectProvider.filteredSubjects;

    if (subjects.isNotEmpty && _tabController.index < subjects.length) {
      return subjects[_tabController.index];
    }
    return null;
  }

  Future<void> _loadLecturesForSubject(int index) async {
    final subjectProvider = context.read<SubjectProvider>();
    final subjects = subjectProvider.filteredSubjects;

    if (subjects.isNotEmpty && index < subjects.length) {
      final subject = subjects[index];
      final subjectId = subject.id;
      final doctorId = widget.userProfile.id;

      // Use the unified DoctorSubjectProvider
      final doctorSubjectProvider = context.read<DoctorSubjectProvider>();
      await doctorSubjectProvider.fetchLecturesForSubject(doctorId, subjectId);
    }
  }

  Widget _buildSubjectContent(Subject subject) {
    final subjectId = subject.id;
    final doctorSubjectProvider = context.watch<DoctorSubjectProvider>();
    final lectures = doctorSubjectProvider.getLecturesForSubject(subjectId);
    final isLoading = doctorSubjectProvider.isSubjectLoading(subjectId);
    final error = doctorSubjectProvider.getSubjectError(subjectId);

    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('جاري تحميل المحاضرات...'),
          ],
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            SizedBox(height: 16),
            Text(
              'خطأ: $error',
              style: TextStyle(color: Colors.red.shade600),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadLecturesForSubject(_tabController.index),
              child: Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (lectures.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16),
            Text(
              'لا توجد محاضرات في هذه المادة',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'اضغط على زر الإضافة لإنشاء محاضرة جديدة',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final subjectProvider = context.read<SubjectProvider>();
        final subjects = subjectProvider.filteredSubjects;
        if (subjects.isNotEmpty && _tabController.index < subjects.length) {
          final subject = subjects[_tabController.index];
          final doctorSubjectProvider = context.read<DoctorSubjectProvider>();
          await doctorSubjectProvider.refreshLecturesForSubject(
            widget.userProfile.id,
            subject.id,
          );
        }
      },
      child: ListView.builder(
        // padding: EdgeInsets.all(Responsive.space(context, size: Space.medium)),
        itemCount: lectures.length,
        itemBuilder:
            (context, index) => SubjectModel(
              lecture: lectures[index],
              canEdit:
                  widget.loggedInUser?.role != 'Student' &&
                  widget.loggedInUser?.role != 'miniProfessor',
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subjectProvider = context.watch<SubjectProvider>();
    final subjects = subjectProvider.filteredSubjects;

    // Safety check: ensure TabController length matches subjects length
    if (_tabController.length != subjects.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _updateTabController();
        }
      });
    }

    if (subjects.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(Responsive.space(context, size: Space.medium)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 64, color: Colors.grey.shade400),
            SizedBox(height: 16),
            Text(
              'لا توجد مواد متاحة',
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.medium),
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'يجب إضافة مواد للدكتور أولاً',
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.small),
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          // TabBar for subjects
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(
                Responsive.space(context, size: Space.large),
              ),
              border: Border.all(color: Colors.grey.shade200, width: 1),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  Responsive.space(context, size: Space.large),
                ),
                color: Colors.black,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.black,
              labelStyle: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.medium),
                fontWeight: FontWeight.w600,
                fontFamily: 'NotoSansArabic',
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.medium),
                fontWeight: FontWeight.w500,
                fontFamily: 'NotoSansArabic',
              ),
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.space(context, size: Space.medium),
              ),
              tabs: subjects.map((subject) => Tab(text: subject.name)).toList(),
            ),
          ),
          SizedBox(height: Responsive.space(context, size: Space.medium)),

          // TabBarView for subject content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children:
                  subjects
                      .map((subject) => _buildSubjectContent(subject))
                      .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
