import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/models/subject_model.dart';
import 'package:pivot/features/subjects/providers/subject_provider.dart';
import 'package:pivot/features/administration/providers/sections_provider.dart';
import 'package:pivot/features/media/screens/material_links_screen.dart';
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
    // Initialize with length 1 to prevent mismatch errors
    _tabController = TabController(length: 1, vsync: this);
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
    final subjectProvider = ref.read(SubjectProviderProvider);
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
    final subjectProvider = ref.read(SubjectProviderProvider);
    final subjects = subjectProvider.filteredSubjects;

    // Only update if the number of subjects actually changed
    if (_tabController.length != subjects.length) {
      // Remove the old listener before disposing
      _tabController.removeListener(_onTabChanged);
      _tabController.dispose();

      // Ensure we have at least length 1 to prevent mismatch errors
      final controllerLength = subjects.isEmpty ? 1 : subjects.length;

      // Determine initial index - prioritize preserved target subject if available
      int initialIndex = 0; // Default to first tab
      if (subjects.isNotEmpty) {
        initialIndex = subjects.length - 1; // Default to last tab
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
      }

      _tabController = TabController(
        length: controllerLength,
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
    } else if (widget.targetSubject != null && subjects.isNotEmpty) {
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

  Future<void> _loadSectionsForSubject(int index) async {
    final subjectProvider = ref.read(SubjectProviderProvider);
    final subjects = subjectProvider.filteredSubjects;

    // print(
    //   '🔄 [AssistantSubjectsSection] Loading sections for subject at index $index',
    // );
    // print('   Total subjects: ${subjects.length}');

    if (subjects.isNotEmpty && index < subjects.length) {
      final assistantId = widget.userProfile.id;

      // print('   Subject: ${subject.name}');
      // print('   Assistant ID: $assistantId');

      try {
        // Use the SectionProvider to load sections for this assistant
        await ref
            .read(sectionsProvider.notifier)
            .loadSectionsForAssistant(assistantId);

        // print('   ✅ Sections loaded successfully');
      } catch (e) {
        print('   ❌ Error loading sections: $e');
      }
    } else {
      print('   ⚠️ Invalid index or no subjects');
    }
  }

  Widget _buildMaterialsAccessCard(Subject subject) {
    return Container(
      margin: EdgeInsets.all(Responsive.space(context, size: Space.small)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.blue.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.medium),
        ),
        border: Border.all(color: Colors.blue.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(
            Responsive.space(context, size: Space.medium),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => MaterialLinksScreen.forAssistant(
                      subject: subject,
                      assistantId: widget.userProfile.id,
                      loggedInUser: widget.loggedInUser,
                    ),
              ),
            );
          },
          child: Padding(
            padding: Responsive.padding(context, size: Space.medium),
            child: Row(
              children: [
                Icon(
                  Icons.arrow_back_ios_rounded,
                  color: Colors.blue.shade700,
                  size: Responsive.text(context, size: TextSize.medium),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'الماتيريال',
                        style: TextStyle(
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.medium,
                          ),
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                          fontFamily: 'NotoSansArabic',
                        ),
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.tiny),
                      ),
                      Text(
                        'مشتركة لجميع السكاشن',
                        style: TextStyle(
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.small,
                          ),
                          color: Colors.blue.shade700,
                          fontFamily: 'NotoSansArabic',
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: Responsive.space(context, size: Space.medium)),
                Container(
                  padding: EdgeInsets.all(
                    Responsive.space(context, size: Space.small),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    borderRadius: BorderRadius.circular(
                      Responsive.space(context, size: Space.small),
                    ),
                  ),
                  child: Icon(
                    Icons.library_books_rounded,
                    color: Colors.white,
                    size: Responsive.text(context, size: TextSize.medium) * 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectContent(Subject subject) {
    // Use read instead of watch to prevent unnecessary rebuilds
    final sectionsState = ref.read(sectionsProvider);
    final sections =
        sectionsState.sections
            .where((section) => section.subjectId == subject.id)
            .toList();

    // print(
    //   '🎨 [AssistantSubjectsSection] Building content for subject: ${subject.name}',
    // );
    // print('   isLoading: ${sectionsState.isLoading}');
    // print('   All sections count: ${sectionsState.sections.length}');
    // print('   Filtered sections for this subject: ${sections.length}');
    // print('   Error: ${sectionsState.error}');

    if (sectionsState.isLoading) {
      print('   → Showing loading indicator');
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
      print('   → Showing empty state');
      return Column(
        children: [
          _buildMaterialsAccessCard(subject),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.class_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
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
            ),
          ),
        ],
      );
    }

    // Showing ${sections.length} sections

    return RefreshIndicator(
      onRefresh: () async {
        await _loadSectionsForSubject(_tabController.index);
      },
      child: ListView.builder(
        itemCount: sections.length + 1, // +1 for materials card
        itemBuilder: (context, index) {
          if (index == 0) {
            // First item: Materials access card
            return _buildMaterialsAccessCard(subject);
          }

          // Remaining items: Section cards
          final section = sections[index - 1];
          // Extract section number from name (e.g., "سكاشن 1" -> "1")
          final sectionNumberFromName = section.name.split(' ').last;
          // Check if this section matches the logged-in user's section
          final bool isCurrentUserSection =
              widget.loggedInUser != null &&
              widget.loggedInUser!.section.isNotEmpty &&
              widget.loggedInUser!.section.toLowerCase() ==
                  sectionNumberFromName.toLowerCase();

          return SectionCard(
            section: section,
            subjectName: subject.name,
            isCurrentUserSection: isCurrentUserSection,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use read instead of watch to prevent unnecessary rebuilds from keyboard/UI changes
    final subjectProvider = ref.read(SubjectProviderProvider);
    final subjects = subjectProvider.filteredSubjects;

    // Safety check: ensure TabController length matches subjects length
    if (_tabController.length != subjects.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _updateTabController();
        }
      });

      // Only show loading if we're actually loading subjects from server
      // If subjects is empty and not loading, show empty state immediately
      final subjectProvider = ref.read(SubjectProviderProvider);
      if (subjectProvider.isLoading) {
        return Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
          ),
        );
      }

      // If subjects is empty and not loading, return empty state immediately
      // This prevents the TabController mismatch error
      if (subjects.isEmpty) {
        return Padding(
          padding: EdgeInsets.all(
            Responsive.space(context, size: Space.medium),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.school_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
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
