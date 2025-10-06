import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/models/subject_model.dart';
import 'package:pivot/services/doctor_subject_service.dart';
import 'package:pivot/features/subjects/providers/subject_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/models/material_links_widget.dart';

class SubjectsSection extends ConsumerStatefulWidget {
  final UserProfile userProfile;
  final UserProfile? loggedInUser;
  final Subject? targetSubject;
  final Function(Subject?)? onCurrentSubjectChanged;
  final Function(VoidCallback)? onRefreshCallbackSet;

  const SubjectsSection({
    super.key,
    required this.userProfile,
    this.loggedInUser,
    this.targetSubject,
    this.onCurrentSubjectChanged,
    this.onRefreshCallbackSet,
  });

  @override
  ConsumerState<SubjectsSection> createState() => _SubjectsSectionState();
}

class _SubjectsSectionState extends ConsumerState<SubjectsSection>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<Subject> _previousSubjects = [];
  String? _previousDoctorId;
  Subject? _preservedTargetSubject;

  // State for lectures
  final Map<String, List<dynamic>> _lecturesBySubject = {};
  final Map<String, bool> _loadingBySubject = {};
  final Map<String, String?> _errorBySubject = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 0, vsync: this);
    _previousDoctorId = widget.userProfile.id;

    // Provide refresh callback to parent
    widget.onRefreshCallbackSet?.call(refreshCurrentSubjectLectures);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Preserve target subject if it's provided and we don't have one yet
    if (widget.targetSubject != null && _preservedTargetSubject == null) {
      _preservedTargetSubject = widget.targetSubject;
    }

    _checkForUpdates();
  }

  void _checkForUpdates() {
    final subjectProvider = ref.watch(SubjectProviderProvider);
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
    } else if (_preservedTargetSubject != null) {
      // If subjects haven't changed but we have a preserved target subject, ensure we're on the right tab
      final targetIndex = subjects.indexWhere(
        (subject) => subject.id == _preservedTargetSubject!.id,
      );
      if (targetIndex != -1 && _tabController.index != targetIndex) {
        print('Switching to preserved target subject at index $targetIndex');
        _tabController.animateTo(targetIndex);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _loadLecturesForSubject(targetIndex);
            _notifyCurrentSubjectChanged();
            // Clear preserved target subject after using it
            _preservedTargetSubject = null;
          }
        });
      }
    }
  }

  void _updateTabController() {
    final subjectProvider = ref.read(SubjectProviderProvider);
    final subjects = subjectProvider.filteredSubjects;

    // Only update if the number of subjects actually changed
    if (_tabController.length != subjects.length) {
      // Remove the old listener before disposing
      _tabController.removeListener(_onTabChanged);
      _tabController.dispose();

      // Determine initial index - prioritize preserved target subject if available
      int initialIndex = subjects.isNotEmpty ? subjects.length - 1 : 0;
      if (_preservedTargetSubject != null) {
        final targetIndex = subjects.indexWhere(
          (subject) => subject.id == _preservedTargetSubject!.id,
        );
        if (targetIndex != -1) {
          initialIndex = targetIndex;
          print(
            'Setting initial index to $targetIndex for preserved target subject',
          );
        }
      } else if (widget.targetSubject != null) {
        final targetIndex = subjects.indexWhere(
          (subject) => subject.id == widget.targetSubject!.id,
        );
        if (targetIndex != -1) {
          initialIndex = targetIndex;
          print(
            'Setting initial index to $targetIndex for widget target subject',
          );
        }
      }

      _tabController = TabController(
        length: subjects.length,
        vsync: this,
        initialIndex: initialIndex,
      );

      // Add listener to detect tab changes (including swiping)
      _tabController.addListener(_onTabChanged);

      // Load initial lectures for the selected subject
      if (subjects.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _loadLecturesForSubject(initialIndex);
            _notifyCurrentSubjectChanged();
            // Clear preserved target subject after tab controller is set
            if (_preservedTargetSubject != null) {
              _preservedTargetSubject = null;
            }
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
    final subjectProvider = ref.read(SubjectProviderProvider);
    final subjects = subjectProvider.filteredSubjects;

    if (subjects.isNotEmpty && _tabController.index < subjects.length) {
      final currentSubject = subjects[_tabController.index];
      widget.onCurrentSubjectChanged?.call(currentSubject);
    } else {
      widget.onCurrentSubjectChanged?.call(null);
    }
  }

  Subject? getCurrentSubject() {
    final subjectProvider = ref.read(SubjectProviderProvider);
    final subjects = subjectProvider.filteredSubjects;

    if (subjects.isNotEmpty && _tabController.index < subjects.length) {
      return subjects[_tabController.index];
    }
    return null;
  }

  Future<void> _loadLecturesForSubject(int index) async {
    final subjectProvider = ref.read(SubjectProviderProvider);
    final subjects = subjectProvider.filteredSubjects;

    if (subjects.isNotEmpty && index < subjects.length) {
      final subject = subjects[index];
      final subjectId = subject.id;
      final doctorId = widget.userProfile.id;

      // Set loading state
      setState(() {
        _loadingBySubject[subjectId] = true;
        _errorBySubject[subjectId] = null;
      });

      try {
        // Fetch lectures using service
        final service = DoctorSubjectService();
        final lectures = await service.getLecturesForDoctorSubject(
          doctorId,
          subjectId,
        );

        if (mounted) {
          setState(() {
            _lecturesBySubject[subjectId] = lectures;
            _loadingBySubject[subjectId] = false;
          });
        }
      } catch (e) {
        print('Error loading lectures for subject $subjectId: $e');
        if (mounted) {
          setState(() {
            _errorBySubject[subjectId] = e.toString();
            _loadingBySubject[subjectId] = false;
          });
        }
      }
    }
  }

  // Public method to refresh current subject's lectures
  Future<void> refreshCurrentSubjectLectures() async {
    if (_tabController.index >= 0) {
      await _loadLecturesForSubject(_tabController.index);
    }
  }

  Widget _buildSubjectContent(Subject subject) {
    final subjectId = subject.id;
    // Get lectures from state
    final lectures = _lecturesBySubject[subjectId] ?? [];
    final isLoading = _loadingBySubject[subjectId] ?? false;
    final error = _errorBySubject[subjectId];

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
        await _loadLecturesForSubject(_tabController.index);
      },
      child: ListView.builder(
        // padding: EdgeInsets.all(Responsive.space(context, size: Space.medium)),
        itemCount: lectures.length,
        itemBuilder:
            (context, index) => SubjectModel(
              lecture: lectures[index],
              subjectName: subject.name,
              canEdit:
                  widget.loggedInUser?.role != 'Student' &&
                  widget.loggedInUser?.role != 'miniProfessor',
              onLectureDeleted: () {
                // Refresh the current subject's lectures after deletion
                _loadLecturesForSubject(_tabController.index);
              },
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subjectProvider = ref.watch(SubjectProviderProvider);
    final subjects = subjectProvider.filteredSubjects;

    // Safety check: ensure TabController length matches subjects length
    if (_tabController.length != subjects.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _updateTabController();
        }
      });

      // Return loading indicator while TabController is being updated
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
        ),
      );
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
