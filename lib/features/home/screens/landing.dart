import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pivot/features/announcements/providers/announcements_provider.dart';
import 'package:pivot/features/user/providers/user_profile_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/features/home/screens/landing_categories.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/home/providers/home_provider.dart';
import 'package:pivot/screens/models/card_model.dart';
import 'package:pivot/screens/models/search_card.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:pivot/services/update_service.dart';
import 'package:pivot/features/settings/providers/settings_provider.dart';

class Landing extends ConsumerStatefulWidget {
  const Landing({super.key});
  // = 'landing';

  @override
  ConsumerState<Landing> createState() => LandingState();
}

class LandingState extends ConsumerState<Landing>
    with TickerProviderStateMixin {
  // State now managed by Riverpod home provider

  final TextEditingController _userSearchController = TextEditingController();
  final PageController _pageController = PageController();
  final PageController _categoryPageController = PageController();
  late TabController _tabController;

  // Flags to prevent circular updates
  bool _isUpdatingFromTab = false;
  bool _isUpdatingFromPage = false;

  @override
  void initState() {
    super.initState();

    // Initialize TabController with empty length first
    _tabController = TabController(
      length: 1, // Will be updated when categories are loaded
      vsync: this,
      initialIndex:
          0, // Will be updated to last index when categories are loaded
    );

    // Listen to tab changes and sync with PageController
    _tabController.addListener(_onTabChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProfileState = ref.read(userProfileProvider);
      final userDepartment = userProfileState.loggedInUserProfile?.department;
      final userLevel = userProfileState.loggedInUserProfile?.level;

      // Initialize home provider with user department and level
      ref
          .read(homeProvider.notifier)
          .initialize(userDepartment, userLevel: userLevel);
    });
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging && !_isUpdatingFromPage) {
      _isUpdatingFromTab = true;
      final newIndex = _tabController.index;
      _categoryPageController.animateToPage(
        newIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

      // Update category via Riverpod provider
      ref.read(homeProvider.notifier).changeCategory(newIndex);

      // Handle category change for the new tab
      final homeState = ref.read(homeProvider);
      if (newIndex < homeState.categories.length) {
        final category = homeState.categories[newIndex];
        _handleCategoryChange(category);
      }

      // Reset flag after a short delay
      Future.delayed(const Duration(milliseconds: 350), () {
        _isUpdatingFromTab = false;
      });
    }
  }

  @override
  void dispose() {
    _userSearchController.dispose();
    _pageController.dispose();
    _categoryPageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _handleCategoryChange(String category) async {
    print('🔍 [Landing] Handling category change: $category');

    // Get user's level for filtering
    final userProfileState = ref.read(userProfileProvider);
    final userLevel = userProfileState.loggedInUserProfile?.level;

    final departmentCode = ref
        .read(homeProvider.notifier)
        .getDepartmentCode(category);
    final timeFilter = ref.read(homeProvider.notifier).getTimeFilter(category);

    print('🔍 [Landing] Department code: $departmentCode');
    print('🔍 [Landing] Time filter: $timeFilter');
    print('🔍 [Landing] User level: $userLevel');

    // Fetch announcements with level filtering
    if (departmentCode != null && timeFilter != null) {
      print(
        '🔍 [Landing] Fetching announcements with department: $departmentCode, timeFilter: $timeFilter, userLevel: $userLevel',
      );
      ref
          .read(announcementsProvider.notifier)
          .fetchAnnouncements(
            timeFilter: timeFilter,
            department: departmentCode,
            userLevel: userLevel,
          );
    } else if (departmentCode != null) {
      print(
        '🔍 [Landing] Fetching announcements with department only: $departmentCode, userLevel: $userLevel',
      );
      ref
          .read(announcementsProvider.notifier)
          .fetchAnnouncements(department: departmentCode, userLevel: userLevel);
    } else {
      print(
        '🔍 [Landing] No valid department code found for category: $category',
      );
    }
  }

  Widget _buildCategoryContent(String category) {
    return Padding(
      padding: EdgeInsets.all(Responsive.space(context, size: Space.small)),
      child: Consumer(
        builder: (context, ref, child) {
          final announcementState = ref.watch(announcementsProvider);
          if (announcementState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (announcementState.announcements.isEmpty) {
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
          final sortedAnnouncements = List.of(announcementState.announcements);
          sortedAnnouncements.sort((a, b) {
            if (a.pinned == b.pinned) {
              return b.timestamp.compareTo(a.timestamp);
            }
            return b.pinned ? 1 : -1;
          });

          // Calculate total items (announcements + loading indicator if loading more)
          final totalItems =
              sortedAnnouncements.length + (announcementState.hasMore ? 1 : 0);

          return NotificationListener<ScrollNotification>(
            onNotification: (scrollInfo) {
              // Trigger load more when scrolling near the end (80% of last item)
              if (!announcementState.isLoadingMore &&
                  announcementState.hasMore &&
                  scrollInfo.metrics.pixels >=
                      scrollInfo.metrics.maxScrollExtent * 0.8) {
                print(
                  '🔍 [Landing] Infinite scroll trigger - loading more announcements',
                );
                ref
                    .read(announcementsProvider.notifier)
                    .loadMoreAnnouncements();
              }
              return false;
            },
            child: PageView.builder(
              controller: _pageController,
              itemCount: totalItems,
              scrollDirection: Axis.vertical,
              physics: const ClampingScrollPhysics(),
              itemBuilder: (context, index) {
                // Show loading indicator at the end if loading more
                if (index >= sortedAnnouncements.length) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(
                        Responsive.space(context, size: Space.large),
                      ),
                      child: CircularProgressIndicator(color: Colors.black87),
                    ),
                  );
                }

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
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final homeState = ref.watch(homeProvider);

        // Show loading if not initialized
        if (!homeState.isInitialized || homeState.isLoading) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator(color: Colors.black)),
          );
        }

        // Update TabController when categories are loaded
        if (homeState.categories.isNotEmpty &&
            _tabController.length != homeState.categories.length) {
          _tabController.dispose();
          _tabController = TabController(
            length: homeState.categories.length,
            vsync: this,
            initialIndex:
                homeState.categories.length -
                1, // Start from rightmost tab (اخبار النهاردة) - index 6
          );

          // Set up listener again
          _tabController.addListener(_onTabChanged);

          // Navigate to the initial category and load its content
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (homeState.categories.isNotEmpty) {
              // Navigate to the last page (rightmost category - اخبار النهاردة)
              _categoryPageController.jumpToPage(
                homeState.categories.length -
                    1, // Jump to index 6 (today's news)
              );
              final initialCategory =
                  homeState.categories[homeState.categories.length -
                      1]; // اخبار النهاردة (rightmost)
              _handleCategoryChange(initialCategory);
            }
          });
        }

        // Normalize the user department for category ordering
        String? normalizedDepartment;
        if (homeState.userDepartment != null &&
            homeState.userDepartment!.startsWith('اخبار قسم ')) {
          normalizedDepartment = homeState.userDepartment!.replaceFirst(
            'اخبار قسم ',
            '',
          );
        } else {
          normalizedDepartment = homeState.userDepartment;
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
                    categories:
                        homeState
                            .categories, // Use categories from Riverpod state
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
                        if (!_isUpdatingFromTab) {
                          _isUpdatingFromPage = true;

                          // PageView index now directly corresponds to TabController index
                          final tabIndex = index;

                          // Update category via Riverpod provider
                          ref
                              .read(homeProvider.notifier)
                              .changeCategory(tabIndex);
                          // Sync with TabController
                          if (_tabController.index != tabIndex) {
                            _tabController.animateTo(tabIndex);
                          }
                          // Trigger category change when swiping
                          if (tabIndex < homeState.categories.length) {
                            final category = homeState.categories[tabIndex];

                            _handleCategoryChange(category);
                          }

                          // Reset flag after a short delay
                          Future.delayed(const Duration(milliseconds: 350), () {
                            _isUpdatingFromPage = false;
                          });
                        }
                      },
                      children:
                          homeState.categories.map((category) {
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
                        horizontal: Responsive.space(
                          context,
                          size: Space.medium,
                        ),
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
                        horizontal: Responsive.space(
                          context,
                          size: Space.medium,
                        ),
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
                  onTap: () => showUserSearchModal(context, ref),
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
                        horizontal: Responsive.space(
                          context,
                          size: Space.medium,
                        ),
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
                      ref
                          .watch(userProfileProvider)
                          .loggedInUserProfile
                          ?.role !=
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
                        horizontal: Responsive.space(
                          context,
                          size: Space.medium,
                        ),
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
                      ref
                          .watch(userProfileProvider)
                          .loggedInUserProfile
                          ?.role ==
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
                        horizontal: Responsive.space(
                          context,
                          size: Space.medium,
                        ),
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
                  visible: ref.watch(settingsProvider).showTeamFormationButton,
                  onTap: () {
                    Navigator.pushNamed(context, '/teams');
                  },
                ),
                // Update button - only shown when Firestore allows it
                if (UpdateService().shouldShowUpdateButtonSync()) ...[
                  SpeedDialChild(
                    child: Icon(
                      Icons.system_update,
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
                          vertical: Responsive.space(
                            context,
                            size: Space.small,
                          ),
                          horizontal: Responsive.space(
                            context,
                            size: Space.medium,
                          ),
                        ),
                        child: Text(
                          'تحديث جديد',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    onTap: () async {
                      // Check if updates are available before showing bottom sheet
                      final hasUpdates =
                          await UpdateService().areUpdatesAvailable();
                      if (hasUpdates) {
                        UpdateService().showUpdateBottomSheet(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('لا توجد تحديثات متاحة حالياً'),
                            backgroundColor: Colors.blue,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
