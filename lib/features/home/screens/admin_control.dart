import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/features/home/screens/adminstration/announcement_card.dart';
import 'package:pivot/features/home/screens/adminstration/announcement/index.dart';
import 'package:pivot/features/home/screens/adminstration/animated_route.dart';
import 'package:pivot/features/announcements/providers/announcements_provider.dart';
import 'package:pivot/features/user/providers/user_profile_provider.dart';
import 'package:pivot/features/home/screens/adminstration/models/announcement_data.dart';
import 'package:lottie/lottie.dart';

class AdminControl extends ConsumerStatefulWidget {
  const AdminControl({super.key});
  // = 'admin_id';

  @override
  ConsumerState<AdminControl> createState() => _AdminControlState();
}

class _AdminControlState extends ConsumerState<AdminControl> {
  String _search = '';
  String _departmentFilter = '';
  String _dateFilter = '';
  String _pinnedFilter = '';
  bool _showSearch = false;
  // bool _showFilters = false; // Removed - filters are always visible now
  final TextEditingController _searchController = TextEditingController();
  int _rebuildCounter = 0; // Force rebuild counter

  final List<String> _departments = [
    '', // All
    'SC',
    'AI',
    'CS',
    'IS',
    'General',
  ];

  @override
  void initState() {
    super.initState();
    // Fetch announcements when the widget is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Force fresh fetch of all announcements
      print(
        '📥 AdminControl: Fetching all announcements (including scheduled & expired)',
      );
      ref
          .read(announcementsProvider.notifier)
          .fetchAnnouncements(includeScheduledAndExpired: true)
          .then((_) {
            // Get user's department and set as initial filter AFTER data loads
            final userProfile =
                ref.read(userProfileProvider).loggedInUserProfile;
            if (userProfile != null &&
                userProfile.department.isNotEmpty &&
                mounted) {
              setState(() {
                _departmentFilter = userProfile.department;
              });
              print(
                '🏢 AdminControl: Auto-filtered to department: ${userProfile.department}',
              );
            }
          });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AnnouncementData> _filterAnnouncements(List<AnnouncementData> list) {
    return list.where((a) {
      // Search
      final searchLower = _search.toLowerCase();
      final matchesSearch =
          _search.isEmpty ||
          a.title.toLowerCase().contains(searchLower) ||
          a.description.toLowerCase().contains(searchLower) ||
          a.tags.any((tag) => tag.toLowerCase().contains(searchLower));

      // Department
      final matchesDepartment =
          _departmentFilter.isEmpty ||
          a.tags.any((tag) {
            // Handle both old and new format
            String cleanTag = tag;
            if (tag.startsWith('اخبار قسم ')) {
              cleanTag = tag.replaceFirst('اخبار قسم ', '');
            }
            return cleanTag == _departmentFilter;
          });

      // Date
      final now = DateTime.now();
      bool matchesDate = true;
      if (_dateFilter == 'today') {
        matchesDate =
            a.timestamp.year == now.year &&
            a.timestamp.month == now.month &&
            a.timestamp.day == now.day;
      } else if (_dateFilter == 'general') {
        matchesDate = a.tags.any((tag) {
          // Handle both old and new format
          String cleanTag = tag;
          if (tag.startsWith('اخبار قسم ')) {
            cleanTag = tag.replaceFirst('اخبار قسم ', '');
          }
          return cleanTag == 'اخبار عامة';
        });
      }

      // Pinned
      bool matchesPinned = true;
      if (_pinnedFilter == 'pinned') {
        matchesPinned = a.pinned;
      } else if (_pinnedFilter == 'not_pinned') {
        matchesPinned = !a.pinned;
      }

      return matchesSearch && matchesDepartment && matchesDate && matchesPinned;
    }).toList();
  }

  Widget _buildAppBarSearchField() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: _showSearch ? 56 : 0,
      curve: Curves.easeInOut,
      child:
          _showSearch
              ? Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.space(context, size: Space.small),
                  vertical: Responsive.space(context, size: Space.tiny),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: 'بحث (العنوان، الوصف، أو الوسوم)',
                    hintStyle: TextStyle(
                      fontSize: Responsive.text(context, size: TextSize.small),
                      color: Colors.grey[500],
                    ),
                    suffixIcon: Icon(
                      Icons.search,
                      size: Responsive.text(context, size: TextSize.medium),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        Responsive.space(context, size: Space.large),
                      ),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        Responsive.space(context, size: Space.large),
                      ),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        Responsive.space(context, size: Space.large),
                      ),
                      borderSide: BorderSide(color: Colors.black, width: 2),
                    ),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: Responsive.space(context, size: Space.medium),
                      vertical: Responsive.space(context, size: Space.small),
                    ),
                    prefixIcon: IconButton(
                      icon: Icon(
                        Icons.close,
                        size: Responsive.text(context, size: TextSize.medium),
                      ),
                      onPressed: () {
                        setState(() {
                          _showSearch = false;
                          _search = '';
                          _searchController.clear();
                        });
                      },
                    ),
                  ),
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.medium),
                  ),
                  onChanged: (v) => setState(() => _search = v.trim()),
                ),
              )
              : null,
    );
  }

  Widget _buildClearButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextButton.icon(
        onPressed: () {
          setState(() {
            _departmentFilter = '';
            _dateFilter = '';
            _pinnedFilter = '';
            _rebuildCounter++;
          });
          print('🧹 AdminControl: Filters cleared - forcing rebuild');
        },
        icon: Icon(Icons.clear_all, color: Colors.grey.shade600, size: 16),
        label: Text(
          'مسح',
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: Responsive.text(context, size: TextSize.small),
            fontWeight: FontWeight.w500,
          ),
        ),
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.space(context, size: Space.small),
            vertical: Responsive.space(context, size: Space.tiny),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, size: Space.tiny),
      ),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: Responsive.text(context, size: TextSize.small),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: Colors.black,
        backgroundColor: Colors.white,
        side: BorderSide(
          color: isSelected ? Colors.black : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontSize: Responsive.text(context, size: TextSize.small),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.space(context, size: Space.medium),
          vertical: Responsive.space(context, size: Space.small),
        ),
        elevation: isSelected ? 2 : 0,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      ),
    );
  }

  Widget _buildFilterBar() {
    // Filters are always visible now
    // Separate active and inactive filters
    final activeDepartments = <String>[];
    final inactiveDepartments = <String>[];

    for (var dep in _departments.where((dep) => dep.isNotEmpty)) {
      if (_departmentFilter == dep) {
        activeDepartments.add(dep);
      } else {
        inactiveDepartments.add(dep);
      }
    }

    // Separate date filters
    final dateOptions = [
      {'label': 'اليوم', 'value': 'today'},
      {'label': 'اخبار عامة', 'value': 'general'},
    ];
    final activeDateOptions =
        dateOptions.where((d) => _dateFilter == d['value']).toList();
    final inactiveDateOptions =
        dateOptions.where((d) => _dateFilter != d['value']).toList();

    // Separate pinned filters
    final pinnedOptions = [
      {'label': 'مثبت', 'value': 'pinned'},
      {'label': 'غير مثبت', 'value': 'not_pinned'},
    ];
    final activePinnedOptions =
        pinnedOptions.where((p) => _pinnedFilter == p['value']).toList();
    final inactivePinnedOptions =
        pinnedOptions.where((p) => _pinnedFilter != p['value']).toList();

    return Container(
      margin: EdgeInsets.only(
        top: Responsive.space(context, size: Space.small),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, size: Space.medium),
        vertical: Responsive.space(context, size: Space.medium),
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Row(
              children: [
                // Inactive pinned chips
                ...inactivePinnedOptions.map(
                  (p) => _buildFilterChip(
                    label: p['label']!,
                    isSelected: false,
                    onTap: () {
                      setState(() {
                        _pinnedFilter = p['value']!;
                        _rebuildCounter++;
                      });
                      print(
                        '📌 AdminControl: Pinned filter changed to: ${p['value']}',
                      );
                    },
                  ),
                ),

                // Active pinned chips
                ...activePinnedOptions.map(
                  (p) => _buildFilterChip(
                    label: p['label']!,
                    isSelected: true,
                    onTap: () {
                      setState(() {
                        _pinnedFilter = '';
                        _rebuildCounter++;
                      });
                      print('📌 AdminControl: Pinned filter cleared');
                    },
                  ),
                ),

                if (pinnedOptions.isNotEmpty)
                  SizedBox(width: Responsive.space(context, size: Space.small)),

                // Inactive date chips
                ...inactiveDateOptions.map(
                  (d) => _buildFilterChip(
                    label: d['label']!,
                    isSelected: false,
                    onTap: () {
                      setState(() {
                        _dateFilter = d['value']!;
                        _rebuildCounter++;
                      });
                      print(
                        '📅 AdminControl: Date filter changed to: ${d['value']}',
                      );
                    },
                  ),
                ),

                // Active date chips
                ...activeDateOptions.map(
                  (d) => _buildFilterChip(
                    label: d['label']!,
                    isSelected: true,
                    onTap: () {
                      setState(() {
                        _dateFilter = '';
                        _rebuildCounter++;
                      });
                      print('📅 AdminControl: Date filter cleared');
                    },
                  ),
                ),

                if (dateOptions.isNotEmpty)
                  SizedBox(width: Responsive.space(context, size: Space.small)),

                // Inactive department chips
                ...inactiveDepartments.map(
                  (dep) => _buildFilterChip(
                    label: dep,
                    isSelected: false,
                    onTap: () {
                      setState(() {
                        _departmentFilter = dep;
                        _rebuildCounter++;
                      });
                      print(
                        '🏢 AdminControl: Department filter changed to: $dep',
                      );
                    },
                  ),
                ),

                // Active department chips (show at end/front in RTL)
                ...activeDepartments.map(
                  (dep) => _buildFilterChip(
                    label: dep,
                    isSelected: true,
                    onTap: () {
                      setState(() {
                        _departmentFilter = '';
                        _rebuildCounter++;
                      });
                      print('🏢 AdminControl: Department filter cleared');
                    },
                  ),
                ),

                if (_departmentFilter.isNotEmpty ||
                    _dateFilter.isNotEmpty ||
                    _pinnedFilter.isNotEmpty)
                  SizedBox(
                    width: Responsive.space(context, size: Space.medium),
                  ),

                // Clear button at the very end (shows at start in RTL)
                if (_departmentFilter.isNotEmpty ||
                    _dateFilter.isNotEmpty ||
                    _pinnedFilter.isNotEmpty)
                  _buildClearButton(),
              ],
            ),
          ),
          SizedBox(height: Responsive.space(context, size: Space.small)),
        ],
      ),
    );
  }

  Widget _buildAnalyticsBar(List<AnnouncementData> announcements) {
    final total = announcements.length;
    final pinned = announcements.where((a) => a.pinned).length;
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final thisWeek =
        announcements.where((a) => a.timestamp.isAfter(weekAgo)).length;
    final Map<String, int> deptCounts = {
      'SC': 0,
      'AI': 0,
      'CS': 0,
      'IS': 0,
      'General': 0,
    };
    for (final a in announcements) {
      for (final d in deptCounts.keys) {
        if (a.tags.any((tag) {
          // Handle both old and new format
          String cleanTag = tag;
          if (tag.startsWith('اخبار قسم ')) {
            cleanTag = tag.replaceFirst('اخبار قسم ', '');
          }
          return cleanTag == d;
        })) {
          deptCounts[d] = deptCounts[d]! + 1;
        }
      }
    }
    final stats = [
      {
        'label': 'الإجمالي',
        'value': total,
        'icon': Icons.campaign,
        'color': Colors.blue,
      },
      {
        'label': 'مثبت',
        'value': pinned,
        'icon': Icons.push_pin,
        'color': Colors.orange,
      },
      {
        'label': 'هذا الأسبوع',
        'value': thisWeek,
        'icon': Icons.calendar_today,
        'color': Colors.green,
      },
      ...deptCounts.entries.map(
        (e) => {
          'label': e.key,
          'value': e.value,
          'icon': Icons.label,
          'color': Colors.purple,
        },
      ),
    ];

    // Calculate responsive dimensions
    final screenWidth = Responsive.width(context);
    final isTablet = screenWidth >= 600;
    final isDesktop = screenWidth >= 900;

    // Adjust card width based on screen size
    final cardWidth = isDesktop ? 140.0 : (isTablet ? 120.0 : 100.0);
    final cardHeight = isDesktop ? 100.0 : (isTablet ? 90.0 : 80.0);
    final iconSize = isDesktop ? 32.0 : (isTablet ? 28.0 : 24.0);
    final valueFontSize = isDesktop ? 20.0 : (isTablet ? 18.0 : 16.0);
    final labelFontSize = isDesktop ? 14.0 : (isTablet ? 13.0 : 12.0);

    return Container(
      height: cardHeight + Responsive.space(context, size: Space.medium),
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, size: Space.small),
        vertical: Responsive.space(context, size: Space.small),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        reverse: true, // RTL support
        itemCount: stats.length,
        separatorBuilder:
            (_, __) =>
                SizedBox(width: Responsive.space(context, size: Space.small)),
        itemBuilder: (context, i) {
          final s = stats[i];
          return Container(
            width: cardWidth,
            height: cardHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                Responsive.space(context, size: Space.large),
              ),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Padding(
              padding: Responsive.padding(context, size: Space.small),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    s['icon'] as IconData,
                    color: s['color'] as Color,
                    size: iconSize,
                  ),
                  SizedBox(height: Responsive.space(context, size: Space.tiny)),
                  Text(
                    '${s['value']}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: valueFontSize,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    s['label'] as String,
                    style: TextStyle(
                      fontSize: labelFontSize,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final announcementsState = ref.watch(announcementsProvider);

    // Force recomputation of filtered announcements on every build
    // This ensures filters are applied immediately
    final filteredAnnouncements = _filterAnnouncements(
      announcementsState.announcements,
    );

    // Debug log to track filter changes and rebuilds
    print(
      '🔄 AdminControl BUILD #$_rebuildCounter: Filters - Dept: "$_departmentFilter", Date: "$_dateFilter", Pinned: "$_pinnedFilter"',
    );
    print(
      '📊 AdminControl: ${announcementsState.announcements.length} total → ${filteredAnnouncements.length} filtered',
    );

    // Additional debug info
    if (filteredAnnouncements.length !=
        announcementsState.announcements.length) {
      print('   ℹ️ Filters are active and reducing results');
    } else {
      print('   ℹ️ No active filters or all items match filters');
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'إدارة الأخبار',
          style: TextStyle(
            fontSize: Responsive.text(context, size: TextSize.heading),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Directionality(
            textDirection: TextDirection.rtl,
            child: Container(
              margin: EdgeInsets.only(
                right: Responsive.space(context, size: Space.small),
              ),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(
                  Responsive.space(context, size: Space.large),
                ),
              ),
              child: PopupMenuButton<String>(
                icon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.tune,
                      color: Colors.black87,
                      size: Responsive.space(context, size: Space.medium),
                    ),
                  ],
                ),
                tooltip: 'خيارات',
                offset: Offset(
                  0,
                  Responsive.space(context, size: Space.large) * 2,
                ),
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    Responsive.space(context, size: Space.large),
                  ),
                ),
                color: Colors.white,
                itemBuilder: (context) {
                  final List<PopupMenuEntry<String>> items = [
                    PopupMenuItem(
                      value: 'search',
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: Responsive.space(
                            context,
                            size: Space.small,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _showSearch ? 'إغلاق البحث' : 'البحث',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    _showSearch
                                        ? 'إخفاء شريط البحث'
                                        : 'البحث في الإعلانات',
                                    style: TextStyle(
                                      fontSize: Responsive.text(
                                        context,
                                        size: TextSize.small,
                                      ),
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: Responsive.space(
                                context,
                                size: Space.small,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.all(
                                Responsive.space(context, size: Space.small),
                              ),
                              decoration: BoxDecoration(
                                color:
                                    _showSearch
                                        ? Colors.blue[100]
                                        : Colors.grey[100],
                                borderRadius: BorderRadius.circular(
                                  Responsive.space(context, size: Space.large),
                                ),
                              ),
                              child: Icon(
                                _showSearch ? Icons.close : Icons.search,
                                size: Responsive.space(
                                  context,
                                  size: Space.medium,
                                ),
                                color:
                                    _showSearch
                                        ? Colors.blue[700]
                                        : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ];
                  return items;
                },
                onSelected: (value) {
                  if (value == 'search') {
                    setState(() {
                      if (_showSearch) {
                        _showSearch = false;
                        _search = '';
                        _searchController.clear();
                      } else {
                        _showSearch = true;
                      }
                    });
                  }
                },
              ),
            ),
          ),
        ],
        surfaceTintColor: Colors.white,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(
            (_showSearch ? 56 : 0) +
                // Filters are always shown now - fixed height
                80,
          ),
          child: Column(
            children: [_buildAppBarSearchField(), _buildFilterBar()],
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            announcementsState.isLoading
                ? Center(
                  child: Lottie.asset(
                    'assets/animation/update.json',
                    width: Responsive.space(context, size: Space.large) * 2.5,
                    height: Responsive.space(context, size: Space.large) * 2.5,
                    repeat: true,
                  ),
                )
                : Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.space(context, size: Space.medium),
                    vertical: Responsive.space(context, size: Space.medium),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (filteredAnnouncements.isEmpty)
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Lottie.asset(
                              'assets/animation/empty.json',
                              width:
                                  Responsive.space(
                                    context,
                                    size: Space.xlarge,
                                  ) *
                                  10,
                              height:
                                  Responsive.space(
                                    context,
                                    size: Space.xlarge,
                                  ) *
                                  10,
                              repeat: true,
                            ),
                            Text(
                              'لا يوجد إعلانات لعرضها حالياً',
                              style: TextStyle(
                                fontSize: Responsive.text(
                                  context,
                                  size: TextSize.heading,
                                ),
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(
                              height: Responsive.space(
                                context,
                                size: Space.small,
                              ),
                            ),
                            Text(
                              'ابدأ بإضافة إعلان جديد أو جرب تغيير الفلاتر',
                              style: TextStyle(
                                fontSize: Responsive.text(
                                  context,
                                  size: TextSize.medium,
                                ),
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        )
                      else
                        Expanded(
                          child: ListView.builder(
                            // Add key with rebuild counter to force rebuild when filters change
                            key: ValueKey(
                              'announcements_$_rebuildCounter-$_departmentFilter-$_dateFilter-$_pinnedFilter-${filteredAnnouncements.length}',
                            ),
                            itemCount: filteredAnnouncements.length,
                            itemBuilder: (context, index) {
                              final announcement = filteredAnnouncements[index];
                              return AnnouncementCard(
                                announcement: announcement,
                                onEdit: () => _editAnnouncement(announcement),
                                onDelete:
                                    () => _deleteAnnouncement(announcement),
                                onPin: () => _pinAnnouncement(announcement),
                                onUnpin: () => _unpinAnnouncement(announcement),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
            Positioned(
              left: 0,
              right: 0,
              bottom: Responsive.space(context),
              child: AnimatedAddButton(
                onPressed: () {
                  Navigator.of(context).push(
                    AnimatedAddRoute(
                      startPosition: Offset.zero,
                      child: AddAnnouncementMain(),
                    ),
                  );
                },
                icon: Icons.add_rounded,
                iconSizeMultiplier: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editAnnouncement(AnnouncementData announcement) {
    Navigator.of(context).push(
      AnimatedAddRoute(
        startPosition: Offset.zero,
        child: AddAnnouncementMain(isEditing: true, announcement: announcement),
      ),
    );
  }

  void _deleteAnnouncement(AnnouncementData announcement) {
    if (announcement.id != null) {
      ref
          .read(announcementsProvider.notifier)
          .deleteAnnouncement(announcement.id!);
    }
  }

  void _pinAnnouncement(AnnouncementData announcement) {
    ref.read(announcementsProvider.notifier).pinAnnouncement(announcement);
  }

  void _unpinAnnouncement(AnnouncementData announcement) {
    ref.read(announcementsProvider.notifier).unpinAnnouncement(announcement);
  }
}
