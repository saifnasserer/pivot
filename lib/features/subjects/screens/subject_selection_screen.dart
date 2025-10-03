import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/guide/providers/guide_provider.dart';
import 'package:pivot/features/user/providers/user_profile_provider.dart';
import 'package:pivot/features/subjects/providers/legacy_subject_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pivot/widgets/no_internet_message.dart';
import 'dart:async';
import 'package:pivot/responsive.dart';
import 'package:pivot/models/subject_model.dart';

class SubjectSelectionScreen extends ConsumerStatefulWidget {
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
  ConsumerState<SubjectSelectionScreen> createState() =>
      _SubjectSelectionScreenState();
}

class _SubjectSelectionScreenState
    extends ConsumerState<SubjectSelectionScreen> {
  bool _isSaving = false;
  bool _saveSuccess = false;
  final Map<int, bool> _expandedState = {};
  late Set<String> _selectedSubjectIds;
  bool _showEnglish = false; // Language toggle
  static const int maxHours = 18; // Maximum allowed hours

  // Removed _isInitializing as it's now handled by Riverpod provider

  // Search functionality
  bool _isSearchMode = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  Timer? _searchDebounce;

  // Filter functionality
  int? _selectedYear;
  List<int> _availableYears = [];

  // Performance optimization
  List<Subject>? _cachedFilteredSubjects;
  String? _lastSearchQuery;
  int? _lastSelectedYear;

  // Prevent unnecessary rebuilds
  String? _lastSubjectsHash;

  @override
  void initState() {
    super.initState();

    _selectedSubjectIds = Set<String>.from(widget.previouslySelectedIds);

    // Initialize subjects provider - local-first approach
    // Only fetches from Firestore if cache is empty
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (kDebugMode) {
        print(
          '📚 [SubjectSelection] Initializing with local-first strategy...',
        );
      }

      // Get user profile to determine level and role
      final userProfileState = ref.read(userProfileProvider);
      final userRole = userProfileState.loggedInUserProfile?.role;

      // Determine which level to use for filtering
      String? levelToUse;
      if (widget.targetUserId != null && userRole == 'Super Admin') {
        // Super Admin editing another user - use target user's level
        final targetUser = userProfileState.allUsers.firstWhere(
          (user) => user.id == widget.targetUserId,
          orElse: () => userProfileState.loggedInUserProfile!,
        );
        levelToUse = targetUser.level;

        if (kDebugMode) {
          print('   👤 Super Admin editing user (Level: ${targetUser.level})');
        }
      } else if (userRole != 'Super Admin') {
        // Regular user - use their own level
        levelToUse = userProfileState.loggedInUserProfile?.level;

        if (kDebugMode) {
          print('   👤 User level: $levelToUse');
        }
      } else {
        // Super Admin managing their own subjects - show all
        if (kDebugMode) {
          print('   👤 Super Admin (showing all subjects)');
        }
      }

      // Fetch subjects - will use cache if available, filtered by level
      ref
          .read(legacySubjectProviderProvider.notifier)
          .fetchAllSubjects(userLevel: levelToUse, userRole: userRole);

      // Fetch guide content
      ref.read(guideProvider.notifier).fetchGuideContent();
    });
  }

  // Removed _loadSubjectsAndData method as it's now handled by Riverpod provider

  // Removed unused methods as they're now handled by Riverpod provider

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _toggleSearchMode() {
    setState(() {
      _isSearchMode = !_isSearchMode;
      if (_isSearchMode) {
        _searchFocusNode.requestFocus();
      } else {
        _searchQuery = '';
        _searchController.clear();
        _searchFocusNode.unfocus();
        _searchDebounce?.cancel();
      }
    });
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = value;
          // Clear cache when search changes
          _cachedFilteredSubjects = null;
        });
      }
    });
  }

  void _updateAvailableFilters(List<Subject> subjects) {
    // Create a hash of the subjects list to detect changes
    final subjectsHash = subjects.map((s) => s.id).join(',');

    // Skip if we've already processed this exact list
    if (_lastSubjectsHash == subjectsHash && _availableYears.isNotEmpty) {
      return;
    }

    _lastSubjectsHash = subjectsHash;

    final years = <int>{};

    for (final subject in subjects) {
      years.add(subject.year);
    }

    final newYears = years.toList()..sort();

    // Only update state if the list has actually changed and is different
    if (_availableYears.length != newYears.length &&
        !_listEquals(_availableYears, newYears)) {
      // Use post-frame callback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _availableYears = newYears;
          });
        }
      });
    }
  }

  bool _listEquals<T>(List<T> list1, List<T> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  List<Subject> _filterSubjects(List<Subject> subjects) {
    // Check if we can use cached results
    // No need to check user level anymore since fetching is level-aware
    if (_cachedFilteredSubjects != null &&
        _lastSearchQuery == _searchQuery &&
        _lastSelectedYear == _selectedYear) {
      return _cachedFilteredSubjects!;
    }

    var filtered =
        subjects.where((subject) {
          // Search filter
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            final name =
                _showEnglish
                    ? subject.englishName.toLowerCase()
                    : subject.name.toLowerCase();
            final departments = subject.departments.join(' ').toLowerCase();

            if (!name.contains(query) && !departments.contains(query)) {
              return false;
            }
          }

          // Year filter
          if (_selectedYear != null && subject.year != _selectedYear) {
            return false;
          }

          return true;
        }).toList();

    // Cache the results
    _cachedFilteredSubjects = filtered;
    _lastSearchQuery = _searchQuery;
    _lastSelectedYear = _selectedYear;

    return filtered;
  }

  int _calculateTotalHours() {
    final subjectState = ref.read(legacySubjectProviderProvider);
    int totalHours = 0;

    for (final subjectId in _selectedSubjectIds) {
      final subject = subjectState.filteredSubjects.firstWhere(
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
    }

    return totalHours;
  }

  bool _canAddSubject(Subject subject) {
    if (_selectedSubjectIds.contains(subject.id)) {
      return true;
    }
    final currentHours = _calculateTotalHours();
    final canAdd = (currentHours + subject.hours) <= maxHours;

    return canAdd;
  }

  void _toggleSubjectSelection(Subject subject) {
    setState(() {
      if (_selectedSubjectIds.contains(subject.id)) {
        _selectedSubjectIds.remove(subject.id);
      } else {
        if (_canAddSubject(subject)) {
          _selectedSubjectIds.add(subject.id);
        } else {
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
  }

  void _showSubjectDetails(Subject subject) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(
                    Responsive.space(context, size: Space.small),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.menu_book,
                    color: Colors.blue[600],
                    size: 24,
                  ),
                ),
                SizedBox(width: Responsive.space(context, size: Space.small)),
                Expanded(
                  child: Text(
                    _showEnglish ? subject.englishName : subject.name,
                    style: TextStyle(
                      fontSize: Responsive.text(context, size: TextSize.medium),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Subject name in both languages
                  if (_showEnglish && subject.name.isNotEmpty) ...[
                    _buildDetailRow(
                      'الاسم بالعربية',
                      subject.name,
                      Icons.translate,
                    ),
                    const SizedBox(height: 12),
                  ] else if (!_showEnglish &&
                      subject.englishName.isNotEmpty) ...[
                    _buildDetailRow(
                      'English Name',
                      subject.englishName,
                      Icons.language,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Year
                  _buildDetailRow(
                    'السنة الدراسية',
                    'السنة ${subject.year}',
                    Icons.grade,
                  ),
                  const SizedBox(height: 12),

                  // Hours
                  _buildDetailRow(
                    'عدد الساعات',
                    '${subject.hours} ساعة',
                    Icons.access_time,
                    valueColor: subject.hours > 3 ? Colors.orange[600] : null,
                  ),
                  const SizedBox(height: 12),

                  // Departments
                  _buildDetailRow(
                    'الأقسام',
                    subject.departments.join(', '),
                    Icons.school,
                    valueColor:
                        subject.departments.length > 1
                            ? Colors.blue[600]
                            : null,
                  ),
                  const SizedBox(height: 16),

                  // Selection status
                  Container(
                    padding: EdgeInsets.all(
                      Responsive.space(context, size: Space.medium),
                    ),
                    decoration: BoxDecoration(
                      color:
                          _selectedSubjectIds.contains(subject.id)
                              ? Colors.green[50]
                              : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            _selectedSubjectIds.contains(subject.id)
                                ? Colors.green[200]!
                                : Colors.grey[200]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _selectedSubjectIds.contains(subject.id)
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color:
                              _selectedSubjectIds.contains(subject.id)
                                  ? Colors.green[600]
                                  : Colors.grey[600],
                          size: 20,
                        ),
                        SizedBox(
                          width: Responsive.space(context, size: Space.small),
                        ),
                        Text(
                          _selectedSubjectIds.contains(subject.id)
                              ? 'مادة محددة'
                              : 'غير محددة',
                          style: TextStyle(
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.small,
                            ),
                            fontWeight: FontWeight.w500,
                            color:
                                _selectedSubjectIds.contains(subject.id)
                                    ? Colors.green[700]
                                    : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('إغلاق'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _toggleSubjectSelection(subject);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _selectedSubjectIds.contains(subject.id)
                          ? Colors.red[600]
                          : Colors.blue[600],
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  _selectedSubjectIds.contains(subject.id)
                      ? 'إلغاء التحديد'
                      : 'تحديد المادة',
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        SizedBox(width: Responsive.space(context, size: Space.small)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.small),
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.small),
                  color: valueColor ?? Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<bool> _showSaveConfirmationDialog() async {
    final totalHours = _calculateTotalHours();
    final selectedCount = _selectedSubjectIds.length;

    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(
                        Responsive.space(context, size: Space.small),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.save,
                        color: Colors.blue[600],
                        size: 24,
                      ),
                    ),
                    SizedBox(
                      width: Responsive.space(context, size: Space.small),
                    ),
                    const Text('تأكيد الحفظ'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'هل أنت متأكد من حفظ التغييرات؟',
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.medium,
                        ),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(
                        Responsive.space(context, size: Space.medium),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        children: [
                          _buildConfirmationRow(
                            'عدد المواد المحددة',
                            '$selectedCount مادة',
                            Icons.checklist_rtl,
                          ),
                          const SizedBox(height: 8),
                          _buildConfirmationRow(
                            'إجمالي الساعات',
                            '$totalHours / $maxHours ساعة',
                            Icons.access_time,
                            valueColor:
                                totalHours > maxHours ? Colors.red[600] : null,
                          ),
                        ],
                      ),
                    ),
                    if (totalHours > maxHours) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.all(
                          Responsive.space(context, size: Space.medium),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning,
                              color: Colors.red[600],
                              size: 20,
                            ),
                            SizedBox(
                              width: Responsive.space(
                                context,
                                size: Space.small,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'تجاوزت الحد الأقصى للساعات المسموح بها',
                                style: TextStyle(
                                  fontSize: Responsive.text(
                                    context,
                                    size: TextSize.small,
                                  ),
                                  color: Colors.red[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('إلغاء'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          totalHours > maxHours
                              ? Colors.red[600]
                              : Colors.blue[600],
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      totalHours > maxHours ? 'حفظ مع التحذير' : 'حفظ',
                    ),
                  ),
                ],
              ),
        ) ??
        false;
  }

  Widget _buildConfirmationRow(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        SizedBox(width: Responsive.space(context, size: Space.small)),
        Text(
          label,
          style: TextStyle(
            fontSize: Responsive.text(context, size: TextSize.small),
            color: Colors.grey[600],
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: Responsive.text(context, size: TextSize.small),
            fontWeight: FontWeight.w600,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Future<void> _retrySave() async {
    setState(() {
      _isSaving = true;
      _saveSuccess = false;
    });

    bool success = false;
    try {
      final userProfileState = ref.read(userProfileProvider);
      final userRole = userProfileState.loggedInUserProfile?.role;

      // If targetUserId is provided, Super Admin is editing another user's subjects
      if (widget.targetUserId != null && userRole == 'Super Admin') {
        final targetUserRole = widget.targetUserRole;

        if (targetUserRole == 'Student' || targetUserRole == 'Admin') {
          await ref
              .read(userProfileProvider.notifier)
              .updateUserEnrolledSubjects(
                widget.targetUserId!,
                _selectedSubjectIds.toList(),
              );
        } else if (targetUserRole == 'Professor' ||
            targetUserRole == 'miniProfessor' ||
            targetUserRole == 'Doctor') {
          await ref
              .read(userProfileProvider.notifier)
              .updateUserTeachingSubjects(
                widget.targetUserId!,
                _selectedSubjectIds.toList(),
              );
        } else {
          throw Exception('Unknown target user role: $targetUserRole');
        }

        await ref.read(userProfileProvider.notifier).fetchAllUsers();
        await ref
            .read(legacySubjectProviderProvider.notifier)
            .fetchAllSubjects();
        success = true;
      } else {
        // Normal flow - user editing their own subjects
        if (userRole == 'Student' ||
            userRole == 'Admin' ||
            userRole == 'Super Admin') {
          await ref
              .read(userProfileProvider.notifier)
              .updateEnrolledSubjects(_selectedSubjectIds.toList());
        } else if (userRole == 'Professor' ||
            userRole == 'miniProfessor' ||
            userRole == 'Doctor') {
          await ref
              .read(userProfileProvider.notifier)
              .updateTeachingSubjects(_selectedSubjectIds.toList());
        } else {
          throw Exception('Unknown user role: $userRole');
        }

        await ref.read(userProfileProvider.notifier).loadLoggedInUserProfile();
        success = true;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في إعادة المحاولة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        if (success) {
          setState(() {
            _isSaving = false;
            _saveSuccess = true;
          });
          await Future.delayed(const Duration(milliseconds: 800));
          if (mounted) {
            Navigator.pop(context, true);
          }
        } else {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
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
        onLongPress: () => _showSubjectDetails(subject),
        borderRadius: BorderRadius.circular(16),
        child: Semantics(
          label:
              '${_showEnglish ? subject.englishName : subject.name} - ${subject.hours} ساعة - ${subject.departments.join(', ')}',
          hint: isSelected ? 'مادة محددة' : 'مادة غير محددة',
          button: true,
          enabled: true,
          selected: isSelected,
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
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.space(
                            context,
                            size: Space.small,
                          ),
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              subject.hours > 3
                                  ? Colors.orange[100]
                                  : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border:
                              subject.hours > 3
                                  ? Border.all(
                                    color: Colors.orange[300]!,
                                    width: 1,
                                  )
                                  : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color:
                                  subject.hours > 3
                                      ? Colors.orange[600]
                                      : Colors.grey[600],
                            ),
                            SizedBox(width: 4),
                            Text(
                              'ساعات: ${subject.hours}',
                              style: TextStyle(
                                color:
                                    subject.hours > 3
                                        ? Colors.orange[700]
                                        : Colors.grey[700],
                                fontWeight: FontWeight.w500,
                                fontSize: Responsive.text(
                                  context,
                                  size: TextSize.small,
                                ),
                              ),
                            ),
                          ],
                        ),
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
                          ? const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          )
                          : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuideSection() {
    return Consumer(
      builder: (context, ref, child) {
        final guideState = ref.watch(guideProvider);

        if (guideState.isLoading && guideState.guideContent == null) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (guideState.error != null) {
          return SizedBox(
            height: 200,
            child: Center(child: Text('خطأ: ${guideState.error}')),
          );
        }

        final guideContent = guideState.guideContent;
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
                            'لائحة الكلية',
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

  Future<void> _handleRefresh() async {
    if (kDebugMode) {
      print('🔄 [SubjectSelection] Manual refresh triggered');
    }

    // Get user profile to determine level and role
    final userProfileState = ref.read(userProfileProvider);
    final userRole = userProfileState.loggedInUserProfile?.role;

    // Determine which level to use for filtering
    String? levelToUse;
    if (widget.targetUserId != null && userRole == 'Super Admin') {
      final targetUser = userProfileState.allUsers.firstWhere(
        (user) => user.id == widget.targetUserId,
        orElse: () => userProfileState.loggedInUserProfile!,
      );
      levelToUse = targetUser.level;
    } else if (userRole != 'Super Admin') {
      levelToUse = userProfileState.loggedInUserProfile?.level;
    }

    await ref
        .read(legacySubjectProviderProvider.notifier)
        .fetchAllSubjects(
          forceRefresh: true,
          userLevel: levelToUse,
          userRole: userRole,
        );

    if (kDebugMode) {
      print('✅ [SubjectSelection] Refresh complete');
    }
  }

  Widget _buildSubjectsList() {
    return Consumer(
      builder: (context, ref, child) {
        final subjectState = ref.watch(legacySubjectProviderProvider);
        if (subjectState.isLoading) {
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
        if (subjectState.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                SizedBox(height: Responsive.space(context, size: Space.medium)),
                Text(
                  'حدث خطأ: ${subjectState.error}',
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.medium),
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: Responsive.space(context, size: Space.medium)),
                ElevatedButton.icon(
                  onPressed: () {
                    ref
                        .read(legacySubjectProviderProvider.notifier)
                        .fetchAllSubjects(forceRefresh: true);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        if (subjectState.filteredSubjects.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(
                    Responsive.space(context, size: Space.large),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.menu_book_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                ),
                SizedBox(height: Responsive.space(context, size: Space.medium)),
                Text(
                  'لا توجد مواد متاحة',
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.medium),
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: Responsive.space(context, size: Space.small)),
                Text(
                  'تأكد من اتصالك بالإنترنت أو حاول مرة أخرى',
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.small),
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: Responsive.space(context, size: Space.medium)),
                ElevatedButton.icon(
                  onPressed: () {
                    ref
                        .read(legacySubjectProviderProvider.notifier)
                        .fetchAllSubjects(forceRefresh: true);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة التحميل'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final subjects = subjectState.filteredSubjects;

        // Update available filters when subjects change (optimized)
        _updateAvailableFilters(subjects);

        // Use memoization for filtered subjects to avoid unnecessary recalculations
        final filteredSubjects = _filterSubjects(subjects);

        if (_searchQuery.isNotEmpty && filteredSubjects.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(
                    Responsive.space(context, size: Space.large),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.search_off,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                ),
                SizedBox(height: Responsive.space(context, size: Space.medium)),
                Text(
                  'لا توجد نتائج للبحث',
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.medium),
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: Responsive.space(context, size: Space.small)),
                Text(
                  'جرب البحث بكلمات مختلفة أو تغيير الفلاتر',
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.small),
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: Responsive.space(context, size: Space.medium)),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _searchController.clear();
                      _selectedYear = null;
                    });
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('مسح البحث والفلاتر'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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

        return RefreshIndicator(
          onRefresh: _handleRefresh,
          color: Colors.black,
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
          ),
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
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
          appBar: AppBar(
            title:
                _isSearchMode
                    ? TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: _onSearchChanged,
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
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Consumer(
                      builder: (context, ref, child) {
                        final totalHours = _calculateTotalHours();
                        final isOverLimit = totalHours > maxHours;

                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color:
                                  isOverLimit ? Colors.red : Colors.grey[600],
                            ),
                            SizedBox(
                              width: Responsive.space(
                                context,
                                size: Space.small,
                              ),
                            ),
                            Text(
                              'الساعات المختارة: $totalHours / $maxHours',
                              style: TextStyle(
                                fontSize: Responsive.text(
                                  context,
                                  size: TextSize.small,
                                ),
                                fontWeight: FontWeight.w500,
                                color:
                                    isOverLimit ? Colors.red : Colors.grey[600],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
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
                Consumer(
                  builder: (context, ref, child) {
                    final guideState = ref.watch(guideProvider);
                    final hasContent =
                        guideState.guideContent != null &&
                        guideState.guideContent!.guidebooks.isNotEmpty;
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
          floatingActionButton: Semantics(
            label: 'حفظ المواد المحددة',
            hint:
                _isSaving
                    ? 'جاري الحفظ...'
                    : _calculateTotalHours() > maxHours
                    ? 'تجاوز الحد الأقصى للساعات'
                    : 'اضغط لحفظ التغييرات',
            button: true,
            enabled: !_isSaving && _calculateTotalHours() <= maxHours,
            child: Container(
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
                          // Show confirmation dialog before saving
                          final shouldSave =
                              await _showSaveConfirmationDialog();
                          if (!shouldSave) return;
                          setState(() {
                            _isSaving = true;
                            _saveSuccess = false;
                          });

                          bool success = false;
                          try {
                            print(
                              '📚 [SubjectSelection] Starting save process...',
                            );
                            final userProfileState = ref.read(
                              userProfileProvider,
                            );

                            final userRole =
                                userProfileState.loggedInUserProfile?.role;
                            print('📚 [SubjectSelection] User role: $userRole');
                            print(
                              '📚 [SubjectSelection] Selected subjects: ${_selectedSubjectIds.length}',
                            );

                            // If targetUserId is provided, Super Admin is editing another user's subjects
                            if (widget.targetUserId != null &&
                                userRole == 'Super Admin') {
                              print('📚 [SubjectSelection] Super Admin mode');
                              // Use the targetUserRole parameter instead of fetching from allUsers
                              final targetUserRole = widget.targetUserRole;

                              if (targetUserRole == 'Student' ||
                                  targetUserRole == 'Admin') {
                                print(
                                  '📚 [SubjectSelection] Updating enrolled subjects for target user',
                                );
                                await ref
                                    .read(userProfileProvider.notifier)
                                    .updateUserEnrolledSubjects(
                                      widget.targetUserId!,
                                      _selectedSubjectIds.toList(),
                                    );
                              } else if (targetUserRole == 'Professor' ||
                                  targetUserRole == 'miniProfessor' ||
                                  targetUserRole == 'Doctor') {
                                print(
                                  '📚 [SubjectSelection] Updating teaching subjects for target user',
                                );
                                await ref
                                    .read(userProfileProvider.notifier)
                                    .updateUserTeachingSubjects(
                                      widget.targetUserId!,
                                      _selectedSubjectIds.toList(),
                                    );
                              } else {
                                throw Exception(
                                  'Unknown target user role: $targetUserRole',
                                );
                              }

                              // Update the UI after Super Admin changes
                              print(
                                '📚 [SubjectSelection] Refreshing all users and subjects',
                              );
                              await ref
                                  .read(userProfileProvider.notifier)
                                  .fetchAllUsers();
                              await ref
                                  .read(legacySubjectProviderProvider.notifier)
                                  .fetchAllSubjects();
                              success = true;
                              print(
                                '✅ [SubjectSelection] Super Admin save successful',
                              );
                            } else {
                              // Normal flow - user editing their own subjects
                              print('📚 [SubjectSelection] Normal user mode');

                              if (userRole == 'Student' ||
                                  userRole == 'Admin' ||
                                  userRole == 'Super Admin') {
                                print(
                                  '📚 [SubjectSelection] Updating enrolled subjects',
                                );
                                await ref
                                    .read(userProfileProvider.notifier)
                                    .updateEnrolledSubjects(
                                      _selectedSubjectIds.toList(),
                                    );
                              } else if (userRole == 'Professor' ||
                                  userRole == 'miniProfessor' ||
                                  userRole == 'Doctor') {
                                print(
                                  '📚 [SubjectSelection] Updating teaching subjects',
                                );
                                await ref
                                    .read(userProfileProvider.notifier)
                                    .updateTeachingSubjects(
                                      _selectedSubjectIds.toList(),
                                    );
                              } else {
                                // Handle unknown role

                                throw Exception('Unknown user role: $userRole');
                              }

                              // After updating subjects, fetch the latest user profile to ensure
                              // the UI reflects the changes upon returning to the previous screen.
                              print(
                                '📚 [SubjectSelection] Reloading user profile',
                              );
                              await ref
                                  .read(userProfileProvider.notifier)
                                  .loadLoggedInUserProfile();
                              success = true;
                              print('✅ [SubjectSelection] Save successful');
                            }
                          } catch (e) {
                            print('❌ [SubjectSelection] Error during save: $e');
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('فشل في تحديث المواد: $e'),
                                  backgroundColor: Colors.red,
                                  action: SnackBarAction(
                                    label: 'إعادة المحاولة',
                                    textColor: Colors.white,
                                    onPressed: () {
                                      // Retry the save operation
                                      _retrySave();
                                    },
                                  ),
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              if (success) {
                                setState(() {
                                  _isSaving = false;
                                  _saveSuccess = true;
                                });
                                await Future.delayed(
                                  const Duration(milliseconds: 800),
                                );
                                if (mounted) {
                                  // Return true to indicate success, allowing the previous screen to react.
                                  Navigator.pop(context, true);
                                }
                              } else {
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
          ),
        ),
      ),
    );
  }
}

// Helper widget to wrap SubjectSelectionScreen with required providers
class SubjectSelectionScreenWithProviders extends StatelessWidget {
  final List<String> previouslySelectedIds;
  final String? targetUserId;
  final String? targetUserRole;

  const SubjectSelectionScreenWithProviders({
    super.key,
    required this.previouslySelectedIds,
    this.targetUserId,
    this.targetUserRole,
  });

  @override
  Widget build(BuildContext context) {
    return SubjectSelectionScreen(
      previouslySelectedIds: previouslySelectedIds,
      targetUserId: targetUserId,
      targetUserRole: targetUserRole,
    );
  }
}
