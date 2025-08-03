import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/providers/announcement_provider.dart';
import 'package:provider/provider.dart';

class LandingCategories extends StatefulWidget {
  const LandingCategories({
    super.key,
    this.userDepartment,
    this.onCategoryChanged,
    this.tabController, // Add tab controller for syncing
  });

  final String? userDepartment;
  final void Function(String category)? onCategoryChanged;
  final TabController? tabController; // Add this

  @override
  State<LandingCategories> createState() => _LandingCategoriesState();
}

class _LandingCategoriesState extends State<LandingCategories>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  int _selectedIndex = 0;

  List<String> get categories {
    final baseCategories = [
      'اخبار النهاردة',
      'عام',
      'SC',
      'AI',
      'CS',
      'IS',
      'General',
    ];

    // If no user department, return default order (now for LTR)
    if (widget.userDepartment == null) {
      return baseCategories;
    }

    // Create ordered list: General - Departments - عام - اخبار النهاردة
    final orderedCategories = <String>[];

    // 1. General (first)
    orderedCategories.add('General');

    // 2. Departments (SC, AI, CS, IS)
    final departments = ['SC', 'AI', 'CS', 'IS'];
    for (final dept in departments) {
      if (baseCategories.contains(dept)) {
        orderedCategories.add(dept);
      }
    }

    // 3. عام
    orderedCategories.add('عام');

    // 4. اخبار النهاردة (last)
    orderedCategories.add('اخبار النهاردة');

    return orderedCategories;
  }

  @override
  void initState() {
    super.initState();
    // Use provided TabController or create new one
    if (widget.tabController != null) {
      _tabController = widget.tabController!;
    } else {
      _tabController = TabController(
        length: categories.length,
        vsync: this,
        initialIndex: 0, // Start from first tab for proper scroll position
      );
    }

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Listen to tab controller changes
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _onCategorySelected(_tabController.index);
      }
    });

    // Trigger initial category selection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // First select the last category for content
      _onCategorySelected(categories.length - 1);

      // Then animate to the last tab to show it as selected
      _tabController.animateTo(categories.length - 1);
    });
  }

  @override
  void dispose() {
    // Only dispose if we created the TabController locally
    if (widget.tabController == null) {
      _tabController.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  void _onCategorySelected(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });

      // Trigger animation
      _animationController.forward().then((_) {
        _animationController.reverse();
      });

      // Handle category change logic
      final category = categories[index];
      _handleCategoryChange(category);
      widget.onCategoryChanged?.call(category);
    }
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
      if (widget.userDepartment != null &&
          widget.userDepartment!.startsWith('اخبار قسم ')) {
        normalizedDepartment = widget.userDepartment!.replaceFirst(
          'اخبار قسم ',
          '',
        );
      } else {
        normalizedDepartment = widget.userDepartment;
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr, // Change to LTR to fix end space issue
      child: Container(
        // Remove margin completely to ensure first tab starts from beginning
        margin: EdgeInsets.zero,
        // Reduce height and padding for a more compact look
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(
            Responsive.space(context, size: Space.large),
          ),
          border: Border.all(color: Colors.grey.shade200, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.transparent,
          dividerColor: Colors.transparent,
          labelPadding: EdgeInsets.symmetric(
            horizontal: Responsive.space(context, size: Space.tiny),
          ),
          padding: EdgeInsets.zero, // Remove all padding
          // Reduce height using preferredSizeWidget and content padding
          tabs: List.generate(
            categories.length,
            (index) => _buildEnhancedTab(
              index: index,
              title: categories[index],
              isSelected: _selectedIndex == index,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedTab({
    required int index,
    required String title,
    required bool isSelected,
  }) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isSelected ? 1.0 + (_slideAnimation.value * 0.05) : 1.0,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(
                Responsive.space(context, size: Space.large),
              ),
              onTap: () {
                _tabController.animateTo(index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                margin: EdgeInsets.only(
                  left:
                      index == 0
                          ? 0
                          : Responsive.space(context, size: Space.tiny),
                  right: 0, // Remove right margin for all tabs
                  top: Responsive.space(context, size: Space.tiny),
                  bottom: Responsive.space(context, size: Space.tiny),
                ),
                padding: EdgeInsets.symmetric(
                  vertical: Responsive.space(context, size: Space.small),
                  horizontal: Responsive.space(context, size: Space.medium),
                ),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.circular(
                    Responsive.space(context, size: Space.large),
                  ),
                  border: Border.all(
                    color: isSelected ? Colors.black : Colors.grey.shade300,
                    width: 1,
                  ),
                  boxShadow:
                      isSelected
                          ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ]
                          : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                ),
                child: Center(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: Responsive.text(context, size: TextSize.medium),
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.black87,
                      fontFamily: 'NotoSansArabic',
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
