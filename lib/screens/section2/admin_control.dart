import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/models/circular_button.dart';
import 'package:pivot/screens/section2/adminstration/announcement_card.dart';
import 'package:pivot/screens/section2/adminstration/show_dialog.dart';
import 'package:provider/provider.dart';
import 'package:pivot/providers/announcement_provider.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/screens/section2/adminstration/models/announcement_data.dart';
import 'package:lottie/lottie.dart';

class AdminControl extends StatefulWidget {
  const AdminControl({super.key});
  static const String id = 'admin_id';

  @override
  State<AdminControl> createState() => _AdminControlState();
}

class _AdminControlState extends State<AdminControl> {
  String _search = '';
  String _departmentFilter = '';
  String _dateFilter = '';
  String _pinnedFilter = '';
  bool _showAnalytics = false;
  bool _showSearch = false;
  bool _showFilters = false;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _departments = [
    '', // All
    'SC',
    'AI',
    'CS',
    'IS',
  ];

  @override
  void initState() {
    super.initState();
    // Fetch announcements when the widget is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AnnouncementProvider>(
        context,
        listen: false,
      ).fetchAnnouncements();
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
          a.tags.contains('اخبار قسم $_departmentFilter');
      // Date
      final now = DateTime.now();
      bool matchesDate = true;
      if (_dateFilter == 'today') {
        matchesDate =
            a.timestamp.year == now.year &&
            a.timestamp.month == now.month &&
            a.timestamp.day == now.day;
      } else if (_dateFilter == 'week') {
        final weekAgo = now.subtract(const Duration(days: 7));
        matchesDate = a.timestamp.isAfter(weekAgo);
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
                    prefixIcon: Icon(
                      Icons.search,
                      size: Responsive.text(context, size: TextSize.medium),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.black, width: 2),
                    ),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: Responsive.space(context, size: Space.medium),
                      vertical: Responsive.space(context, size: Space.small),
                    ),
                    suffixIcon: IconButton(
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

  Widget _buildFilterBar() {
    if (!_showFilters) return const SizedBox.shrink();
    final filterChipColor = Theme.of(
      context,
    ).colorScheme.primary.withOpacity(0.1);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, size: Space.small),
        vertical: Responsive.space(context, size: Space.small),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Row(
              children: [
                // Department chips
                ..._departments
                    .where((dep) => dep.isNotEmpty)
                    .map(
                      (dep) => Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.space(
                            context,
                            size: Space.tiny,
                          ),
                        ),
                        child: ChoiceChip(
                          label: Text(
                            dep,
                            style: TextStyle(
                              fontSize: Responsive.text(
                                context,
                                size: TextSize.small,
                              ),
                            ),
                          ),
                          selected: _departmentFilter == dep,
                          onSelected:
                              (selected) => setState(
                                () => _departmentFilter = selected ? dep : '',
                              ),
                          selectedColor: Colors.blue.shade100,
                          backgroundColor: filterChipColor,
                          labelStyle: TextStyle(
                            color:
                                _departmentFilter == dep
                                    ? Colors.blue
                                    : Colors.black,
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.small,
                            ),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: Responsive.space(
                              context,
                              size: Space.small,
                            ),
                            vertical: Responsive.space(
                              context,
                              size: Space.tiny,
                            ),
                          ),
                        ),
                      ),
                    ),
                SizedBox(width: Responsive.space(context, size: Space.small)),
                // Date chips
                ...[
                  {'label': 'اليوم', 'value': 'today'},
                  {'label': 'هذا الأسبوع', 'value': 'week'},
                ].map(
                  (d) => Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.space(context, size: Space.tiny),
                    ),
                    child: ChoiceChip(
                      label: Text(
                        d['label']!,
                        style: TextStyle(
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.small,
                          ),
                        ),
                      ),
                      selected: _dateFilter == d['value'],
                      onSelected:
                          (selected) => setState(
                            () => _dateFilter = selected ? d['value']! : '',
                          ),
                      selectedColor: Colors.green.shade100,
                      backgroundColor: filterChipColor,
                      labelStyle: TextStyle(
                        color:
                            _dateFilter == d['value']
                                ? Colors.green
                                : Colors.black,
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.small,
                        ),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.space(
                          context,
                          size: Space.small,
                        ),
                        vertical: Responsive.space(context, size: Space.tiny),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: Responsive.space(context, size: Space.small)),
                // Pinned chips
                ...[
                  {'label': 'مثبت', 'value': 'pinned'},
                  {'label': 'غير مثبت', 'value': 'not_pinned'},
                ].map(
                  (p) => Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.space(context, size: Space.tiny),
                    ),
                    child: ChoiceChip(
                      label: Text(
                        p['label']!,
                        style: TextStyle(
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.small,
                          ),
                        ),
                      ),
                      selected: _pinnedFilter == p['value'],
                      onSelected:
                          (selected) => setState(
                            () => _pinnedFilter = selected ? p['value']! : '',
                          ),
                      selectedColor: Colors.orange.shade100,
                      backgroundColor: filterChipColor,
                      labelStyle: TextStyle(
                        color:
                            _pinnedFilter == p['value']
                                ? Colors.orange
                                : Colors.black,
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.small,
                        ),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.space(
                          context,
                          size: Space.small,
                        ),
                        vertical: Responsive.space(context, size: Space.tiny),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: Responsive.space(context, size: Space.small)),
                // Clear button
                if (_departmentFilter.isNotEmpty ||
                    _dateFilter.isNotEmpty ||
                    _pinnedFilter.isNotEmpty)
                  TextButton(
                    onPressed:
                        () => setState(() {
                          _departmentFilter = '';
                          _dateFilter = '';
                          _pinnedFilter = '';
                        }),
                    child: Text(
                      'مسح',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.small,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: Responsive.space(context, size: Space.small)),
        ],
      ),
    );
  }

  Widget _buildAnalyticsBar(List<AnnouncementData> announcements) {
    if (!_showAnalytics) return const SizedBox.shrink();
    final total = announcements.length;
    final pinned = announcements.where((a) => a.pinned).length;
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final thisWeek =
        announcements.where((a) => a.timestamp.isAfter(weekAgo)).length;
    final Map<String, int> deptCounts = {'SC': 0, 'AI': 0, 'CS': 0, 'IS': 0};
    for (final a in announcements) {
      for (final d in deptCounts.keys) {
        if (a.tags.contains('اخبار قسم $d')) deptCounts[d] = deptCounts[d]! + 1;
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
              borderRadius: BorderRadius.circular(16),
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
    final userProfile =
        Provider.of<UserProfileProvider>(context, listen: false).userProfile;
    return Consumer<AnnouncementProvider>(
      builder: (context, announcementProvider, child) {
        final filteredAnnouncements = _filterAnnouncements(
          announcementProvider.announcements,
        );
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: Text(
              'المطبخ',
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.heading),
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz, color: Colors.black),
                tooltip: 'خيارات',
                offset: const Offset(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.white,
                itemBuilder: (context) {
                  final List<PopupMenuEntry<String>> items = [
                    PopupMenuItem(
                      value: 'search',
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          leading: Icon(
                            _showSearch ? Icons.close : Icons.search,
                            size: 26,
                            color: Colors.black,
                          ),

                          horizontalTitleGap: 0,
                          dense: true,
                          minLeadingWidth: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'filters',
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          leading: Icon(
                            _showFilters
                                ? Icons.filter_alt
                                : Icons.filter_alt_outlined,
                            size: 26,
                            color: Colors.black,
                          ),
                          horizontalTitleGap: 0,
                          dense: true,
                          minLeadingWidth: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'analytics',
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          leading: Icon(
                            _showAnalytics
                                ? Icons.bar_chart
                                : Icons.bar_chart_outlined,
                            size: 26,
                            color: Colors.black,
                          ),
                          horizontalTitleGap: 0,
                          dense: true,
                          minLeadingWidth: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                  } else if (value == 'filters') {
                    setState(() => _showFilters = !_showFilters);
                  } else if (value == 'analytics') {
                    setState(() => _showAnalytics = !_showAnalytics);
                  } else if (value == 'settings') {
                    Navigator.pushNamed(context, '/super-admin-panel');
                  }
                },
              ),
            ],
            surfaceTintColor: Colors.white,
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(
                (_showSearch ? 56 : 0) +
                    (_showFilters
                        ? (Responsive.space(context, size: Space.large) * 2)
                        : 0),
              ),
              child: Column(
                children: [_buildAppBarSearchField(), _buildFilterBar()],
              ),
            ),
          ),
          body: SafeArea(
            child: Stack(
              children: [
                announcementProvider.isLoading
                    ? Center(
                      child: Lottie.asset(
                        'assets/animation/update.json',
                        width:
                            Responsive.space(context, size: Space.large) * 2.5,
                        height:
                            Responsive.space(context, size: Space.large) * 2.5,
                        repeat: true,
                      ),
                    )
                    : Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.space(
                          context,
                          size: Space.medium,
                        ),
                        vertical: Responsive.space(context, size: Space.medium),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_showAnalytics)
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: Responsive.space(
                                  context,
                                  size: Space.medium,
                                ),
                              ),
                              child: _buildAnalyticsBar(
                                announcementProvider.announcements,
                              ),
                            ),
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
                                itemCount: filteredAnnouncements.length,
                                itemBuilder: (context, index) {
                                  final announcement =
                                      filteredAnnouncements[index];
                                  return Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: Responsive.space(
                                        context,
                                        size: Space.small,
                                      ),
                                    ),
                                    child: AnnouncementCard(
                                      announcement: announcement,
                                      onEdit:
                                          () => _editAnnouncement(announcement),
                                      onDelete:
                                          () =>
                                              _deleteAnnouncement(announcement),
                                      onPin:
                                          () => _pinAnnouncement(announcement),
                                      onUnpin:
                                          () =>
                                              _unpinAnnouncement(announcement),
                                    ),
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
                  child: CircularButton(
                    onPressed: () {
                      showAddAnnouncementDialog(
                        context: context,
                        onSave: (newAnnouncement) {
                          announcementProvider.addAnnouncement(newAnnouncement);
                        },
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
      },
    );
  }

  void _editAnnouncement(AnnouncementData announcement) {
    final provider = Provider.of<AnnouncementProvider>(context, listen: false);
    showAddAnnouncementDialog(
      context: context,
      isEditing: true,
      announcement: announcement,
      onSave: (newAnnouncement) {
        provider.updateAnnouncement(newAnnouncement);
      },
    );
  }

  void _deleteAnnouncement(AnnouncementData announcement) {
    final provider = Provider.of<AnnouncementProvider>(context, listen: false);
    if (announcement.id != null) {
      provider.deleteAnnouncement(announcement.id!);
    }
  }

  void _pinAnnouncement(AnnouncementData announcement) {
    final provider = Provider.of<AnnouncementProvider>(context, listen: false);
    provider.pinAnnouncement(announcement);
  }

  void _unpinAnnouncement(AnnouncementData announcement) {
    final provider = Provider.of<AnnouncementProvider>(context, listen: false);
    provider.unpinAnnouncement(announcement);
  }
}
