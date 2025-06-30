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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProfileProvider = Provider.of<UserProfileProvider>(
        context,
        listen: false,
      );
      _userDepartment = userProfileProvider.loggedInUserProfile?.department;

      // Normalize department for initial fetch
      String? normalizedDepartment;
      if (_userDepartment != null &&
          _userDepartment!.startsWith('اخبار قسم ')) {
        normalizedDepartment = _userDepartment!.replaceFirst('اخبار قسم ', '');
      } else {
        normalizedDepartment = _userDepartment;
      }

      final announcementProvider = Provider.of<AnnouncementProvider>(
        context,
        listen: false,
      );

      // Use normalizedDepartment for initial fetch
      String? departmentCode;
      if (normalizedDepartment != null) {
        departmentCode = 'today_mixed:اخبار قسم $normalizedDepartment';
      } else {
        departmentCode = 'عام';
      }

      announcementProvider.fetchAnnouncements(
        timeFilter: 'today',
        department: departmentCode,
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
    // Normalize the user department for category ordering
    String? normalizedDepartment;
    if (_userDepartment != null && _userDepartment!.startsWith('اخبار قسم ')) {
      normalizedDepartment = _userDepartment!.replaceFirst('اخبار قسم ', '');
    } else {
      normalizedDepartment = _userDepartment;
    }
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
                        userDepartment: normalizedDepartment,
                        onCategoryChanged: (category) {
                          debugPrint(
                            '[LANDING] Category changed to: $category',
                          );

                          final announcementProvider =
                              Provider.of<AnnouncementProvider>(
                                context,
                                listen: false,
                              );

                          String? departmentCode;
                          String? timeFilter;

                          if (category == 'SC' ||
                              category == 'AI' ||
                              category == 'CS' ||
                              category == 'IS' ||
                              category == 'General') {
                            // Convert short format to full format for filtering
                            departmentCode = 'اخبار قسم $category';
                            debugPrint(
                              '[LANDING] Department category - Department code: $departmentCode',
                            );
                          } else if (category == 'اخبار النهاردة') {
                            timeFilter = 'today';
                            // For today's news, we want to show announcements from user's department AND عام announcements
                            // We'll use a special format to pass both pieces of information
                            if (_userDepartment != null) {
                              // Convert user department to proper format if needed
                              String userDeptTag;
                              if (_userDepartment!.startsWith('اخبار قسم ')) {
                                userDeptTag = _userDepartment!;
                              } else {
                                userDeptTag = 'اخبار قسم $_userDepartment';
                              }
                              departmentCode = 'today_mixed:$userDeptTag';
                              debugPrint(
                                '[LANDING] Today\'s news - User dept tag: $userDeptTag',
                              );
                              debugPrint(
                                '[LANDING] Today\'s news - Department code: $departmentCode',
                              );
                            } else {
                              // Fallback to just عام announcements if no user department
                              departmentCode = 'عام';
                              debugPrint(
                                '[LANDING] Today\'s news - No user department, using عام',
                              );
                            }
                          } else if (category == 'عام') {
                            // General news - filter for announcements with 'عام' tag
                            departmentCode = 'عام';
                            timeFilter = null;
                            debugPrint(
                              '[LANDING] General category - Department code: $departmentCode',
                            );
                          } else {
                            // Default case - show all announcements
                            departmentCode = null;
                            timeFilter = null;
                            debugPrint(
                              '[LANDING] Default category - No filters',
                            );
                          }

                          debugPrint(
                            '[LANDING] Final parameters - Department: $departmentCode, TimeFilter: $timeFilter',
                          );

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
                        return Center(
                          child: Text(
                            'لا توجد أخبار لعرضها حاليًا',
                            style: TextStyle(
                              fontSize: Responsive.text(
                                context,
                                size: TextSize.medium,
                              ),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      // Sort announcements: pinned first, then by timestamp
                      final sortedAnnouncements = List.of(
                        provider.announcements,
                      );
                      sortedAnnouncements.sort((a, b) {
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
