import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/models/section_model.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/features/administration/providers/sections_provider.dart';
import 'package:pivot/features/subjects/providers/subjects_provider.dart';
import 'package:pivot/features/user/providers/user_profile_provider.dart';
import 'enhanced_section_list_item.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/models/subject_model.dart';

/// Simplified sections builder for snapshot-based approach
class SectionsBuilder {
  /// Builds a complete sections list with snapshot data
  static List<Widget> buildSectionsSlivers(
    BuildContext context,
    WidgetRef ref, {
    bool enableAnimations = true,
  }) {
    // Only watch providers that actually need to trigger rebuilds
    final userProfileState = ref.watch(userProfileProvider);
    final sectionsState = ref.watch(sectionsProvider);

    // Use read for subjects since they don't change frequently
    final subjectsState = ref.read(subjectsProvider);

    // Show loading state
    if (userProfileState.isLoading || sectionsState.isLoading) {
      return [_buildLoadingState(context)];
    }

    final loggedInUser = userProfileState.loggedInUserProfile;
    final allSections = sectionsState.sections; // Snapshot data
    final enrolledSubjects = subjectsState.filteredSubjects;

    // Building sections UI

    // Show error state if error and no sections
    if (sectionsState.error != null && allSections.isEmpty) {
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
              ],
            ),
          ),
        ),
      ];
    }

    if (loggedInUser == null) {
      return [_buildErrorState(context)];
    }

    final enrolledSubjectIds = loggedInUser.enrolledSubjects.toSet();

    // Check if user has no enrolled subjects
    if (enrolledSubjectIds.isEmpty) {
      return [_buildEmptyState(context)];
    }

    // Filter sections by enrolled subjects
    final userRelevantSections =
        allSections.where((section) {
          return enrolledSubjectIds.contains(section.subjectId);
        }).toList();

    // Filtered sections: ${userRelevantSections.length}

    // Filter subjects by enrolled
    final registeredSubjects =
        enrolledSubjects
            .where((s) => enrolledSubjectIds.contains(s.id))
            .toList();

    // If subjects not loaded yet, show loading
    if (registeredSubjects.isEmpty && enrolledSubjectIds.isNotEmpty) {
      return [_buildLoadingState(context)];
    }

    // Build sections list
    return [
      _buildSectionsList(
        context,
        registeredSubjects,
        userRelevantSections,
        enableAnimations,
        loggedInUser,
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

  /// Builds empty state
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
              'لا توجد مواد مسجلة',
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.medium),
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Responsive.space(context, size: Space.small)),
            Text(
              'قم بتسجيل المواد أولاً لعرض الأقسام',
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

  /// Builds sections list
  static Widget _buildSectionsList(
    BuildContext context,
    List<Subject> subjects,
    List<Section> allSections,
    bool enableAnimations,
    UserProfile? loggedInUser,
  ) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, size: Space.medium),
        vertical: Responsive.space(context, size: Space.small),
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final subject = subjects[index];

          // Find sections for this subject
          final subjectSections =
              allSections
                  .where((section) => section.subjectId == subject.id)
                  .toList();

          // Subject: ${subject.name} → ${subjectSections.length} sections

          return AnimatedContainer(
            duration:
                enableAnimations
                    ? Duration(milliseconds: 300 + (index * 50))
                    : Duration.zero,
            curve: Curves.easeInOut,
            child: EnhancedSectionListItem(
              subject: subject,
              sections: subjectSections,
              index: index,
            ),
          );
        }, childCount: subjects.length),
      ),
    );
  }
}
