import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/models/section_model.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/features/user/providers/user_profile_provider.dart';
import 'package:pivot/screens/models/instructors_gate.dart';
import 'package:pivot/features/administration/providers/sections_provider.dart';
import 'package:pivot/features/subjects/providers/subject_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/models/subject_model.dart';

/// Enhanced sections builder with better structure and animations
class SectionsBuilder {
  /// Builds a complete sections list with enhanced features
  static List<Widget> buildSectionsSlivers(
    BuildContext context,
    WidgetRef ref, {
    bool enableAnimations = true,
  }) {
    final userProfileState = ref.watch(userProfileProvider);
    final sectionsState = ref.watch(sectionsProvider);
    final subjectState = ref.watch(SubjectProviderProvider);

    if (userProfileState.isLoading || sectionsState.isLoading) {
      return [_buildLoadingState(context)];
    }

    final loggedInUser = userProfileState.loggedInUserProfile;
    final allSections = sectionsState.sections;
    final enrolledSubjects = subjectState.filteredSubjects;

    if (sectionsState.error != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 48),
                SizedBox(height: Responsive.space(context, size: Space.medium)),
                Text(
                  sectionsState.error!,
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: Responsive.text(context, size: TextSize.medium),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: Responsive.space(context, size: Space.medium)),
                ElevatedButton(
                  onPressed:
                      () => ref
                          .read(sectionsProvider.notifier)
                          .fetchSectionsForUserSubjects(
                            enrolledSubjects.map((s) => s.id).toList(),
                          ),
                  child: Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
      ];
    }
    if (loggedInUser == null) {
      return [_buildErrorState(context)];
    }

    final userSectionName = loggedInUser.section;
    final enrolledSubjectIds = loggedInUser.enrolledSubjects.toSet();
    final assistantPreferences = loggedInUser.assistantPreferences;

    // Create subject lookup map for O(1) access
    final subjectMap = {
      for (var subject in enrolledSubjects) subject.id: subject,
    };

    // Get sections based on default instructors (one per subject)
    final relevantSections = <Section>[];

    for (final subjectId in enrolledSubjectIds) {
      // Get the subject object using O(1) lookup
      final subject = subjectMap[subjectId];
      if (subject == null) continue;

      // Get instructors for this subject
      final instructors =
          subjectState.instructorsBySubject[subject.id]
              ?.where((prof) => prof.role == 'miniProfessor')
              .toList() ??
          [];

      if (instructors.isEmpty) continue;

      // Get the default instructor (selected preference or first instructor)
      String? defaultAssistantId = assistantPreferences[subject.id];
      if (defaultAssistantId == null && instructors.length == 1) {
        // Auto-select if only one instructor
        defaultAssistantId = instructors.first.id;
      } else if (defaultAssistantId == null) {
        // Multiple instructors but none selected - skip this subject
        continue;
      }

      // Find the user's specific section for this subject and default instructor
      // Use more efficient filtering
      try {
        final userSectionWithDefaultInstructor = allSections.firstWhere(
          (section) =>
              section.subjectId == subject.id &&
              section.assistantId == defaultAssistantId &&
              section.name.contains(userSectionName),
        );
        relevantSections.add(userSectionWithDefaultInstructor);
      } catch (e) {
        // Section not found, continue to next subject
      }
    }

    // If no relevant sections found, show empty state only if we have enrolled subjects
    if (relevantSections.isEmpty && enrolledSubjectIds.isNotEmpty) {
      return [_buildEmptyState(context)];
    }

    return [
      _buildSectionsList(
        context,
        relevantSections,
        subjectMap,
        enableAnimations,
      ),
    ];
  }

  /// Builds loading state
  static Widget _buildLoadingState(BuildContext context) {
    return const SliverFillRemaining(
      child: Center(child: CircularProgressIndicator()),
    );
  }

  /// Builds error state
  static Widget _buildErrorState(BuildContext context) {
    return const SliverFillRemaining(
      child: Center(child: Text('User not found')),
    );
  }

  /// Builds empty state with enhanced design
  static Widget _buildEmptyState(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(
                Responsive.space(context, size: Space.large),
              ),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_today_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
            ),
            SizedBox(height: Responsive.space(context, size: Space.medium)),
            Text(
              'لا توجد سكاشن مسجلة لك حالياً',
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.medium),
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Responsive.space(context, size: Space.small)),
            Text(
              'سيتم إضافة السكاشن قريباً',
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.small),
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds sections list with enhanced styling
  static Widget _buildSectionsList(
    BuildContext context,
    List<Section> sections,
    Map<String, Subject> subjectMap,
    bool enableAnimations,
  ) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, size: Space.medium),
        vertical: Responsive.space(context, size: Space.small),
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final section = sections[index];
          final subject = subjectMap[section.subjectId];
          if (subject == null) {
            return const SizedBox.shrink();
          }

          return AnimatedContainer(
            duration:
                enableAnimations
                    ? Duration(milliseconds: 300 + (index * 50))
                    : Duration.zero,
            curve: Curves.easeInOut,
            child: EnhancedSectionListItem(
              section: section,
              subject: subject,
              index: index,
            ),
          );
        }, childCount: sections.length),
      ),
    );
  }
}

/// Enhanced section list item with better design and functionality
class EnhancedSectionListItem extends ConsumerStatefulWidget {
  const EnhancedSectionListItem({
    super.key,
    required this.section,
    required this.subject,
    required this.index,
  });

  final Section section;
  final Subject subject;
  final int index;

  @override
  ConsumerState<EnhancedSectionListItem> createState() =>
      _EnhancedSectionListItemState();
}

