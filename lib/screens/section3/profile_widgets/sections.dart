import 'package:flutter/material.dart';
import 'package:pivot/models/section_model.dart';
import 'package:pivot/models/subject_model.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/screens/models/instructors_gate.dart';
import 'package:pivot/providers/section_provider.dart';
import 'package:pivot/providers/subject_provider.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/widgets/unified_dialog.dart';
import 'package:provider/provider.dart';

/// Enhanced sections builder with better structure and animations
class SectionsBuilder {
  /// Builds a complete sections list with enhanced features
  static List<Widget> buildSectionsSlivers(
    BuildContext context, {
    bool enableAnimations = true,
  }) {
    final userProfileProvider = Provider.of<UserProfileProvider>(context);
    final sectionProvider = Provider.of<SectionProvider>(context);
    final subjectProvider = Provider.of<SubjectProvider>(context);

    if (userProfileProvider.isLoading || sectionProvider.isLoading) {
      return [_buildLoadingState(context)];
    }

    final loggedInUser = userProfileProvider.loggedInUserProfile;
    final allSections = sectionProvider.sections;
    final enrolledSubjects = subjectProvider.filteredSubjects;

    if (sectionProvider.error != null) {
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
                  sectionProvider.error!,
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: Responsive.text(context, size: TextSize.medium),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: Responsive.space(context, size: Space.medium)),
                ElevatedButton(
                  onPressed:
                      () => sectionProvider.fetchSectionsForUserSubjects(
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

    // Get sections based on default instructors (one per subject)
    final relevantSections = <Section>[];

    for (final subjectId in enrolledSubjectIds) {
      // Get the subject object
      final subject =
          enrolledSubjects.where((s) => s.id == subjectId).firstOrNull;
      if (subject == null) continue;
      // Get instructors for this subject
      final instructors =
          subjectProvider.instructorsBySubject[subject.id]
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
      final userSectionWithDefaultInstructor =
          allSections.where((section) {
            return section.subjectId == subject.id &&
                section.assistantId == defaultAssistantId &&
                section.name.contains(userSectionName);
          }).firstOrNull;

      // Add the user's section with default instructor if found
      if (userSectionWithDefaultInstructor != null) {
        relevantSections.add(userSectionWithDefaultInstructor);
      }
    }

    // If no relevant sections found, show empty state only if we have enrolled subjects
    if (relevantSections.isEmpty && enrolledSubjectIds.isNotEmpty) {
      return [_buildEmptyState(context)];
    }

    final subjectMap = {
      for (var subject in enrolledSubjects) subject.id: subject,
    };

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
class EnhancedSectionListItem extends StatefulWidget {
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
  State<EnhancedSectionListItem> createState() =>
      _EnhancedSectionListItemState();
}

class _EnhancedSectionListItemState extends State<EnhancedSectionListItem>
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
        Provider.of<SubjectProvider>(
          context,
          listen: false,
        ).instructorsBySubject[widget.subject.id];
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
    final userProfileProvider = Provider.of<UserProfileProvider>(
      context,
      listen: false,
    );
    final currentUser = userProfileProvider.userProfile;
    final currentAssistantId = currentUser?.assistantPreferences[subject.id];

    // Auto-select if only one assistant
    String? selectedAssistantId = currentAssistantId;
    if (assistants.length == 1 && selectedAssistantId == null) {
      selectedAssistantId = assistants.first.id;
      // Auto-save the preference
      try {
        final loggedInUser = userProfileProvider.loggedInUserProfile;
        if (loggedInUser != null) {
          await userProfileProvider.updateAssistantPreferences({
            ...loggedInUser.assistantPreferences,
            subject.id: selectedAssistantId,
          });
          print(
            'Auto-saved assistant preference: ${subject.id} -> $selectedAssistantId',
          );
        }
      } catch (e) {
        print('Failed to auto-save assistant preference: $e');
      }
    }

    showInstructorsGate(
      context: context,
      subject: subject,
      instructors: assistants,
      config: InstructorsGateConfig.assistants.copyWith(
        onInstructorSelected: (assistantId) async {
          try {
            // Get the current logged-in user profile
            final loggedInUser = userProfileProvider.loggedInUserProfile;
            if (loggedInUser == null) {
              throw Exception('No logged-in user found');
            }

            print('Saving assistant preference: ${subject.id} -> $assistantId');
            print('Current preferences: ${loggedInUser.assistantPreferences}');

            await userProfileProvider.updateAssistantPreferences({
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
            print('Failed to update assistant preference: $e');
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
      ),
      selectedInstructorId: null, // Dialog will read from provider
      section: section,
    );
  }

  Widget _buildEnhancedDetailSection(BuildContext context, Section section) {
    return Container(
      padding: Responsive.padding(context, size: Space.medium),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.medium),
        ),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildEnhancedDetailRow(
            context,
            'السكاشن',
            section.name,
            Icons.class_,
            Colors.blue,
          ),
          SizedBox(height: Responsive.space(context, size: Space.small)),
          _buildEnhancedDetailRow(
            context,
            'المكان',
            section.location,
            Icons.location_on_outlined,
            Colors.green,
          ),
          SizedBox(height: Responsive.space(context, size: Space.small)),
          _buildEnhancedDetailRow(
            context,
            'الأيام',
            section.days,
            Icons.calendar_today,
            Colors.orange,
          ),
          SizedBox(height: Responsive.space(context, size: Space.small)),
          _buildEnhancedDetailRow(
            context,
            'الوقت',
            section.time,
            Icons.access_time,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(Responsive.space(context, size: Space.small)),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(
              Responsive.space(context, size: Space.small),
            ),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        SizedBox(width: Responsive.space(context, size: Space.medium)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.small),
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.medium),
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAssistantsSection(
    BuildContext context,
    List<UserProfile> assistants,
    Subject subject,
    String? selectedAssistantId,
    Function(String) onAssistantSelected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'المعيدين',
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.medium),
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            if (selectedAssistantId != null)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.space(context, size: Space.small),
                  vertical: Responsive.space(context, size: Space.tiny),
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    Responsive.space(context, size: Space.small),
                  ),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Text(
                  'تم ختيار',
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.small),
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: Responsive.space(context, size: Space.small)),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(
              Responsive.space(context, size: Space.medium),
            ),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: assistants.length,
            separatorBuilder:
                (context, index) =>
                    Divider(height: 1, color: Colors.grey.shade200),
            itemBuilder: (context, index) {
              final assistant = assistants[index];
              return _buildAssistantTile(
                context,
                assistant,
                subject,
                selectedAssistantId,
                onAssistantSelected,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAssistantTile(
    BuildContext context,
    UserProfile assistant,
    Subject subject,
    String? selectedAssistantId,
    Function(String) onAssistantSelected,
  ) {
    final isSelected = selectedAssistantId == assistant.id;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? Colors.green.withOpacity(0.05) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border:
            isSelected
                ? Border.all(color: Colors.green.withOpacity(0.3), width: 1)
                : null,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              isSelected
                  ? Colors.green.withOpacity(0.2)
                  : Colors.black.withOpacity(0.1),
          child: Icon(
            isSelected ? Icons.check : Icons.person,
            color: isSelected ? Colors.green : Colors.black,
          ),
        ),
        title: Text(
          assistant.name,
          style: TextStyle(
            fontSize: Responsive.text(context, size: TextSize.medium),
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.green.shade700 : Colors.black87,
          ),
        ),
        subtitle: Text(
          isSelected ? 'المعيد المختار حالياً' : 'انقر لاختيار هذا المعيد',
          style: TextStyle(
            fontSize: Responsive.text(context, size: TextSize.small),
            color: isSelected ? Colors.green.shade700 : Colors.grey.shade600,
          ),
        ),
        trailing:
            isSelected
                ? Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  ),
                )
                : Icon(
                  Icons.radio_button_unchecked,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
        onTap: () {
          onAssistantSelected(assistant.id);
        },
      ),
    );
  }
}

// Keep the original function for backward compatibility
List<Widget> buildSectionsSlivers(BuildContext context) {
  return SectionsBuilder.buildSectionsSlivers(context, enableAnimations: true);
}
