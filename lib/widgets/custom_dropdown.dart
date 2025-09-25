import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';

/// A robust and flexible dropdown component with enhanced validation and error handling.
///
/// Features:
/// - Automatic duplicate removal
/// - Value validation
/// - Custom styling options
/// - Error state handling
/// - Accessibility support
class CustomDropdown extends StatelessWidget {
  /// Creates a custom dropdown with enhanced features.
  const CustomDropdown({
    super.key,
    required this.items,
    required this.hint,
    required this.onChanged,
    this.value,
    this.isValid = true,
    this.showError = false,
    this.errorText,
    this.color = Colors.white,
    this.disabled = false,
    this.required = false,
    this.icon,
    this.borderRadius,
    this.padding,
    this.textStyle,
    this.hintStyle,
  });

  /// The background color of the dropdown. Defaults to white.
  final Color color;

  /// The list of items to display in the dropdown.
  final List<String> items;

  /// The hint text to display when no item is selected.
  final String hint;

  /// Called when the user selects an item.
  final Function(String?) onChanged;

  /// The currently selected value.
  final String? value;

  /// Whether the field's current value is valid. Defaults to true.
  final bool isValid;

  /// Whether to show error state. Defaults to false.
  final bool showError;

  /// Custom error text to display.
  final String? errorText;

  /// Whether the dropdown is disabled. Defaults to false.
  final bool disabled;

  /// Whether the field is required. Defaults to false.
  final bool required;

  /// Custom icon to display. Defaults to dropdown arrow.
  final Widget? icon;

  /// Custom border radius. Defaults to large spacing.
  final double? borderRadius;

  /// Custom padding. Defaults to medium spacing.
  final EdgeInsetsGeometry? padding;

  /// Custom text style for the selected value.
  final TextStyle? textStyle;

  /// Custom hint text style.
  final TextStyle? hintStyle;

  /// Creates the common decoration used across dropdowns.
  BoxDecoration _getDropdownDecoration(BuildContext context) {
    final radius = borderRadius ?? Responsive.space(context, size: Space.large);

    return BoxDecoration(
      color: disabled ? Colors.grey.shade100 : color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: _getBorderColor(context),
        width: _getBorderWidth(),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// Gets the appropriate border color based on state.
  Color _getBorderColor(BuildContext context) {
    if (showError) return const Color(0xFFE57373);
    if (isValid) return const Color(0xFF4CAF50);
    if (disabled) return Colors.grey.shade300;
    return Colors.grey.shade300;
  }

  /// Gets the appropriate border width based on state.
  double _getBorderWidth() {
    if (showError || isValid) return 2;
    return 1;
  }

  /// Creates the common text style used across dropdowns.
  TextStyle _getDropdownTextStyle(BuildContext context) {
    return textStyle ??
        TextStyle(
          color: _getTextColor(),
          fontSize: Responsive.text(context, size: TextSize.medium),
          fontWeight: FontWeight.w500,
          height: 1.2,
        );
  }

  /// Gets the appropriate text color based on state.
  Color _getTextColor() {
    if (disabled) return Colors.grey.shade600;
    return Colors.black;
  }

  /// Validates and cleans the dropdown items to prevent duplicates and empty values.
  List<String> _getValidItems() {
    final seen = <String>{};
    final validItems = <String>[];

    for (final item in items) {
      if (item.trim().isNotEmpty && !seen.contains(item.trim())) {
        seen.add(item.trim());
        validItems.add(item.trim());
      }
    }

    return validItems;
  }

  /// Gets a valid value for the dropdown.
  String? _getValidValue() {
    final validItems = _getValidItems();

    if (value == null || !validItems.contains(value)) {
      return null;
    }

    return value;
  }

  /// Gets the appropriate hint text.
  String _getHintText() {
    if (required) return '$hint *';
    return hint;
  }

  @override
  Widget build(BuildContext context) {
    final validItems = _getValidItems();
    final validValue = _getValidValue();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: _getDropdownDecoration(context),
          padding:
              padding ??
              EdgeInsets.symmetric(
                horizontal: Responsive.space(context, size: Space.small) * 2,
                vertical: Responsive.space(context, size: Space.small) / 2,
              ),
          constraints: BoxConstraints(
            minHeight: Responsive.space(context, size: Space.small),
          ),
          child: DropdownButton<String>(
            value: validValue,
            isExpanded: true,
            isDense: false,
            dropdownColor: color,
            borderRadius: BorderRadius.circular(
              borderRadius ?? Responsive.space(context, size: Space.large),
            ),
            hint: Container(
              alignment: Alignment.centerRight,
              width: double.infinity,
              child: Text(
                _getHintText(),
                textAlign: TextAlign.right,
                style:
                    hintStyle ??
                    _getDropdownTextStyle(context).copyWith(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w400,
                    ),
              ),
            ),
            underline: Container(),
            icon:
                icon ??
                Icon(Icons.arrow_drop_down, color: _getTextColor(), size: 24),
            items:
                validItems
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item,
                        child: Container(
                          alignment: Alignment.centerRight,
                          width: double.infinity,
                          child: Text(
                            item,
                            textAlign: TextAlign.right,
                            style: _getDropdownTextStyle(context),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    )
                    .toList(),
            onChanged: disabled ? null : onChanged,
          ),
        ),
        if (showError && errorText != null) ...[
          SizedBox(height: Responsive.space(context, size: Space.tiny)),
          Padding(
            padding: EdgeInsets.only(
              left: Responsive.space(context, size: Space.small),
            ),
            child: Text(
              errorText!,
              style: TextStyle(
                color: Colors.red,
                fontSize: Responsive.text(context, size: TextSize.small),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
