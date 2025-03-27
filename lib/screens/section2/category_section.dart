import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/section2/models/category_model.dart';

class CategorySection extends StatefulWidget {
  const CategorySection({super.key, this.onCategoryChanged});
  final void Function(String category)? onCategoryChanged;

  @override
  State<CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends State<CategorySection> {
  int selectedIndex = 0;

  final List<String> categories = [
    'اخبار النهاردة',
    'اخبار الاسبوع',
    'اخبار قسم SC',
    'اخبار قسم AI',
    'اخبار قسم CS',
    'اخبار قسم IS',
  ];

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
