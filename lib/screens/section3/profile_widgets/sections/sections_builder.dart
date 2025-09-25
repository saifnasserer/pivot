import 'package:flutter/material.dart';
import 'package:pivot/models/section_model.dart';
import 'package:pivot/providers/section_provider.dart';
import 'package:pivot/providers/subject_provider.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:provider/provider.dart';
import 'enhanced_section_list_item.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/models/subject_model.dart';
import 'package:pivot/models/material_link.dart';


/// Enhanced sections builder with simplified logic - similar to subjects
class SectionsBuilder {
  /// Builds a complete sections list with simplified approach
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
                  onPressed: () {
                    final enrolledIds = loggedInUser?.enrolledSubjects ?? [];
                    if (enrolledIds.isNotEmpty) {
                      sectionProvider.fetchSectionsForUserSubjects(enrolledIds);
                    }
                  },
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

    // Simplified approach: Show section cards for all enrolled subjects
    final enrolledSubjectIds = loggedInUser.enrolledSubjects.toSet();

    // Check if user has no enrolled subjects first
    if (enrolledSubjectIds.isEmpty) {
      return [_buildEmptyState(context)];
    }

    final registeredSubjects =
        enrolledSubjects
            .where((s) => enrolledSubjectIds.contains(s.id))
            .toList();

    // If we have enrolled subjects but none found in the list, still show them
    // This handles the case where subjects are enrolled but not yet loaded
    if (registeredSubjects.isEmpty && enrolledSubjectIds.isNotEmpty) {
      // Create placeholder subjects for enrolled subjects not found in the list
      final placeholderSubjects =
          enrolledSubjectIds
              .map(
                (subjectId) => Subject(
                  id: subjectId,
                  name: 'Subject $subjectId', // Placeholder name
                  hours: 0,
                  year: 1,
                  departments: [],
                  englishName: 'Subject $subjectId',
                  description: '',
                ),
              )
              .toList();

      return [
        _buildSectionsList(
          context,
          placeholderSubjects,
          allSections,
          enableAnimations,
        ),
      ];
    }

    return [
      _buildSectionsList(
        context,
        registeredSubjects,
        allSections,
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

  /// Builds sections list with simplified approach
  static Widget _buildSectionsList(
    BuildContext context,
    List<Subject> subjects,
    List<Section> allSections,
    bool enableAnimations,
  ) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, size: Space.medium),
        vertical: Responsive.space(context, size: Space.small),
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final subject = subjects[index];

          // Find sections for this subject (if any)
          final subjectSections =
              allSections
                  .where((section) => section.subjectId == subject.id)
                  .toList();

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
