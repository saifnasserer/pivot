import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/models/category_model.dart';

class AssistantCategories extends StatefulWidget {
  AssistantCategories({super.key, this.onCategoryChanged});
  final void Function(String category)? onCategoryChanged;
  final List<String> categories = ['المواد', 'عن الدكتور'];
  @override
  State<AssistantCategories> createState() => AssistantCategoriesState();
}

class AssistantCategoriesState extends State<AssistantCategories> {
  int selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: Responsive.space(context, size: Space.xlarge) * 1.4,
      child: Row(
        children: [
          // المواد button - takes remaining space
          // عن الدكتور button - natural width
          CategoryButton(
            selected: selectedIndex == 1,
            title: widget.categories[1],
            onSelected: () {
              setState(() {
                selectedIndex = 1;
              });
              widget.onCategoryChanged?.call(widget.categories[1]);
            },
          ),
          Expanded(
            child: CategoryButton(
              selected: selectedIndex == 0,
              title: widget.categories[0],
              onSelected: () {
                setState(() {
                  selectedIndex = 0;
                });
                widget.onCategoryChanged?.call(widget.categories[0]);
              },
            ),
          ),
        ],
      ),
    );
  }
}
