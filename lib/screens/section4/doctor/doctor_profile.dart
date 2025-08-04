import 'package:flutter/material.dart';
import 'package:pivot/models/lecture_model.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/models/subject_model.dart';
import 'package:pivot/providers/doctor_subject_provider.dart';
import 'package:pivot/providers/subject_provider.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/widgets/unified_dialog.dart';
import 'package:pivot/screens/section4/doctor/add_subject_link_dialog.dart';
import 'package:pivot/screens/section4/doctor/doctor_categories.dart';
import 'package:pivot/screens/section4/doctor_details.dart';
import 'package:pivot/screens/section4/doctor/edit_about_route.dart';
import 'package:pivot/screens/models/category_model.dart';
import 'package:pivot/screens/models/material_links_widget.dart';
import 'package:pivot/screens/section3/profile_widgets/Profile_options.dart';
import 'package:pivot/screens/section3/subject_selection_screen.dart';
import 'package:provider/provider.dart';
import 'package:pivot/widgets/no_internet_message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorProfile extends StatefulWidget {
  // = 'doctor';
  const DoctorProfile({super.key});

  @override
  State<DoctorProfile> createState() => _DoctorProfileState();
}

class _DoctorProfileState extends State<DoctorProfile>
    with TickerProviderStateMixin {
  UserProfile? _displayedProfile;
  String? _previousProfileId;
  late ScrollController _scrollController;
  late TabController _subjectTabController;
  String _currentCategory = 'المواد';
  int _selectedSubjectIndex = 0;
  List<Subject> _localFilteredSubjects =
      []; // Local filtered subjects for this doctor
  final GlobalKey _profileDetailsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(); // Initialize scroll controller
    _subjectTabController = TabController(
      length: 0,
      vsync: this,
    ); // Will be updated when subjects are loaded
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _subjectTabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final argument = ModalRoute.of(context)?.settings.arguments;
    UserProfile? profileToShow;

    if (argument is UserProfile) {
      profileToShow = argument;
    } else {
      profileToShow = context.watch<UserProfileProvider>().userProfile;
    }

    if (profileToShow != null && profileToShow.id != _previousProfileId) {
      _displayedProfile = profileToShow;
      _previousProfileId = profileToShow.id;
      _subjectTabController.dispose(); // Dispose old controller
      _subjectTabController = TabController(
        length: 0, // Reset length
        vsync: this,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _fetchInitialData(profileToShow!);
        }
      });
    }
  }

  void _fetchInitialData(UserProfile userProfile) {
    if (!mounted) return;

    print(
      '_fetchInitialData called for user: ${userProfile.name} (${userProfile.role})',
    );
    print('Teaching subjects: ${userProfile.teachingSubjects}');

    // Use a safer approach to access providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      try {
        final subjectProvider = Provider.of<SubjectProvider>(
          context,
          listen: false,
        );

        // Use fetchAndFilterSubjects to show only the doctor's teaching subjects
        subjectProvider.fetchAndFilterSubjects(userProfile).then((_) {
          if (mounted) {
            try {
              final subjects = subjectProvider.filteredSubjects;
              print('Filtered subjects count: ${subjects.length}');
              print(
                'Filtered subjects: ${subjects.map((s) => s.name).toList()}',
              );

              // Update local filtered subjects
              setState(() {
                _localFilteredSubjects = subjects;
              });

              if (subjects.isNotEmpty) {
                _updateSubjectTabController(subjects);
                _onSubjectSelected(0, fetchLectures: true);
              }
            } catch (e) {
              // Provider might be disposed, ignore the error
              print('Provider access error in callback: $e');
            }
          }
        });
      } catch (e) {
        // Provider might be disposed, ignore the error
        print('Provider access error: $e');
      }
    });
  }

  void _onMainCategoryChanged(String category) {
    setState(() {
      _currentCategory = category;
    });
  }

  void _onSubjectSelected(int index, {bool fetchLectures = true}) {
    setState(() {
      _selectedSubjectIndex = index;
    });
    if (fetchLectures) {
      final subjects = _localFilteredSubjects; // Use local filtered subjects
      if (subjects.isNotEmpty && index < subjects.length) {
        final subjectId = subjects[index].id;
        final doctorId = _displayedProfile!.id;
        context.read<DoctorSubjectProvider>().fetchLecturesForSubject(
          doctorId,
          subjectId,
        );
      }
    }
  }

  // Update TabController when subjects are loaded
  void _updateSubjectTabController(List<Subject> subjects) {
    if (_subjectTabController.length != subjects.length) {
      _subjectTabController.dispose();
      _subjectTabController = TabController(
        length: subjects.length,
        vsync: this,
        initialIndex:
            subjects.isNotEmpty
                ? subjects.length - 1
                : 0, // Start with last tab (rightmost)
      );
      _subjectTabController.addListener(() {
        if (_subjectTabController.indexIsChanging) {
          _onSubjectSelected(_subjectTabController.index);
        }
      });
    }
  }

  // Get properly initialized TabController for subjects
  TabController _getSubjectTabController(List<Subject> subjects) {
    print('_getSubjectTabController called with ${subjects.length} subjects');
    print('Current TabController length: ${_subjectTabController.length}');
    print('Subject names: ${subjects.map((s) => s.name).toList()}');

    if (_subjectTabController.length != subjects.length) {
      print('TabController length mismatch, recreating...');
      _subjectTabController.dispose();
      _subjectTabController = TabController(
        length: subjects.length,
        vsync: this,
        initialIndex:
            subjects.isNotEmpty
                ? subjects.length - 1
                : 0, // Start with last tab
      );
      print(
        'New TabController created with length: ${_subjectTabController.length}',
      );
      _subjectTabController.addListener(() {
        if (_subjectTabController.indexIsChanging) {
          _onSubjectSelected(_subjectTabController.index);
        }
      });
    } else {
      print('TabController length matches, reusing existing');
    }
    return _subjectTabController;
  }

  Widget _buildSubjectContent(
    Subject subject,
    DoctorSubjectProvider doctorSubjectProvider,
    UserProfile? loggedInUser,
  ) {
    final lectures = doctorSubjectProvider.lectures;

    if (doctorSubjectProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (doctorSubjectProvider.error != null) {
      return Center(child: Text(doctorSubjectProvider.error!));
    }

    if (lectures.isEmpty) {
      return Center(child: Text('لا توجد عناصر في هذه المادة'));
    }

    return ListView.builder(
      itemCount: lectures.length,
      itemBuilder:
          (context, index) => SubjectModel(
            lecture: lectures[index],
            canEdit:
                loggedInUser?.role != 'Student' &&
                loggedInUser?.role != 'miniProfessor',
          ),
    );
  }

  Future<void> _showAddLectureDialog() async {
    final userProfile = _displayedProfile;
    final subjects = _localFilteredSubjects; // Use local filtered subjects
    if (userProfile == null) return;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AddSubjectLinkDialog(subjects: subjects),
    );

    if (result != null) {
      final newLecture = Lecture(
        id: '', // Firestore will generate
        title: result['title']!,
        subjectId: result['subjectId']!,
        doctorId: userProfile.id,
        categoryName: 'المحاضرات', // Or determine dynamically
        links: [],
      );
      await context.read<DoctorSubjectProvider>().addLecture(newLecture);
    }
  }

  List<Widget> _getCategoryContentSlivers(BuildContext context) {
    final loggedInUser = context.watch<UserProfileProvider>().userProfile;
    final isOwnProfile = loggedInUser?.id == _displayedProfile?.id;
    final userProfile = _displayedProfile;

    if (userProfile == null) {
      return [const SliverToBoxAdapter(child: SizedBox.shrink())];
    }

    final subjectProvider = context.watch<SubjectProvider>();
    final doctorSubjectProvider = context.watch<DoctorSubjectProvider>();

    switch (_currentCategory) {
      case 'المواد':
        final subjects = _localFilteredSubjects; // Use local filtered subjects

        print('=== UI Debug ===');
        print('Current category: $_currentCategory');
        print('Subjects in UI: ${subjects.length}');
        print('Subject names in UI: ${subjects.map((s) => s.name).toList()}');
        print('Subject IDs in UI: ${subjects.map((s) => s.id).toList()}');

        if (subjects.isEmpty) {
          return [
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('لا توجد مواد متاحة حالياً')),
            ),
          ];
        }

        final doctorSubjectProvider = context.watch<DoctorSubjectProvider>();
        final lectures = doctorSubjectProvider.lectures;

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
                      final tabController = _getSubjectTabController(subjects);

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
                      final tabController = _getSubjectTabController(subjects);

                      print('TabBarView Debug:');
                      print('  TabController length: ${tabController.length}');
                      print('  Subjects count: ${subjects.length}');
                      print('  TabBarView children count: ${subjects.length}');

                      return SizedBox(
                        height: 400, // Fixed height for TabBarView
                        child: TabBarView(
                          controller: tabController,
                          children:
                              subjects.map((subject) {
                                return _buildSubjectContent(
                                  subject,
                                  doctorSubjectProvider,
                                  loggedInUser,
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
          if (doctorSubjectProvider.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
          // else if (doctorSubjectProvider.error != null)
          //   SliverFillRemaining(
          //     child: Center(child: Text(doctorSubjectProvider.error!)),
          //   )
          // else if (lectures.isEmpty)
          //   SliverToBoxAdapter(
          //     child: Padding(
          //       padding: Responsive.padding(context, size: Space.medium),
          //       child: Center(child: Text('لا توجد عناصر في هذه المادة')),
          //     ),
          //   )
          // else
          //   SliverList(
          //     delegate: SliverChildBuilderDelegate(
          //       (context, index) => SubjectModel(
          //         lecture: lectures[index],
          //         canEdit:
          //             loggedInUser?.role != 'Student' &&
          //             loggedInUser?.role != 'miniProfessor',
          //       ),
          //       childCount: lectures.length,
          //     ),
          //   ),
        ];
      case 'عن الدكتور':
        return [
          // Add DoctorDetails at the top of the about tab
          SliverToBoxAdapter(
            child: Container(
              key: _profileDetailsKey,
              child: DoctorDetails(userProfile: userProfile),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: Responsive.space(context, size: Space.large),
            ),
          ),
          // Enhanced About Me section
          SliverToBoxAdapter(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: _buildEnhancedAboutSection(
                context,
                userProfile,
                isOwnProfile,
              ),
            ),
          ),
        ];
      default:
        return [
          const SliverFillRemaining(
            child: Center(child: Text('لا يوجد محتوى متاح حالياً')),
          ),
        ];
    }
  }

  Widget _buildAboutMeDisplay(
    BuildContext context,
    UserProfile userProfile,
    bool canEdit,
  ) {
    return Padding(
      padding: Responsive.padding(context, size: Space.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'عن الدكتور',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.medium),
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (canEdit)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditAboutScreen(context, userProfile),
                ),
            ],
          ),
          SizedBox(height: Responsive.space(context, size: Space.small)),
          Text(
            userProfile.aboutMe.isNotEmpty
                ? userProfile.aboutMe
                : 'لم يتم تقديمه بعد.',
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedAboutSection(
    BuildContext context,
    UserProfile userProfile,
    bool canEdit,
  ) {
    return Padding(
      padding: Responsive.padding(context, size: Space.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // About Me Section
          _buildAboutMeSection(context, userProfile, canEdit),
          SizedBox(height: Responsive.space(context, size: Space.large)),

          // Social Media Section
          _buildSocialMediaSection(context, userProfile, canEdit),
          SizedBox(height: Responsive.space(context, size: Space.large)),

          // Contact Information Section
          _buildContactInfoSection(context, userProfile),
        ],
      ),
    );
  }

  Widget _buildAboutMeSection(
    BuildContext context,
    UserProfile userProfile,
    bool canEdit,
  ) {
    return Container(
      padding: Responsive.padding(context, size: Space.medium),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.large),
        ),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'نبذة عن الدكتور',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.medium),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (canEdit)
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.black54),
                  onPressed: () => _showEditAboutScreen(context, userProfile),
                ),
            ],
          ),
          SizedBox(height: Responsive.space(context, size: Space.small)),
          Text(
            userProfile.aboutMe.isNotEmpty
                ? userProfile.aboutMe
                : 'لم يتم تقديمه بعد.',
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.small),
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditAboutScreen(
    BuildContext context,
    UserProfile userProfile,
  ) async {
    print('Opening edit about screen for user: ${userProfile.id}');
    final result = await Navigator.push(
      context,
      AnimatedEditAboutRoute(
        userProfile: userProfile,
        initialAboutText: userProfile.aboutMe,
      ),
    );

    print('Edit about screen result: $result');
    // If the edit was successful, update the displayed profile
    if (result == true && mounted) {
      print('Updating displayed profile after successful edit');
      final userProfileProvider = context.read<UserProfileProvider>();

      // Force refresh by fetching from Firestore directly
      try {
        final doc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userProfile.id)
                .get();

        if (doc.exists) {
          final updatedProfile = UserProfile.fromJson(doc.data()!);
          print('Updated profile about: ${updatedProfile.aboutMe}');
          setState(() {
            _displayedProfile = updatedProfile;
          });
        } else {
          print('Document does not exist');
        }
      } catch (e) {
        print('Error fetching updated profile: $e');
      }
    } else {
      print('Edit was not successful or widget not mounted');
    }
  }

  Widget _buildSocialMediaSection(
    BuildContext context,
    UserProfile userProfile,
    bool canEdit,
  ) {
    final loggedInUser = context.watch<UserProfileProvider>().userProfile;
    final isOwnProfile = loggedInUser?.id == userProfile.id;
    final canEditSocial =
        isOwnProfile ||
        loggedInUser?.role == 'Admin' ||
        loggedInUser?.role == 'Super Admin';

    // Only show the section if there are social media links OR if user can add them
    if (userProfile.socialMediaLinks.isEmpty && !canEditSocial) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: Responsive.padding(context, size: Space.medium),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.large),
        ),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'وسائل التواصل الاجتماعي',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.medium),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (canEditSocial)
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.black54),
                  onPressed: () {
                    _showSocialMediaDialog(context, userProfile);
                  },
                ),
            ],
          ),
          SizedBox(height: Responsive.space(context, size: Space.small)),

          // Social Media Links Display
          _buildSocialMediaLinksDisplay(context, userProfile),
        ],
      ),
    );
  }

  Widget _buildSocialMediaLinksDisplay(
    BuildContext context,
    UserProfile userProfile,
  ) {
    final loggedInUser = context.watch<UserProfileProvider>().userProfile;
    final isOwnProfile = loggedInUser?.id == userProfile.id;
    final canEditSocial =
        isOwnProfile ||
        loggedInUser?.role == 'Admin' ||
        loggedInUser?.role == 'Super Admin';

    if (userProfile.socialMediaLinks.isEmpty) {
      if (canEditSocial) {
        // Show helpful message for users who can add links
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'لا توجد روابط تواصل اجتماعي مضافة.',
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.small),
                color: Colors.black54,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: Responsive.space(context, size: Space.small)),
            Text(
              'اضغط على زر التعديل لإضافة روابط التواصل الاجتماعي',
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.small),
                color: Colors.black38,
              ),
            ),
          ],
        );
      } else {
        // This shouldn't happen since we check this in the parent method
        return const SizedBox.shrink();
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...userProfile.socialMediaLinks.map(
          (link) => _buildSocialMediaLink(context, link),
        ),
      ],
    );
  }

  Widget _buildSocialMediaLink(BuildContext context, SocialMediaLink link) {
    IconData getIconForPlatform(String platform) {
      switch (platform.toLowerCase()) {
        case 'facebook':
          return Icons.facebook;
        case 'twitter':
          return Icons.flutter_dash; // Twitter icon
        case 'linkedin':
          return Icons.work;
        case 'instagram':
          return Icons.camera_alt;
        case 'youtube':
          return Icons.play_circle;
        case 'github':
          return Icons.code;
        default:
          return Icons.link;
      }
    }

    Color getColorForPlatform(String platform) {
      switch (platform.toLowerCase()) {
        case 'facebook':
          return Colors.blue[600]!;
        case 'twitter':
          return Colors.lightBlue[400]!;
        case 'linkedin':
          return Colors.blue[700]!;
        case 'instagram':
          return Colors.purple[400]!;
        case 'youtube':
          return Colors.red[600]!;
        case 'github':
          return Colors.black87;
        default:
          return Colors.grey[600]!;
      }
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: Responsive.space(context, size: Space.small),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(
              Responsive.space(context, size: Space.small),
            ),
            decoration: BoxDecoration(
              color: getColorForPlatform(link.platform),
              borderRadius: BorderRadius.circular(
                Responsive.space(context, size: Space.medium),
              ),
            ),
            child: Icon(
              getIconForPlatform(link.platform),
              color: Colors.white,
              size: Responsive.text(context, size: TextSize.medium),
            ),
          ),
          SizedBox(width: Responsive.space(context, size: Space.small)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  link.platform,
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.small),
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (link.displayName != null)
                  Text(
                    link.displayName!,
                    style: TextStyle(
                      fontSize: Responsive.text(context, size: TextSize.small),
                      color: Colors.black54,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.open_in_new, size: 16),
            onPressed: () {
              // TODO: Open URL in browser
            },
            color: Colors.black54,
          ),
        ],
      ),
    );
  }

  void _showSocialMediaDialog(BuildContext context, UserProfile userProfile) {
    final TextEditingController platformController = TextEditingController();
    final TextEditingController urlController = TextEditingController();
    final TextEditingController displayNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return UnifiedDialog(
              title: 'إضافة رابط التواصل الاجتماعي',
              subtitle: 'أضف رابط منصة التواصل الاجتماعي الخاصة بك',
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  UnifiedFormField(
                    controller: platformController,
                    label: 'المنصة',
                    hint: 'مثال: Facebook, Twitter, LinkedIn',
                  ),
                  SizedBox(
                    height: Responsive.space(context, size: Space.medium),
                  ),
                  UnifiedFormField(
                    controller: urlController,
                    label: 'الرابط',
                    hint: 'https://www.facebook.com/username',
                    keyboardType: TextInputType.url,
                  ),
                  SizedBox(
                    height: Responsive.space(context, size: Space.medium),
                  ),
                  UnifiedFormField(
                    controller: displayNameController,
                    label: 'الاسم المعروض',
                    hint: 'اختياري - اسم معروض للرابط',
                  ),
                ],
              ),
              confirmText: 'إضافة',
              confirmIcon: Icons.add_link,
              onConfirm: () async {
                if (platformController.text.isNotEmpty &&
                    urlController.text.isNotEmpty) {
                  final newLink = SocialMediaLink(
                    platform: platformController.text.trim(),
                    url: urlController.text.trim(),
                    displayName:
                        displayNameController.text.trim().isEmpty
                            ? null
                            : displayNameController.text.trim(),
                  );

                  final updatedLinks = [
                    ...userProfile.socialMediaLinks,
                    newLink,
                  ];

                  try {
                    await context
                        .read<UserProfileProvider>()
                        .updateSocialMediaLinks(userProfile.id, updatedLinks);

                    if (mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('تم إضافة الرابط بنجاح'),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              Responsive.space(context, size: Space.large),
                            ),
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('فشل في إضافة الرابط: $e'),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              Responsive.space(context, size: Space.large),
                            ),
                          ),
                        ),
                      );
                    }
                  }
                }
              },
              onCancel: () => Navigator.of(context).pop(),
            );
          },
        );
      },
    );
  }

  Widget _buildContactInfoSection(
    BuildContext context,
    UserProfile userProfile,
  ) {
    return Container(
      padding: Responsive.padding(context, size: Space.medium),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.large),
        ),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'معلومات التواصل',
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.medium),
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: Responsive.space(context, size: Space.small)),

          // Email with icon
          if (userProfile.email != null && userProfile.email!.isNotEmpty)
            _buildContactRow(
              Icons.email_outlined,
              'البريد الإلكتروني',
              userProfile.email!,
              () {
                // Could add email action here
              },
            ),

          // Role information
          _buildContactRow(
            Icons.person_outline,
            'الدور',
            _getRoleDisplayName(userProfile.role),
            null,
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(
    IconData icon,
    String label,
    String value,
    VoidCallback? onTap,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: Responsive.space(context, size: Space.small),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: Responsive.text(context, size: TextSize.medium),
            color: Colors.black54,
          ),
          SizedBox(width: Responsive.space(context, size: Space.small)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.small),
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.small),
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            IconButton(
              icon: Icon(Icons.open_in_new, size: 16),
              onPressed: onTap,
              color: Colors.black54,
            ),
        ],
      ),
    );
  }

  String _getRoleDisplayName(String role) {
    switch (role.toLowerCase()) {
      case 'professor':
        return 'أستاذ';
      case 'miniprofessor':
        return 'أستاذ مساعد';
      case 'student':
        return 'طالب';
      case 'admin':
        return 'مدير';
      case 'super admin':
        return 'مدير عام';
      default:
        return role;
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: Responsive.space(context, size: Space.small),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: Responsive.space(context, size: Space.large) * 3,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.small),
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.small),
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = _displayedProfile;
    final loggedInUser = context.watch<UserProfileProvider>().userProfile;
    final isOwnProfile = loggedInUser?.id == userProfile?.id;

    if (userProfile == null) {
      return NoInternetMessage(
        child: Scaffold(
          backgroundColor: Colors.white,
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return NoInternetMessage(
      child: Scaffold(
        backgroundColor: Colors.white,
        floatingActionButton:
            loggedInUser?.role != 'Student' &&
                    loggedInUser?.role != 'miniProfessor' &&
                    _currentCategory == '\u0627\u0644\u0645\u0648\u0627\u062f'
                ? FloatingActionButton(
                  onPressed: _showAddLectureDialog,
                  backgroundColor: Colors.black,
                  child: const Icon(Icons.add),
                )
                : null,
        body: Padding(
          padding: Responsive.paddingHorizontal(context),
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Add top padding for safe area
              SliverToBoxAdapter(
                child: SizedBox(
                  height:
                      MediaQuery.of(context).padding.top +
                      Responsive.space(context, size: Space.small),
                ),
              ),
              // Categories as tabs with integrated back button
              SliverToBoxAdapter(
                child: DoctorCategories(
                  onCategoryChanged: _onMainCategoryChanged,
                  showBackButton: true,
                  showEditButton: _shouldShowEditIcon(),
                  showMenuButton: isOwnProfile,
                  onBackPressed: () => Navigator.pop(context),
                  onEditPressed: _editTeachingSubjects,
                  onMenuPressed: () => profile_options(context),
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

  // Check if Super Admin should see edit icon
  bool _shouldShowEditIcon() {
    final loggedInUser =
        context.watch<UserProfileProvider>().loggedInUserProfile;
    final isSuperAdmin = loggedInUser?.role == 'Super Admin';
    final isViewingOtherUser = loggedInUser?.id != _displayedProfile?.id;
    final isProfessorOrMiniProfessor =
        _displayedProfile?.role == 'Professor' ||
        _displayedProfile?.role == 'miniProfessor';

    return isSuperAdmin && isViewingOtherUser && isProfessorOrMiniProfessor;
  }

  // Handle edit teaching subjects
  Future<void> _editTeachingSubjects() async {
    if (_displayedProfile == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => SubjectSelectionScreen(
              previouslySelectedIds: _displayedProfile!.teachingSubjects,
              targetUserId: _displayedProfile!.id,
              targetUserRole: _displayedProfile!.role,
            ),
      ),
    );

    if (result == true && mounted) {
      // Refresh the displayed profile data
      final userProfileProvider = Provider.of<UserProfileProvider>(
        context,
        listen: false,
      );

      // Fetch updated profile data
      final updatedProfile = await userProfileProvider.getUserProfileById(
        _displayedProfile!.id,
      );
      if (updatedProfile != null) {
        setState(() {
          _displayedProfile = updatedProfile;
        });
        _fetchInitialData(updatedProfile);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديث المواد المدرسية بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
