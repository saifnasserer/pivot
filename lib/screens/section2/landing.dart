import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pivot/providers/announcement_provider.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/section2/landing_categories.dart';
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

class LandingState extends State<Landing> with TickerProviderStateMixin {
  String? _userDepartment;
  int _currentCategoryIndex = 0;

  final TextEditingController _userSearchController = TextEditingController();
  final PageController _pageController = PageController();
  final PageController _categoryPageController = PageController();
  late TabController _tabController; // Add TabController
  @override
  void initState() {
    super.initState();

    // Initialize TabController
    final categories = _getCategories(_userDepartment);
    _tabController = TabController(
      length: categories.length,
      vsync: this,
      initialIndex: 0,
    );

    // Listen to tab changes and sync with PageController
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        final newIndex = _tabController.index;
        if (newIndex != _currentCategoryIndex) {
          _categoryPageController.animateToPage(
            newIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          setState(() {
            _currentCategoryIndex = newIndex;
          });
        }
      }
    });

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
    _pageController.dispose();
    _categoryPageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  List<String> _getCategories(String? userDepartment) {
    final baseCategories = [
      'اخبار النهاردة',
      'عام',
      'SC',
      'AI',
      'CS',
      'IS',
      'General',
    ];

    // If no user department, return default order
    if (userDepartment == null) {
      return baseCategories; // Don't reverse - keep natural order for RTL
    }

    // Create ordered list: Today's News - General - User's Department - Other Departments
    final orderedCategories = <String>[];

    // 1. Today's News (always first)
    orderedCategories.add('اخبار النهاردة');

    // 2. General (always second)
    orderedCategories.add('عام');

    // 3. User's Department (if it exists in the list)
    if (baseCategories.contains(userDepartment)) {
      orderedCategories.add(userDepartment);
    }

    // 4. Other departments (excluding the ones already added)
    for (final category in baseCategories) {
      if (!orderedCategories.contains(category)) {
        orderedCategories.add(category);
      }
    }

    return orderedCategories; // Don't reverse - keep natural order for RTL
  }

  void _handleCategoryChange(String category) {
    final announcementProvider = Provider.of<AnnouncementProvider>(
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
      // Handle today's news with mixed department content
      String? normalizedDepartment;
      if (_userDepartment != null &&
          _userDepartment!.startsWith('اخبار قسم ')) {
        normalizedDepartment = _userDepartment!.replaceFirst('اخبار قسم ', '');
      } else {
        normalizedDepartment = _userDepartment;
      }

      if (normalizedDepartment != null) {
        departmentCode = 'today_mixed:اخبار قسم $normalizedDepartment';
      } else {
        departmentCode = 'عام';
      }
      timeFilter = 'today';
    } else if (category == 'عام') {
      departmentCode = 'عام';
    }

    // Fetch announcements with the determined parameters
    announcementProvider.fetchAnnouncements(
      timeFilter: timeFilter,
      department: departmentCode,
    );
  }

  Widget _buildCategoryContent(String category) {
    return Padding(
      padding: EdgeInsets.all(Responsive.space(context, size: Space.small)),
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
                  fontSize: Responsive.text(context, size: TextSize.medium),
                ),
                textAlign: TextAlign.center,
              ),
            );
          }
          final sortedAnnouncements = List.of(provider.announcements);
          sortedAnnouncements.sort((a, b) {
            if (a.pinned == b.pinned) {
              return b.timestamp.compareTo(a.timestamp);
            }
            return b.pinned ? 1 : -1;
          });
          return PageView.builder(
            controller: _pageController,
            itemCount: sortedAnnouncements.length,
            scrollDirection: Axis.vertical,
            physics: const ClampingScrollPhysics(),
            itemBuilder: (context, index) {
              final announcement = sortedAnnouncements[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
    );
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
              LandingCategories(
                userDepartment: normalizedDepartment,
                tabController: _tabController,
                onCategoryChanged: (category) {
                  // Category change is now handled by TabController listener
                  // This callback can be used for additional UI updates if needed
                },
              ),
              // Main content with horizontal swipe navigation
              Expanded(
                child: PageView(
                  controller: _categoryPageController,
                  scrollDirection: Axis.horizontal,
                  onPageChanged: (index) {
                    setState(() {
                      _currentCategoryIndex = index;
                    });
                    // Sync with TabController
                    if (_tabController.index != index) {
                      _tabController.animateTo(index);
                    }
                    // Trigger category change when swiping
                    final categories = _getCategories(normalizedDepartment);
                    if (index < categories.length) {
                      _handleCategoryChange(categories[index]);
                    }
                  },
                  children:
                      _getCategories(normalizedDepartment).map((category) {
                        return _buildCategoryContent(category);
                      }).toList(),
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
