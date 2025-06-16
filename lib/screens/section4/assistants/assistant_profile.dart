import 'package:flutter/material.dart';
import 'package:pivot/models/section_model.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/providers/subject_provider.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/models/subject_model.dart';
import 'package:pivot/screens/section4/doctor_details.dart';
import 'assistant_subjects.dart';
import 'assistant_categories.dart';
import 'package:provider/provider.dart';
import 'package:pivot/providers/section_provider.dart';
import 'add_edit_section_dialog.dart';
import 'package:pivot/screens/section3/profile_widgets/Profile_options.dart';

class AssistantProfile extends StatefulWidget {
  static const String id = 'section';
  final UserProfile userProfile;
  final bool isAdmin;

  const AssistantProfile({
    super.key,
    required this.userProfile,
    this.isAdmin = false,
  });

  @override
  State<AssistantProfile> createState() => _AssistantProfileState();
}

class _AssistantProfileState extends State<AssistantProfile> {
  String _currentCategory = 'المواد';
  int _selectedSubjectIndex = 0;
  UserProfile? _previousUserProfile;

  @override
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newProfile = Provider.of<UserProfileProvider>(context).userProfile;

    // With value equality implemented on UserProfile, we can now directly
    // compare the previous and new profile objects to detect any change.
    if (newProfile != _previousUserProfile) {
      if (newProfile != null) {
        _fetchData(newProfile);
      }
      // Update the previous profile state for the next check.
      _previousUserProfile = newProfile;
    }
  }

  void _fetchData(UserProfile userProfile) {
    final subjectIds = userProfile.teachingSubjects;
    // Fetch sections for the subjects the user teaches
    context.read<SectionProvider>().fetchSectionsForUserSubjects(subjectIds);
    // Fetch the subject details
    context.read<SubjectProvider>().fetchAndFilterSubjects(userProfile);
  }

  void _onMainCategoryChanged(String category) {
    setState(() {
      _currentCategory = category;
    });
  }

  void _onSubjectCategorySelected(int index) {
    setState(() {
      _selectedSubjectIndex = index;
    });
  }

  List<Widget> _getCategoryContentSlivers(BuildContext context) {
    final subjectProvider = context.watch<SubjectProvider>();
    final sectionProvider = context.watch<SectionProvider>();
    // Use the new `loggedInUserProfile` to get the currently authenticated user.
    final loggedInUser =
        context.watch<UserProfileProvider>().loggedInUserProfile;
    // The profile being viewed is passed to the widget's constructor.
    final profileBeingViewed = widget.userProfile;

    if (loggedInUser == null) {
      return [
        const SliverFillRemaining(
          child: Center(child: Text('User not logged in')),
        ),
      ];
    }

    if (subjectProvider.isLoading || sectionProvider.isLoading) {
      return [
        const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    final List<Subject> subjects = subjectProvider.filteredSubjects;

    switch (_currentCategory) {
      case 'المواد':
        if (subjects.isEmpty) {
          return [
            const SliverFillRemaining(
              child: Center(child: Text('لا يوجد مواد متاحة حالياً')),
            ),
          ];
        }
        // Ensure index is valid
        if (_selectedSubjectIndex >= subjects.length) {
          _selectedSubjectIndex = 0;
        }
        final Subject selectedSubject = subjects[_selectedSubjectIndex];
        final List<Section> sectionsForSelectedSubject =
            sectionProvider.sections
                .where((section) => section.subjectId == selectedSubject.id)
                .toList();

        return buildAssistantSubjects(
          context: context,
          subjects: subjects,
          selectedSubjectIndex: _selectedSubjectIndex,
          sections: sectionsForSelectedSubject,
          onCategorySelected: _onSubjectCategorySelected,
        );
      case 'عن المعيد':
        // Correctly determine if the edit button should be shown.
        final bool isMiniProfessorProfile =
            profileBeingViewed.role.toLowerCase() == 'miniprofessor';
        final bool isOwner = loggedInUser.id == profileBeingViewed.id;
        final bool isSuperAdmin =
            loggedInUser.role.toLowerCase() == 'super admin';
        final bool canEdit =
            isMiniProfessorProfile && (isOwner || isSuperAdmin);

        return [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'About',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (canEdit)
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed:
                              () => _showEditAboutMeDialog(
                                context,
                                profileBeingViewed,
                              ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profileBeingViewed.aboutMe.isNotEmpty
                        ? profileBeingViewed.aboutMe
                        : 'No information has been added yet.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
        ];
      default:
        return [
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('Unknown Category')),
          ),
        ];
    }
  }

  Future<void> _showEditAboutMeDialog(
    BuildContext context,
    UserProfile userProfile,
  ) async {
    final controller = TextEditingController(text: userProfile.aboutMe);
    final userProfileProvider = Provider.of<UserProfileProvider>(
      context,
      listen: false,
    );

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit About Me'),
          content: TextField(
            controller: controller,
            maxLines: null,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter information here...',
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () async {
                try {
                  // Correctly call `updateAboutMe` with both userId and the new text.
                  await userProfileProvider.updateAboutMe(
                    userProfile.id,
                    controller.text,
                  );
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Successfully updated.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = context.watch<UserProfileProvider>().userProfile;
    final subjects = context.watch<SubjectProvider>().filteredSubjects;
    final selectedSubject =
        subjects.isNotEmpty && _selectedSubjectIndex < subjects.length
            ? subjects[_selectedSubjectIndex]
            : null;

    if (userProfile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (userProfile.role.toLowerCase() == 'miniprofessor')
            IconButton(
              icon: const Icon(Icons.more_vert_sharp, color: Colors.black),
              onPressed: () => profile_options(context),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: () {
          if (selectedSubject != null) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AddEditSectionDialog(
                  subjects: subjects, // Pass the list of Subject objects
                  initialSubjectId: selectedSubject.id, // Pass the ID
                );
              },
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('الرجاء تحديد المادة أولاً')),
            );
          }
        },
        tooltip: 'إضافة سكشن جديد',
        child: const Icon(Icons.add, color: Colors.white),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: Responsive.paddingHorizontal(context),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: DoctorDetails(userProfile: userProfile),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: Responsive.space(context, size: Space.large),
                ),
              ),
              SliverToBoxAdapter(
                child: AssistantCategories(
                  onCategoryChanged: _onMainCategoryChanged,
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: Responsive.space(context, size: Space.large),
                ),
              ),
              const SliverToBoxAdapter(child: Divider(indent: 4, endIndent: 1)),
              ..._getCategoryContentSlivers(context),
            ],
          ),
        ),
      ),
    );
  }
}
