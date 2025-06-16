import 'package:flutter/material.dart';
import 'package:pivot/models/section_model.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/providers/section_provider.dart';
import 'package:pivot/providers/subject_provider.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/section3/profile_widgets/Profile_options.dart';
import 'package:pivot/screens/section4/doctor_details.dart';
import 'package:provider/provider.dart';
import 'add_edit_section_dialog.dart';
import 'assistant_categories.dart';
import 'assistant_subjects.dart';

class AssistantProfile extends StatefulWidget {
  static const String id = 'section';
  final bool isAdmin;

  const AssistantProfile({super.key, this.isAdmin = false});

  @override
  State<AssistantProfile> createState() => _AssistantProfileState();
}

class _AssistantProfileState extends State<AssistantProfile> {
  String _currentCategory = 'المواد';
  int _selectedSubjectIndex = 0;
  UserProfile? _previousUserProfile;
  bool _isEditingAboutMe = false;
  late TextEditingController _aboutMeController;

  @override
  void initState() {
    super.initState();
    _aboutMeController = TextEditingController();
  }

  @override
  void dispose() {
    _aboutMeController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userProfile = context.watch<UserProfileProvider>().userProfile;

    // Fetch data only if the user profile has changed.
    if (userProfile != null && userProfile != _previousUserProfile) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _fetchData(userProfile);
        }
      });
      if (!_isEditingAboutMe) {
        _aboutMeController.text = userProfile.aboutMe ?? '';
      }
      _previousUserProfile = userProfile;
    }
  }

  void _fetchData(UserProfile userProfile) {
    // Fetch subjects the user teaches
    context.read<SubjectProvider>().fetchAndFilterSubjects(userProfile);
    // Fetch sections for those subjects
    context.read<SectionProvider>().fetchSectionsForUserSubjects(
      userProfile.teachingSubjects,
    );
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

    if (subjectProvider.isLoading || sectionProvider.isLoading) {
      return [
        const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    final subjects = subjectProvider.filteredSubjects;
    if (subjects.isEmpty) {
      return [
        const SliverFillRemaining(
          child: Center(child: Text('لا يوجد مواد متاحة حالياً')),
        ),
      ];
    }

    if (_selectedSubjectIndex >= subjects.length) {
      _selectedSubjectIndex = 0;
    }

    final selectedSubject =
        subjects.isNotEmpty ? subjects[_selectedSubjectIndex] : null;

    switch (_currentCategory) {
      case 'المواد':
        final sectionsForSelectedSubject =
            selectedSubject != null
                ? sectionProvider.sections
                    .where((s) => s.subjectId == selectedSubject.id)
                    .toList()
                : [];

        return buildAssistantSubjects(
          context: context,
          subjects: subjects,
          selectedSubjectIndex: _selectedSubjectIndex,
          sections: sectionsForSelectedSubject.cast<Section>(),
          onCategorySelected: _onSubjectCategorySelected,
        );
      case 'عن المعيد':
        final userProfile = context.watch<UserProfileProvider>().userProfile;
        final loggedInUser =
            context.watch<UserProfileProvider>().loggedInUserProfile;
        final profileBeingViewed = userProfile;

        final bool isMiniProfessorProfile =
            profileBeingViewed?.role.toLowerCase() == 'miniprofessor';
        final bool isOwner = loggedInUser?.id == profileBeingViewed?.id;
        final bool isSuperAdmin =
            loggedInUser?.role.toLowerCase() == 'super admin';
        final bool canEdit =
            isMiniProfessorProfile && (isOwner || isSuperAdmin);

        return [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'عني',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_isEditingAboutMe)
                    _buildAboutMeEditor(context, userProfile!)
                  else
                    _buildAboutMeDisplay(context, userProfile, canEdit),
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

  Widget _buildAboutMeDisplay(
    BuildContext context,
    UserProfile? userProfile,
    bool canEdit,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          userProfile?.aboutMe ?? 'لا يوجد معلومات حالياً',
          style: const TextStyle(fontSize: 16, height: 1.5),
          textAlign: TextAlign.right,
        ),
        if (canEdit)
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                setState(() {
                  _isEditingAboutMe = true;
                });
              },
            ),
          ),
      ],
    );
  }

  Widget _buildAboutMeEditor(BuildContext context, UserProfile userProfile) {
    final userProfileProvider = Provider.of<UserProfileProvider>(
      context,
      listen: false,
    );
    return Column(
      children: [
        TextField(
          controller: _aboutMeController,
          maxLines: null,
          autofocus: true,
          textAlign: TextAlign.right,
          decoration: const InputDecoration(
            hintText: '...اخبرنا عن نفسك',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                setState(() {
                  _aboutMeController.text = userProfile.aboutMe ?? '';
                  _isEditingAboutMe = false;
                });
              },
            ),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () async {
                try {
                  await userProfileProvider.updateAboutMe(
                    userProfile.id,
                    _aboutMeController.text,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Successfully updated.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    setState(() {
                      _isEditingAboutMe = false;
                    });
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to update: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ],
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
                  subjects: subjects,
                  initialSubjectId: selectedSubject.id,
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
                  height: Responsive.space(context, size: Space.medium),
                ),
              ),
              SliverToBoxAdapter(
                child: AssistantCategories(
                  onCategoryChanged: _onMainCategoryChanged,
                ),
              ),
              // SliverToBoxAdapter(
              //   child: SizedBox(
              //     height: Responsive.space(context, size: Space.large),
              //   ),
              // ),
              const SliverToBoxAdapter(child: Divider(indent: 4, endIndent: 1)),
              ..._getCategoryContentSlivers(context),
            ],
          ),
        ),
      ),
    );
  }
}
