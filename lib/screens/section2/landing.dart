import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pivot/providers/announcement_provider.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/section2/admin_control.dart';
import 'package:pivot/screens/section2/category_section.dart';
import 'package:pivot/screens/section2/teams.dart';
import 'package:pivot/screens/section3/profile.dart';
import 'package:provider/provider.dart';
import 'package:pivot/screens/models/card_model.dart';
import 'package:pivot/screens/models/search_card.dart';

class Landing extends StatefulWidget {
  const Landing({super.key});
  static const String id = 'landing';

  @override
  State<Landing> createState() => LandingState();
}

class LandingState extends State<Landing> {
  String? _userDepartment;

  final TextEditingController _userSearchController = TextEditingController();
  @override
  void initState() {
    super.initState();
    // The AuthWrapper now guarantees the user profile is ready before this screen is built.
    // We can now safely trigger the initial fetch for 'Today''s News'.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProfileProvider = Provider.of<UserProfileProvider>(
        context,
        listen: false,
      );
      _userDepartment = userProfileProvider.loggedInUserProfile?.department;

      final announcementProvider = Provider.of<AnnouncementProvider>(
        context,
        listen: false,
      );
      announcementProvider.fetchAnnouncements(
        timeFilter: 'today',
        department: _userDepartment,
      );
    });
  }

  @override
  void dispose() {
    _userSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  vertical: Responsive.space(context, size: Space.medium),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: CategorySection(
                        onCategoryChanged: (category) {
                          final announcementProvider =
                              Provider.of<AnnouncementProvider>(
                                context,
                                listen: false,
                              );

                          String? departmentCode;
                          String? timeFilter;

                          if (category.startsWith('اخبار قسم ')) {
                            departmentCode = category.split(' ').last;
                          } else if (category == 'اخبار النهاردة') {
                            timeFilter = 'today';
                            departmentCode =
                                _userDepartment; // Use stored department
                          } else if (category == 'اخبار الاسبوع') {
                            timeFilter = 'week';
                            departmentCode =
                                _userDepartment; // Use stored department
                          } else {
                            // This handles the "All News" case
                            departmentCode = null;
                            timeFilter = null;
                          }
                          announcementProvider.fetchAnnouncements(
                            department: departmentCode,
                            timeFilter: timeFilter,
                          );
                        },
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.pushNamed(context, TeamsScreen.id);
                      },
                      icon: const Icon(FontAwesomeIcons.magnet),
                    ),
                    Consumer<UserProfileProvider>(
                      builder: (context, userProfileProvider, child) {
                        final userRole =
                            userProfileProvider.loggedInUserProfile?.role;
                        // if (userRole != null && userRole == 'Super Admin') {
                        //   return IconButton(
                        //     icon: const Icon(
                        //       Icons.notifications_active_outlined,
                        //     ),
                        //     tooltip: 'Test Notifications',
                        //     onPressed: () {
                        //       Navigator.pushNamed(
                        //         context,
                        //         NotificationTestWidget.id,
                        //       );
                        //     },
                        //   );
                        // }
                        if (userRole != null && userRole != 'Student') {
                          return IconButton(
                            icon: const Icon(Icons.add_circle_outline_rounded),
                            onPressed: () {
                              Navigator.pushNamed(context, AdminControl.id);
                            },
                          );
                        } else {
                          return const SizedBox.shrink();
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.search),
                      tooltip: 'بحث',
                      onPressed: () => showUserSearchModal(context),
                    ),

                    Consumer<UserProfileProvider>(
                      builder: (context, userProfileProvider, child) {
                        return IconButton(
                          icon: const Icon(Icons.person_outline_rounded),
                          onPressed: () {
                            if (userProfileProvider.loggedInUserProfile?.role ==
                                'Super Admin') {
                              Navigator.pushNamed(
                                context,
                                '/super-admin-panel',
                              );
                            } else {
                              Navigator.pushNamed(context, Profile.id);
                            }
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(
                    Responsive.space(context, size: Space.small),
                  ),
                  child: Consumer<AnnouncementProvider>(
                    builder: (context, provider, child) {
                      if (provider.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (provider.announcements.isEmpty) {
                        return const Center(
                          child: Text(
                            'لا توجد أخبار لعرضها حاليًا',
                            style: TextStyle(fontSize: 18),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      // Sort pinned announcements to the top
                      final sortedAnnouncements = List.of(
                        provider.announcements,
                      )..sort((a, b) {
                        if (a.pinned == b.pinned) {
                          return b.timestamp.compareTo(a.timestamp);
                        }
                        return b.pinned ? 1 : -1;
                      });
                      return PageView.builder(
                        itemCount: sortedAnnouncements.length,
                        scrollDirection: Axis.vertical,
                        itemBuilder: (context, index) {
                          final announcement = sortedAnnouncements[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            child: CardModel(
                              id: announcement.id,
                              title: announcement.title,
                              date: announcement.date,
                              color: announcement.color,
                              description: announcement.description,
                              tags: announcement.tags,
                              imageUrls: announcement.imageUrls,
                              links: announcement.links,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
