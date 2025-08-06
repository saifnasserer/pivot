import 'package:flutter/material.dart';
import 'package:pivot/models/section_model.dart';
import 'package:pivot/models/subject_model.dart';
import 'package:pivot/providers/section_provider.dart';
import 'package:pivot/providers/subject_provider.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:provider/provider.dart';
import 'enhanced_section_list_item.dart';

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
