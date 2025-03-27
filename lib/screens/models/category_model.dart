import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';

class CategoryButton extends StatelessWidget {
  const CategoryButton({
    super.key,
    required this.selected,
    required this.title,
    required this.onSelected,
  });
  
  final bool selected;
  final String title;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, size: Space.small),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.space(context, size: Space.medium),
            vertical: Responsive.space(context, size: Space.small),
          ),
          backgroundColor: selected ? Colors.black : Color(0xffD9D9D9),
          foregroundColor: selected ? Color(0xffD9D9D9) : Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              Responsive.space(context, size: Space.medium),
            ),
          ),
        ),
        onPressed: onSelected,
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: Responsive.text(context, size: TextSize.medium),
          ),
        ),
      ),
    );
  }
}
