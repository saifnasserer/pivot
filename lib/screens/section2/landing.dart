import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pivot/providers/announcement_provider.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/section2/landing_categories.dart';
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

  @override
  void initState() {
    super.initState();

    // Initialize TabController with empty length first
    _tabController = TabController(
      length: 1, // Will be updated when categories are loaded
      vsync: this,
      initialIndex: 0,
    );

    // Listen to tab changes and sync with PageController
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        final newIndex = _tabController.index;
        print('🔍 [Landing] TabController changed to index: $newIndex');
        _categoryPageController.animateToPage(
          newIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        // Update category via Riverpod provider
        ref.read(homeProvider.notifier).changeCategory(newIndex);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProfileProvider = legacy_provider
          .Provider.of<UserProfileProvider>(context, listen: false);
      final userDepartment =
          userProfileProvider.loggedInUserProfile?.department;

      // Initialize home provider with user department
      ref.read(homeProvider.notifier).initialize(userDepartment);
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
            initialIndex: homeState.currentCategoryIndex,
          );

          // Set up listener again
          _tabController.addListener(() {
            if (_tabController.indexIsChanging) {
              final newIndex = _tabController.index;
              _categoryPageController.animateToPage(
                newIndex,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
              ref.read(homeProvider.notifier).changeCategory(newIndex);
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
                        print('🔍 [Landing] PageView changed to index: $index');
                        // Update category via Riverpod provider
                        ref.read(homeProvider.notifier).changeCategory(index);
                        // Sync with TabController
                        if (_tabController.index != index) {
                          print(
                            '🔍 [Landing] Syncing TabController to index: $index',
                          );
                          _tabController.animateTo(index);
                        }
                        // Trigger category change when swiping
                        if (index < homeState.categories.length) {
                          final category = homeState.categories[index];
                          print(
                            '🔍 [Landing] Category changed to: $category (index: $index)',
                          );
                          _handleCategoryChange(category);
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
