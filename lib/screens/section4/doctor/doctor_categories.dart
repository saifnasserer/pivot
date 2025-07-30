import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';

class DoctorCategories extends StatefulWidget {
  DoctorCategories({
    super.key,
    this.onCategoryChanged,
    this.showBackButton = false,
    this.showEditButton = false,
    this.showMenuButton = false,
    this.onBackPressed,
    this.onEditPressed,
    this.onMenuPressed,
  });
  final void Function(String category)? onCategoryChanged;
  final List<String> categories = ['عن الدكتور', 'المواد'];
  final bool showBackButton;
  final bool showEditButton;
  final bool showMenuButton;
  final VoidCallback? onBackPressed;
  final VoidCallback? onEditPressed;
  final VoidCallback? onMenuPressed;

  @override
  State<DoctorCategories> createState() => DoctorCategoriesState();
}

class DoctorCategoriesState extends State<DoctorCategories>
    with TickerProviderStateMixin {
  int selectedIndex = 1; // Default to المواد (Materials)
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onCategorySelected(int index) {
    if (selectedIndex != index) {
      setState(() {
        selectedIndex = index;
      });
      _animationController.forward().then((_) {
        _animationController.reverse();
      });
      widget.onCategoryChanged?.call(widget.categories[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, size: Space.medium),
        vertical: Responsive.space(context, size: Space.small),
      ),
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
      child: Row(
        children: [
          // Back button
          if (widget.showBackButton)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: widget.onBackPressed,
            ),
          // Categories
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildEnhancedCategoryButton(
                    index: 0,
                    title: widget.categories[0], // عن الدكتور
                    isSelected: selectedIndex == 0,
                  ),
                ),
                Expanded(
                  child: _buildEnhancedCategoryButton(
                    index: 1,
                    title: widget.categories[1], // المواد
                    isSelected: selectedIndex == 1,
                  ),
                ),
              ],
            ),
          ),
          // Action buttons
          if (widget.showEditButton)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.black),
              onPressed: widget.onEditPressed,
            ),
          if (widget.showMenuButton)
            IconButton(
              icon: const Icon(Icons.more_vert_sharp, color: Colors.black),
              onPressed: widget.onMenuPressed,
            ),
        ],
      ),
    );
  }

  Widget _buildEnhancedCategoryButton({
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
        onTap: () => _onCategorySelected(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: EdgeInsets.all(Responsive.space(context, size: Space.tiny)),
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
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: Responsive.space(context, size: Space.small),
              horizontal: Responsive.space(context, size: Space.small),
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
      ),
    );
  }
}
