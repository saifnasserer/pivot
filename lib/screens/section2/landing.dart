import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pivot/providers/announcement_provider.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/section2/category_section.dart';
import 'package:provider/provider.dart';
import 'package:pivot/screens/models/card_model.dart';
import 'package:pivot/screens/models/search_card.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class Landing extends StatefulWidget {
  const Landing({super.key});
  // = 'landing';

  @override
  State<Landing> createState() => LandingState();
}

class LandingState extends State<Landing> {
  String? _userDepartment;

  final TextEditingController _userSearchController = TextEditingController();
  final PageController _pageController = PageController(); // Add this line
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
              // Category selector gets its own row
              Padding(
                padding: EdgeInsets.symmetric(
                  vertical: Responsive.space(context, size: Space.medium),
                  horizontal: Responsive.space(context, size: Space.small),
                ),
                child: CategorySection(
                  userDepartment: normalizedDepartment,
                  onCategoryChanged: (category) {
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
                      departmentCode = 'اخبار قسم $category';
                    } else if (category == 'اخبار النهاردة') {
                      timeFilter = 'today';
                      if (_userDepartment != null) {
                        String userDeptTag;
                        if (_userDepartment!.startsWith('اخبار قسم ')) {
                          userDeptTag = _userDepartment!;
                        } else {
                          userDeptTag = 'اخبار قسم $_userDepartment';
                        }
                        departmentCode = 'today_mixed:$userDeptTag';
                      } else {
                        departmentCode = 'عام';
                      }
                    } else if (category == 'عام') {
                      departmentCode = 'عام';
                      timeFilter = null;
                    } else {
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
              // Main content
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
                        controller: _pageController, // Add this line
                        itemCount: sortedAnnouncements.length,
                        scrollDirection: Axis.vertical,
                        physics: const ClampingScrollPhysics(),
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
                              pageController:
                                  _pageController, // Pass controller
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
        floatingActionButton: SpeedDial(
          icon: Icons.menu,
          activeIcon: Icons.close,
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          childPadding: EdgeInsets.all(4),
          children: [
            SpeedDialChild(
              child: Icon(
                Icons.person_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              backgroundColor: Colors.black,
              shape: const CircleBorder(),
              labelWidget: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(
                    Responsive.space(context, size: Space.large),
                  ),
                ),
                alignment: Alignment.center,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: Responsive.space(context, size: Space.small),
                    horizontal: Responsive.space(context, size: Space.medium),
                  ),
                  child: Text(
                    'حسابي',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              onTap: () {
                final userProfileProvider = Provider.of<UserProfileProvider>(
                  context,
                  listen: false,
                );
                if (userProfileProvider.loggedInUserProfile?.role ==
                    'Super Admin') {
                  Navigator.pushNamed(context, '/super-admin-panel');
                } else {
                  Navigator.pushNamed(context, '/profile');
                }
              },
            ),
            SpeedDialChild(
              child: Icon(Icons.search, color: Colors.white, size: 20),
              backgroundColor: Colors.black,
              shape: const CircleBorder(),
              labelWidget: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(
                    Responsive.space(context, size: Space.large),
                  ),
                ),
                alignment: Alignment.center,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: Responsive.space(context, size: Space.small),
                    horizontal: Responsive.space(context, size: Space.medium),
                  ),
                  child: Text(
                    'بحث',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              onTap: () => showUserSearchModal(context),
            ),
            SpeedDialChild(
              child: Icon(
                Icons.add_circle_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              backgroundColor: Colors.black,
              shape: const CircleBorder(),
              labelWidget: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(
                    Responsive.space(context, size: Space.large),
                  ),
                ),
                alignment: Alignment.center,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: Responsive.space(context, size: Space.small),
                    horizontal: Responsive.space(context, size: Space.medium),
                  ),
                  child: Text(
                    'إدارة',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              visible:
                  Provider.of<UserProfileProvider>(
                    context,
                    listen: false,
                  ).loggedInUserProfile?.role !=
                  'Student',
              onTap: () {
                Navigator.pushNamed(context, '/admin-control');
              },
            ),
            SpeedDialChild(
              child: Icon(
                FontAwesomeIcons.handshake,
                color: Colors.white,
                size: 20,
              ),
              backgroundColor: Colors.black,
              shape: const CircleBorder(),
              labelWidget: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(
                    Responsive.space(context, size: Space.large),
                  ),
                ),
                alignment: Alignment.center,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: Responsive.space(context, size: Space.small),
                    horizontal: Responsive.space(context, size: Space.medium),
                  ),
                  child: Text(
                    'تكوين فريق',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              onTap: () {
                Navigator.pushNamed(context, '/teams');
              },
            ),
          ],
        ),
      ),
    );
  }
}
