import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/models/category_model.dart';

class ProfileCategories extends StatefulWidget {
  ProfileCategories({super.key, this.onCategoryChanged});
  final void Function(String category)? onCategoryChanged;
  final List<String> categories = [
    'تاسكات الاسبوع',
    'الجدول',
    'مواد الترم',
    'السكاشن',
  ];
  @override
  State<ProfileCategories> createState() => PprofileCategoriesState();
}

class PprofileCategoriesState extends State<ProfileCategories> {
  int selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: Responsive.space(context, size: Space.xlarge) * 1.4,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        reverse: true,
        itemCount: widget.categories.length,
        itemBuilder: (context, index) {
          return CategoryButton(
            selected: selectedIndex == index,
            title: widget.categories[index],
            onSelected: () {
              setState(() {
                selectedIndex = index;
              });
              widget.onCategoryChanged?.call(widget.categories[index]);
            },
          );
        },
      ),
    );
  }
}
