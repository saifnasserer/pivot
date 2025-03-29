import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';

/// A reusable dropdown component used throughout the app.
///
/// This dropdown is designed with consistent styling and validation
/// for use in forms across the application.
class CustomDropdown extends StatelessWidget {
  /// Creates a custom dropdown.
  ///
  /// The [items], [hint], and [onChanged] parameters are required.
  const CustomDropdown({
    super.key,
    required this.items,
    required this.hint,
    required this.onChanged,
    this.value,
    this.isValid = false,
    this.color = Colors.black,
  });

  /// The background color of the dropdown. Defaults to black.
  final Color color;

  /// The list of items to display in the dropdown.
  final List<String> items;

  /// The hint text to display when no item is selected.
  final String hint;

  /// Called when the user selects an item.
  final Function(String?) onChanged;

  /// The currently selected value.
  final String? value;

  /// Whether the field's current value is valid. Defaults to false.
  final bool isValid;

  /// Creates the common decoration used across dropdowns.
  BoxDecoration _getDropdownDecoration(BuildContext context) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(
        Responsive.space(context, size: Space.medium),
      ),
      border: Border.all(
        color: isValid ? Colors.green : Color(0xfff7f7f7),
        width: isValid ? 2 : 1,
      ),
    );
  }

  /// Creates the common text style used across dropdowns.
  TextStyle _getDropdownTextStyle(BuildContext context) {
    return TextStyle(
      color: color != Colors.black ? Colors.black : Colors.white,
      fontSize: Responsive.text(context, size: TextSize.medium),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _getDropdownDecoration(context),
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, size: Space.medium),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        dropdownColor: color,
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.medium),
        ),
        hint: Container(
          width: double.infinity,
          alignment: Alignment.center,
          child: Text(
            hint,
            textAlign: TextAlign.center,
            style: _getDropdownTextStyle(context),
          ),
        ),
        underline: Container(),
        items:
            items
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item,
                    child: Container(
                      alignment: Alignment.center,
                      child: Text(
                        item,
                        textAlign: TextAlign.center,
                        style: _getDropdownTextStyle(context),
                      ),
                    ),
                  ),
                )
                .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