class _EnhancedSectionListItemState
    extends ConsumerState<EnhancedSectionListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTap() {
    final instructors =
        ref.read(SubjectProviderProvider).instructorsBySubject[widget
            .subject
            .id];
    final assistants =
        instructors?.where((prof) => prof.role == 'miniProfessor').toList() ??
        [];
    _showEnhancedSectionDetails(
      context,
      widget.subject,
      widget.section,
      assistants,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: Responsive.space(context, size: Space.small),
            ),
            child: Material(
              elevation: _isHovered ? 4 : 0.5,
              borderRadius: BorderRadius.circular(
                Responsive.space(context, size: Space.large),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(
                  Responsive.space(context, size: Space.large),
                ),
                onTap: _onTap,
                onHover: (hovered) {
                  setState(() {
                    _isHovered = hovered;
                  });
                  if (hovered) {
                    _animationController.forward();
                  } else {
                    _animationController.reverse();
                  }
                },
                child: Container(
                  padding: Responsive.padding(context, size: Space.medium),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      Responsive.space(context, size: Space.large),
                    ),
                    border: Border.all(
                      color:
                          _isHovered
                              ? Colors.black.withOpacity(0.2)
                              : Colors.grey.shade200,
                    ),
                    gradient:
                        _isHovered
                            ? LinearGradient(
                              colors: [Colors.grey.shade50, Colors.white],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                            : null,
                  ),
                  child: Row(
                    children: [
                      // Arrow icon (RTL - on the left)
                      Icon(
                        Icons.arrow_back_ios,
                        color: _isHovered ? Colors.black : Colors.grey.shade400,
                        size: 16,
                      ),

                      // Section info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              widget.subject.name,
                              style: TextStyle(
                                fontSize: Responsive.text(
                                  context,
                                  size: TextSize.medium,
                                ),
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            ),
                            SizedBox(
                              height: Responsive.space(
                                context,
                                size: Space.small,
                              ),
                            ),
                            Wrap(
                              spacing: Responsive.space(
                                context,
                                size: Space.small,
                              ),
                              runSpacing: Responsive.space(
                                context,
                                size: Space.tiny,
                              ),
                              alignment: WrapAlignment.end,
                              children: [
                                _buildInfoChip(
                                  context,
                                  widget.section.location,
                                  Colors.green,
                                ),
                                _buildInfoChip(
                                  context,
                                  '${widget.section.days} - ${widget.section.time}',
                                  Colors.orange,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(
                        width: Responsive.space(context, size: Space.medium),
                      ),

                      // Section icon (RTL - on the right)
                      Container(
                        padding: EdgeInsets.all(
                          Responsive.space(context, size: Space.small),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            Responsive.space(context, size: Space.medium),
                          ),
                        ),
                        child: Icon(
                          Icons.class_,
                          color: Colors.black,
                          size: Responsive.text(context, size: TextSize.medium),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(BuildContext context, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, size: Space.small),
        vertical: Responsive.space(context, size: Space.tiny),
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.small),
        ),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: Responsive.text(context, size: TextSize.small),
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showEnhancedSectionDetails(
    BuildContext context,
    Subject subject,
    Section section,
    List<UserProfile> assistants,
  ) async {
    final userProfileState = ref.read(userProfileProvider);
    final currentUser = userProfileState.loggedInUserProfile;
    final currentAssistantId = currentUser?.assistantPreferences[subject.id];

    // Auto-select if only one assistant
    String? selectedAssistantId = currentAssistantId;
    if (assistants.length == 1 && selectedAssistantId == null) {
      selectedAssistantId = assistants.first.id;
      // Auto-save the preference
      try {
        final loggedInUser = userProfileState.loggedInUserProfile;
        if (loggedInUser != null) {
          await ref
              .read(userProfileProvider.notifier)
              .updateAssistantPreferences({
                ...loggedInUser.assistantPreferences,
                subject.id: selectedAssistantId,
              });
        }
      } catch (e) {}
    }

    showInstructorsGate(
      context: context,
      ref: ref,
      subject: subject,
      instructors: assistants,
      config: InstructorsGateConfig.assistants.copyWith(
        onInstructorSelected: (assistantId) async {
          try {
            // Get the current logged-in user profile
            final loggedInUser =
                ref.read(userProfileProvider).loggedInUserProfile;
            if (loggedInUser == null) {
              throw Exception('No logged-in user found');
            }

            await ref
                .read(userProfileProvider.notifier)
                .updateAssistantPreferences({
                  ...loggedInUser.assistantPreferences,
                  subject.id: assistantId,
                });
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('تم حفظ اختيار المعيد بنجاح'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
            // Close the dialog after successful update
            Navigator.of(context).pop();
          } catch (e) {
            // Show error message to user
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('فشل في حفظ اختيار المعيد'),
                backgroundColor: Colors.red,
              ),
            );
            // Re-throw to let the dialog handle the error state
            rethrow;
          }
        },
        onInstructorTapped: (assistant) {
          // Navigate to assistant profile with subject context
          Navigator.of(context).pop();
          final navigationArgs = {
            'instructor': assistant,
            'subject': subject,
            'fromSubject': true,
          };
          Navigator.pushNamed(
            context,
            '/assistant-profile',
            arguments: navigationArgs,
          );
        },
      ),
      selectedInstructorId: null, // Dialog will read from provider
      section: section,
    );
  }
}

// Keep the original function for backward compatibility
// Note: This should be replaced with the version that includes WidgetRef
@Deprecated('Use the version with WidgetRef parameter instead')
List<Widget> buildSectionsSlivers(BuildContext context) {
  throw UnimplementedError(
    'buildSectionsSlivers now requires a WidgetRef parameter. '
    'Convert your widget to ConsumerWidget and pass ref.',
  );
}
