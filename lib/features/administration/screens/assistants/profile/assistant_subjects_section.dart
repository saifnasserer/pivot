import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/models/subject_model.dart';
import 'package:pivot/features/subjects/providers/legacy_subject_provider.dart';
import 'package:pivot/features/administration/providers/sections_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/models/section_card.dart';

class AssistantSubjectsSection extends ConsumerStatefulWidget {
  final UserProfile userProfile;
  final UserProfile? loggedInUser;
  final Subject? targetSubject;
  final Function(Subject?)? onCurrentSubjectChanged;

  const AssistantSubjectsSection({
    super.key,
    required this.userProfile,
    this.loggedInUser,
    this.targetSubject,
    this.onCurrentSubjectChanged,
  });

  @override
  ConsumerState<AssistantSubjectsSection> createState() =>
      _AssistantSubjectsSectionState();
}

class _AssistantSubjectsSectionState
    extends ConsumerState<AssistantSubjectsSection>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<Subject> _previousSubjects = [];
  String? _previousAssistantId;
  Subject? _preservedTargetSubject;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 0, vsync: this);
    _previousAssistantId = widget.userProfile.id;
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
    final subjectProvider = ref.read(legacySubjectProviderProvider);
    final subjects = subjectProvider.filteredSubjects;
    final currentAssistantId = widget.userProfile.id;

    // Check if assistant has changed
    if (_previousAssistantId != currentAssistantId) {
      _previousAssistantId = currentAssistantId;
      print('Assistant changed to $currentAssistantId');
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
            _loadSectionsForSubject(targetIndex);
            _notifyCurrentSubjectChanged();
            // Clear preserved target subject after using it
            _preservedTargetSubject = null;
          }
        });
      }
    }
  }

  void _updateTabController() {
    final subjectProvider = ref.read(legacySubjectProviderProvider);
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

      // Load initial sections for the selected subject
      if (subjects.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _loadSectionsForSubject(initialIndex);
            _notifyCurrentSubjectChanged();
            // Clear preserved target subject after tab controller is set
            if (_preservedTargetSubject != null) {
              _preservedTargetSubject = null;
            }
          }
        });
      }
    } else if (widget.targetSubject != null) {
      // If subjects haven't changed but we have a target subject, switch to it
      final targetIndex = subjects.indexWhere(
        (subject) => subject.id == widget.targetSubject!.id,
      );
      if (targetIndex != -1 && _tabController.index != targetIndex) {
        _tabController.animateTo(targetIndex);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _loadSectionsForSubject(targetIndex);
            _notifyCurrentSubjectChanged();
          }
        });
      }
    }
  }

  void _onTabChanged() {
    // Only load sections if the tab actually changed and we're not in the middle of a swipe
    if (_tabController.indexIsChanging) {
      return;
    }

    // Load sections for the current subject
    _loadSectionsForSubject(_tabController.index);

    // Notify parent about current subject change
    _notifyCurrentSubjectChanged();
  }

  void _notifyCurrentSubjectChanged() {
    final subjectProvider = ref.read(legacySubjectProviderProvider);
    final subjects = subjectProvider.filteredSubjects;

    if (subjects.isNotEmpty && _tabController.index < subjects.length) {
      final currentSubject = subjects[_tabController.index];
      widget.onCurrentSubjectChanged?.call(currentSubject);
    } else {
      widget.onCurrentSubjectChanged?.call(null);
    }
  }

  Subject? getCurrentSubject() {
    final subjectProvider = ref.read(legacySubjectProviderProvider);
    final subjects = subjectProvider.filteredSubjects;

    if (subjects.isNotEmpty && _tabController.index < subjects.length) {
      return subjects[_tabController.index];
    }
    return null;
  }

  Future<void> _loadSectionsForSubject(int index) async {
    final subjectProvider = ref.read(legacySubjectProviderProvider);
    final subjects = subjectProvider.filteredSubjects;

    if (subjects.isNotEmpty && index < subjects.length) {
      final assistantId = widget.userProfile.id;

      // Use the SectionProvider to load sections for this assistant
      await ref
          .read(sectionsProvider.notifier)
          .fetchSectionsForAssistant(assistantId);
    }
  }

  Widget _buildSubjectContent(Subject subject) {
    final sectionsState = ref.watch(sectionsProvider);
    final sections =
        sectionsState.sections
            .where((section) => section.subjectId == subject.id)
            .toList();

    if (sectionsState.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('جاري تحميل السكاشن...'),
          ],
        ),
      );
    }

    if (sectionsState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            SizedBox(height: 16),
            Text(
              'خطأ: ${sectionsState.error}',
              style: TextStyle(color: Colors.red.shade600),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadSectionsForSubject(_tabController.index),
              child: Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (sections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.class_outlined, size: 48, color: Colors.grey.shade400),
            SizedBox(height: 16),
            Text(
              'لا توجد سكاشن في هذه المادة',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'سيتم إضافة السكاشن قريباً',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadSectionsForSubject(_tabController.index);
      },
      child: ListView.builder(
        itemCount: sections.length,
        itemBuilder:
            (context, index) => SectionCard(
              section: sections[index],
              subjectName: subject.name,
              isCurrentUserSection:
                  widget.loggedInUser?.id == widget.userProfile.id,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subjectProvider = ref.watch(legacySubjectProviderProvider);
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
              'يجب إضافة مواد للمعيد أولاً',
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
