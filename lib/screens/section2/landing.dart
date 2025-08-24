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
import 'package:pivot/services/category_service.dart';
import 'package:pivot/services/update_service.dart';

class Landing extends StatefulWidget {
  const Landing({super.key});
  // = 'landing';

  @override
  State<Landing> createState() => LandingState();
}

class LandingState extends State<Landing> with TickerProviderStateMixin {
  String? _userDepartment;
  int _currentCategoryIndex = 0;
  List<String> _categories = []; // Add categories list to ensure consistency
  bool _isInitialized =
      false; // Add flag to prevent listener during initialization

  final TextEditingController _userSearchController = TextEditingController();
  final PageController _pageController = PageController();
  final PageController _categoryPageController = PageController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();

    // Initialize categories first
    _categories = CategoryService.getCategories(_userDepartment);

    // Initialize TabController with categories
    _tabController = TabController(
      length: _categories.length,
      vsync: this,
      initialIndex: _categories.length - 1, // Start from rightmost tab
    );

    // Listen to tab changes and sync with PageController
    _tabController.addListener(() {
      if (_tabController.indexIsChanging && _isInitialized) {
        final newIndex = _tabController.index;
        print('🔍 [Landing] TabController changed to index: $newIndex');
        if (newIndex != _currentCategoryIndex) {
          print('🔍 [Landing] Syncing PageView to index: $newIndex');
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

      // Update categories with actual user department
      _categories = CategoryService.getCategories(_userDepartment);

      // Use CategoryService for initial fetch
      final normalizedDepartment = CategoryService.normalizeDepartment(
        _userDepartment,
      );

      print(
        '🔍 [Landing] Initial setup - normalizedDepartment: $normalizedDepartment',
      );
      print('🔍 [Landing] Initial categories: $_categories');

      if (_categories.isNotEmpty) {
        final lastCategory =
            _categories[_categories.length -
                1]; // Use last category (rightmost)
        print(
          '🔍 [Landing] Initial category: $lastCategory (index: ${_categories.length - 1})',
        );

        // Set initial state properly
        setState(() {
          _currentCategoryIndex = _categories.length - 1;
        });

        // Ensure PageView is at the correct initial position
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_categoryPageController.hasClients) {
            _categoryPageController.jumpToPage(_categories.length - 1);
            print(
              '🔍 [Landing] Set PageView to initial index: ${_categories.length - 1}',
            );
          }

          // Ensure TabController is at the correct initial position
          if (_tabController.index != _categories.length - 1) {
            _tabController.index = _categories.length - 1;
            print(
              '🔍 [Landing] Set TabController to initial index: ${_categories.length - 1}',
            );
          }

          // Mark as initialized after setup is complete
          _isInitialized = true;
          print('🔍 [Landing] Initialization complete, listener enabled');
        });

        // Check for app updates after initialization
        WidgetsBinding.instance.addPostFrameCallback((_) {
          UpdateService().checkForUpdates(context);
        });

        final departmentCode = CategoryService.getDepartmentCode(
          lastCategory,
          _userDepartment,
        );
        final timeFilter = CategoryService.getTimeFilter(lastCategory);

        final announcementProvider = Provider.of<AnnouncementProvider>(
          context,
          listen: false,
        );

        announcementProvider.fetchAnnouncements(
          timeFilter: timeFilter,
          department: departmentCode,
        );
      }
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

  void _handleCategoryChange(String category) {
    print('🔍 [Landing] Handling category change: $category');
    final announcementProvider = Provider.of<AnnouncementProvider>(
      context,
      listen: false,
    );

    final departmentCode = CategoryService.getDepartmentCode(
      category,
      _userDepartment,
    );
    final timeFilter = CategoryService.getTimeFilter(category);

    print(
      '🔍 [Landing] Fetching with department: $departmentCode, timeFilter: $timeFilter',
    );

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
                  availableHeight:
                      Responsive.height(context) *
                      0.95, // Pass available height
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
                categories: _categories, // Pass categories for consistency
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
                    print('🔍 [Landing] PageView changed to index: $index');
                    setState(() {
                      _currentCategoryIndex = index;
                    });
                    // Sync with TabController
                    if (_tabController.index != index) {
                      print(
                        '🔍 [Landing] Syncing TabController to index: $index',
                      );
                      _tabController.animateTo(index);
                    }
                    // Trigger category change when swiping
                    if (index < _categories.length) {
                      final category = _categories[index];
                      print(
                        '🔍 [Landing] Category changed to: $category (index: $index)',
                      );
                      _handleCategoryChange(category);
                    }
                  },
                  children:
                      _categories.map((category) {
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
                Navigator.pushNamed(context, '/profile');
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
                Icons.admin_panel_settings,
                color: Colors.white,
                size: 20,
              ),
              backgroundColor: Colors.red,
              shape: const CircleBorder(),
              labelWidget: Container(
                decoration: BoxDecoration(
                  color: Colors.red,
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
                    'لوحة السوبر أدمن',
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
                  ).loggedInUserProfile?.role ==
                  'Super Admin',
              onTap: () {
                Navigator.pushNamed(context, '/super-admin-panel');
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
