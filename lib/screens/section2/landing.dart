import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pivot/providers/announcement_provider.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/section2/admin_control.dart';
import 'package:pivot/screens/section2/category_section.dart';
import 'package:pivot/screens/section3/profile.dart';
import 'package:pivot/screens/models/card_model.dart';
import 'package:provider/provider.dart';

class Landing extends StatefulWidget {
  const Landing({super.key});
  static const String id = 'landing';

  @override
  State<Landing> createState() => LandingState();
}

class LandingState extends State<Landing> {
  String? _userDepartment;

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
      _userDepartment = userProfileProvider.userProfile?.department;

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

                          debugPrint(
                            '[LANDING onCategoryChanged] Fetching with department: $departmentCode, timeFilter: $timeFilter',
                          );
                          announcementProvider.fetchAnnouncements(
                            department: departmentCode,
                            timeFilter: timeFilter,
                          );
                        },
                      ),
                    ),
                    Consumer<UserProfileProvider>(
                      builder: (context, userProfileProvider, child) {
                        final userRole = userProfileProvider.userProfile?.role;
                        if (userRole != null && userRole != 'Student') {
                          return IconButton(
                            icon: const Icon(Icons.add_circle_outline_rounded),
                            onPressed: () {
                              Navigator.pushNamed(context, AdminControl.id);
                            },
                          );
                        } else {
                          return const SizedBox.shrink(); // Return an empty widget if not allowed
                        }
                      },
                    ),
                    // IconButton(
                    //   icon: Icon(Icons.search),
                    //   onPressed: () {
                    //     // Handle search icon press
                    //     // Navigator.pushNamed(context, DoctorProfile.id);
                    //   },
                    // ),
                    IconButton(
                      icon: Icon(Icons.person_outline_rounded),
                      onPressed: () {
                        // Handle profile icon press
                        Navigator.pushNamed(context, Profile.id);
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
                      return PageView.builder(
                        itemCount: provider.announcements.length,
                        scrollDirection: Axis.vertical,
                        itemBuilder: (context, index) {
                          final announcement = provider.announcements[index];
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
