import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/services/category_service.dart';
import 'package:pivot/responsive.dart';

class LandingCategories extends ConsumerStatefulWidget {
  const LandingCategories({
    super.key,
    this.userDepartment,
    this.onCategoryChanged,
    this.tabController,
    this.categories, // Add categories parameter
  });

  final String? userDepartment;
  final void Function(String category)? onCategoryChanged;
  final TabController? tabController;
  final List<String>? categories; // Add this

  @override
  ConsumerState<LandingCategories> createState() => _LandingCategoriesState();
}

class _LandingCategoriesState extends ConsumerState<LandingCategories>
    with TickerProviderStateMixin {
  late TabController _tabController;

  List<String> get categories {
    // Use passed categories if available, otherwise generate them
    if (widget.categories != null) {
      return widget.categories!;
    }
    return CategoryService.getCategories(widget.userDepartment);
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
        initialIndex:
            categories.length -
            1, // Start from rightmost tab (اخبار النهاردة) for RTL
      );
    }

    // Listen to tab controller changes
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _onCategorySelected(_tabController.index);
      }
    });

    // Set initial category
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (categories.isNotEmpty) {
        // Don't trigger category selection here - let Landing.dart handle it
        // _onCategorySelected(categories.length - 1); // Commented out to avoid conflicts
      }
    });
  }

  @override
  void dispose() {
    // Only dispose if we created the TabController locally
    if (widget.tabController == null) {
      _tabController.dispose();
    }
    super.dispose();
  }

  void _onCategorySelected(int index) {
    if (index < categories.length) {
      final category = categories[index];
      _handleCategoryChange(category);
      widget.onCategoryChanged?.call(category);
    }
  }

  void _handleCategoryChange(String category) {
    // Note: Announcement fetching is now handled in landing.dart's _handleCategoryChange
    // to ensure user level filtering is applied correctly.
    // This method is kept for backwards compatibility but doesn't fetch announcements anymore.
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.zero,
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
            isSelected: _tabController.index == index,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.large),
        ),
        onTap: () {
          print(
            '🔍 [LandingCategories] Tab clicked: index $index, category: ${categories[index]}',
          );
          // Only animate if not already at the target index
          if (_tabController.index != index) {
            _tabController.animateTo(index);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          margin: EdgeInsets.only(
            left: index == 0 ? 0 : Responsive.space(context, size: Space.tiny),
            right: 0,
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
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : Colors.black87,
                fontFamily: 'NotoSansArabic',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
