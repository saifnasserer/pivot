import 'package:flutter/material.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/models/subject_model.dart';
import 'package:pivot/providers/section_provider.dart';
import 'package:pivot/providers/subject_provider.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/section4/doctor_details.dart';
import 'package:pivot/screens/models/section_card.dart';
import 'package:provider/provider.dart';
import 'assistant_about_section.dart';

class AssistantProfileContent {
  static List<Widget> getCategoryContentSlivers(
    BuildContext context,
    String currentCategory,
    UserProfile displayedProfile,
    List<Subject> localFilteredSubjects,
    int selectedSubjectIndex,
    TabController Function(List<Subject>) getSubjectTabController,
    Function(int) onSubjectSelected,
    bool isOwnProfile,
    bool isEditingAboutMe,
    TextEditingController aboutMeController,
    GlobalKey profileDetailsKey,
    Function(UserProfile)? onProfileUpdated,
  ) {
    final subjectProvider = context.watch<SubjectProvider>();
    final sectionProvider = context.watch<SectionProvider>();
    final loggedInUser = context.watch<UserProfileProvider>().userProfile;

    if (subjectProvider.isLoading || sectionProvider.isLoading) {
      return [
        const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (loggedInUser == null) {
      return [
        const SliverFillRemaining(
          child: Center(child: Text('Authentication error: User not found.')),
        ),
      ];
    }

    final subjects = localFilteredSubjects;
    if (subjects.isEmpty && currentCategory == 'المواد') {
      return [
        const SliverFillRemaining(
          child: Center(child: Text('لا يوجد مواد متاحة حالياً')),
        ),
      ];
    }

    if (selectedSubjectIndex >= subjects.length) {
      selectedSubjectIndex = 0;
    }

    switch (currentCategory) {
      case 'المواد':
        if (subjects.isEmpty) {
          return [
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('لا توجد مواد متاحة حالياً')),
            ),
          ];
        }

        return [
          // Subjects as tabs using TabBar style
          SliverToBoxAdapter(
            child: Column(
              children: [
                // TabBar for subjects
                if (subjects.isNotEmpty) ...[
                  Builder(
                    builder: (context) {
                      // Get properly initialized TabController
                      final tabController = getSubjectTabController(subjects);

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(
                            Responsive.space(context, size: Space.large),
                          ),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        child: TabBar(
                          controller: tabController,
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
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.medium,
                            ),
                            fontWeight: FontWeight.w600,
                            fontFamily: 'NotoSansArabic',
                          ),
                          unselectedLabelStyle: TextStyle(
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.medium,
                            ),
                            fontWeight: FontWeight.w500,
                            fontFamily: 'NotoSansArabic',
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: Responsive.space(
                              context,
                              size: Space.medium,
                            ),
                          ),
                          tabs:
                              subjects
                                  .map((subject) => Tab(text: subject.name))
                                  .toList(),
                        ),
                      );
                    },
                  ),
                  // TabBarView for subject content
                  Builder(
                    builder: (context) {
                      // Get properly initialized TabController
                      final tabController = getSubjectTabController(subjects);
                      final screenHeight = MediaQuery.of(context).size.height;
                      final availableHeight =
                          screenHeight * 0.5; // Use 50% of screen height

                      return SizedBox(
                        height: availableHeight,
                        child: TabBarView(
                          controller: tabController,
                          children:
                              subjects.map((subject) {
                                return _buildSubjectContent(
                                  context,
                                  subject,
                                  sectionProvider,
                                  loggedInUser,
                                  displayedProfile,
                                );
                              }).toList(),
                        ),
                      );
                    },
                  ),
                ] else
                  Padding(
                    padding: EdgeInsets.all(
                      Responsive.space(context, size: Space.medium),
                    ),
                    child: Text(
                      'لا توجد مواد متاحة',
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.medium,
                        ),
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: Divider(indent: 4, endIndent: 1)),
        ];
      case 'عن المعيد':
        return [
          // Add DoctorDetails at the top of the about tab
          SliverToBoxAdapter(
            child: Container(
              key: profileDetailsKey,
              child: DoctorDetails(userProfile: displayedProfile),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: Responsive.space(context, size: Space.large),
            ),
          ),
          // Enhanced About Me section
          SliverToBoxAdapter(
            child: AssistantAboutSection(
              userProfile: displayedProfile,
              isOwnProfile: isOwnProfile,
              onProfileUpdated: onProfileUpdated,
            ),
          ),
        ];
      default:
        return [
          const SliverFillRemaining(
            child: Center(child: Text('Unknown Category')),
          ),
        ];
    }
  }

  static Widget _buildSubjectContent(
    BuildContext context,
    Subject subject,
    SectionProvider sectionProvider,
    UserProfile? loggedInUser,
    UserProfile displayedProfile,
  ) {
    // Filter sections that belong to this assistant AND are for this subject
    final sectionsForSubject =
        sectionProvider.sections
            .where(
              (s) =>
                  s.assistantId == displayedProfile.id &&
                  s.subjectId == subject.id,
            )
            .toList();

    if (sectionProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (sectionsForSubject.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(
            Responsive.space(context, size: Space.medium),
          ),
          child: Text(
            'لا توجد عناصر في هذه المادة',
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.medium),
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, size: Space.small),
        vertical: Responsive.space(context, size: Space.small),
      ),
      itemCount: sectionsForSubject.length,
      itemBuilder:
          (context, index) => SectionCard(
            section: sectionsForSubject[index],
            subjectName: subject.name,
            isCurrentUserSection:
                false, // We'll handle this differently if needed
          ),
    );
  }
}
