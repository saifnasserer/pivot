import 'package:flutter/material.dart';
import 'package:pivot/screens/models/category_model.dart';
import 'package:pivot/responsive.dart';


class CategorySection extends StatefulWidget {
  const CategorySection({
    super.key,
    this.onCategoryChanged,
    this.userDepartment,
  });
  final void Function(String category)? onCategoryChanged;
  final String? userDepartment;

  @override
  State<CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends State<CategorySection> {
  int selectedIndex = 0;

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

    // If no user department, return default order
    if (widget.userDepartment == null) {
      //debugprint(
        // '[CATEGORY_SECTION] No user department, using default order: $baseCategories',
        // );
      return baseCategories;
    }

    // Create ordered list: Today's News - General - User's Department - Other Departments
    final orderedCategories = <String>[];

    // 1. Today's News (always first)
    orderedCategories.add('اخبار النهاردة');

    // 2. General (always second)
    orderedCategories.add('عام');

    // 3. User's Department (if it exists in the list)
    if (baseCategories.contains(widget.userDepartment)) {
      orderedCategories.add(widget.userDepartment!);
    }

    // 4. Other departments (excluding the ones already added)
    for (final category in baseCategories) {
      if (!orderedCategories.contains(category)) {
        orderedCategories.add(category);
      }
    }

    //debugprint('[CATEGORY_SECTION] User department: ${widget.userDepartment}');
    //debugprint('[CATEGORY_SECTION] Ordered categories: $orderedCategories');

    return orderedCategories;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: Responsive.space(context, size: Space.xlarge) * 1.4,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        reverse: true,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return CategoryButton(
            selected: selectedIndex == index,
            title: categories[index],
            onSelected: () {
              setState(() {
                selectedIndex = index;
              });
              widget.onCategoryChanged?.call(categories[index]);
            },
          );
        },
      ),
    );
  }
}
