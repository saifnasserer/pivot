import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pivot/providers/announcement_provider.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/features/home/screens/landing_categories.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:pivot/features/home/providers/home_provider.dart';
import 'package:pivot/screens/models/card_model.dart';
import 'package:pivot/screens/models/search_card.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:pivot/services/update_service.dart';
import 'package:pivot/providers/settings_provider.dart';

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
      final userProfileProvider = legacy_provider
          .Provider.of<UserProfileProvider>(context, listen: false);
      final userDepartment =
          userProfileProvider.loggedInUserProfile?.department;

      // Initialize home provider with user department
      ref.read(homeProvider.notifier).initialize(userDepartment);
    });
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging && !_isUpdatingFromPage) {
      _isUpdatingFromTab = true;
      final newIndex = _tabController.index;
      print('🔍 [Landing] TabController changed to index: $newIndex');

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
        print(
          '🔍 [Landing] Tab change - Category: $category (index: $newIndex)',
        );
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
    final announcementProvider = legacy_provider
        .Provider.of<AnnouncementProvider>(context, listen: false);

    final departmentCode = ref
        .read(homeProvider.notifier)
        .getDepartmentCode(category);
    final timeFilter = ref.read(homeProvider.notifier).getTimeFilter(category);

    print(
      '🔍 [Landing] Fetching with department: $departmentCode, timeFilter: $timeFilter',
    );

    // Only fetch if we have valid values
    if (departmentCode != null && timeFilter != null) {
      announcementProvider.fetchAnnouncements(
        timeFilter: timeFilter,
        department: departmentCode,
      );
    }
  }

  Widget _buildCategoryContent(String category) {
    return Padding(
      padding: EdgeInsets.all(Responsive.space(context, size: Space.small)),
      child: legacy_provider.Consumer<AnnouncementProvider>(
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
              print('🔍 [Landing] Categories order: ${homeState.categories}');
              print(
                '🔍 [Landing] Starting from index: ${homeState.categories.length - 1}',
              );
              print(
                '🔍 [Landing] Initial category: ${homeState.categories[homeState.categories.length - 1]}',
              );

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
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: PageView(
                        controller: _categoryPageController,
                        scrollDirection: Axis.horizontal,
                        reverse:
                            true, // RTL swipe behavior (high index to low index: 6->5->4->3->2->1->0)
                        onPageChanged: (index) {
                          if (!_isUpdatingFromTab) {
                            _isUpdatingFromPage = true;
                            print(
                              '🔍 [Landing] PageView changed to index: $index',
                            );
                            // PageView index now directly corresponds to TabController index
                            final tabIndex = index;
                            print(
                              '🔍 [Landing] TabController index: $tabIndex',
                            );
                            // Update category via Riverpod provider
                            ref
                                .read(homeProvider.notifier)
                                .changeCategory(tabIndex);
                            // Sync with TabController
                            if (_tabController.index != tabIndex) {
                              print(
                                '🔍 [Landing] Syncing TabController to index: $tabIndex',
                              );
                              _tabController.animateTo(tabIndex);
                            }
                            // Trigger category change when swiping
                            if (tabIndex < homeState.categories.length) {
                              final category = homeState.categories[tabIndex];
                              print(
                                '🔍 [Landing] Category changed to: $category (tabIndex: $tabIndex)',
                              );
                              _handleCategoryChange(category);
                            }

                            // Reset flag after a short delay
                            Future.delayed(
                              const Duration(milliseconds: 350),
                              () {
                                _isUpdatingFromPage = false;
                              },
                            );
                          }
                        },
                        children:
                            homeState.categories.map((category) {
                              return _buildCategoryContent(category);
                            }).toList(),
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
                      legacy_provider.Provider.of<UserProfileProvider>(
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
                      legacy_provider.Provider.of<UserProfileProvider>(
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
                  visible:
                      legacy_provider.Provider.of<SettingsProvider>(
                        context,
                        listen: false,
                      ).showTeamFormationButton,
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
