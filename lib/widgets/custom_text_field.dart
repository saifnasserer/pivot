import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';

/// A robust and flexible text field component with enhanced validation and error handling.
///
/// Features:
/// - Comprehensive validation
/// - Error state handling
/// - Custom styling options
/// - Accessibility support
/// - RTL support
/// - Password visibility toggle
class CustomTextField extends StatelessWidget {
  /// Creates a custom text field with enhanced features.
  const CustomTextField({
    super.key,
    required this.hint,
    this.onChanged,
    this.validator,
    this.focusNode,
    this.textInputAction = TextInputAction.next,
    this.keyboardType = TextInputType.text,
    this.onEditingComplete,
    this.obscureText = false,
    this.suffixIcon,
    this.prefixIcon,
    this.isValid = true,
    this.showError = false,
    this.errorText,
    this.minLines,
    this.maxLines = 1,
    this.controller,
    this.textCapitalization = TextCapitalization.none,
    this.enabled = true,
    this.required = false,
    this.maxLength,
    this.counterText,
    this.borderRadius,
    this.padding,
    this.textStyle,
    this.hintStyle,
    this.errorStyle,
    this.fillColor,
    this.borderColor,
    this.focusedBorderColor,
    this.errorBorderColor,
    this.onTap,
    this.readOnly = false,
    this.autofocus = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.textAlign = TextAlign.right,
    this.textDirection = TextDirection.rtl,
  });

  /// The hint text to display.
  final String hint;

  /// Called when the text changes.
  final Function(String)? onChanged;

  /// Validator function for the text field.
  final String? Function(String?)? validator;

  /// Controller for the text field.
  final TextEditingController? controller;

  /// Focus node for the text field.
  final FocusNode? focusNode;

  /// The action to take when the user submits the text field.
  final TextInputAction textInputAction;

  /// The type of keyboard to show.
  final TextInputType keyboardType;

  /// Called when the user finishes editing.
  final VoidCallback? onEditingComplete;

  /// Whether to obscure the text (for passwords).
  final bool obscureText;

  /// Icon to display at the end of the text field.
  final Widget? suffixIcon;

  /// Icon to display at the beginning of the text field.
  final Widget? prefixIcon;

  /// Whether the field's current value is valid. Defaults to true.
  final bool isValid;

  /// Whether to show error state. Defaults to false.
  final bool showError;

  /// Custom error text to display.
  final String? errorText;

  /// Minimum number of lines for the text field.
  final int? minLines;

  /// Maximum number of lines for the text field.
  final int? maxLines;

  /// Whether the field is required. Defaults to false.
  final bool required;

  /// Maximum number of characters allowed.
  final int? maxLength;

  /// Custom counter text to display.
  final String? counterText;

  /// Custom border radius. Defaults to large spacing.
  final double? borderRadius;

  /// Custom padding. Defaults to medium spacing.
  final EdgeInsetsGeometry? padding;

  /// Custom text style for the input text.
  final TextStyle? textStyle;

  /// Custom hint text style.
  final TextStyle? hintStyle;

  /// Custom error text style.
  final TextStyle? errorStyle;

  /// Background fill color. Defaults to light grey.
  final Color? fillColor;

  /// Border color. Defaults to light grey.
  final Color? borderColor;

  /// Focused border color. Defaults to black.
  final Color? focusedBorderColor;

  /// Error border color. Defaults to red.
  final Color? errorBorderColor;

  /// Called when the text field is tapped.
  final VoidCallback? onTap;

  /// Whether the text field is enabled. Defaults to true.
  final bool enabled;

  /// Whether the text field is read-only. Defaults to false.
  final bool readOnly;

  /// Whether the text field should have focus initially. Defaults to false.
  final bool autofocus;

  /// Whether to enable autocorrect. Defaults to true.
  final bool autocorrect;

  /// Whether to enable suggestions. Defaults to true.
  final bool enableSuggestions;

  /// Text alignment. Defaults to center.
  final TextAlign textAlign;

  /// Text direction. Defaults to RTL.
  final TextDirection textDirection;

  /// Text capitalization. Defaults to none.
  final TextCapitalization textCapitalization;

  /// Creates the input decoration for the text field.
  InputDecoration _getInputDecoration(BuildContext context) {
    final radius = borderRadius ?? Responsive.space(context, size: Space.large);

    return InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: _getBorderColor()),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(
          color: _getBorderColor(),
          width: _getBorderWidth(),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(
          color: _getFocusedBorderColor(),
          width: _getBorderWidth(),
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(
          color: _getErrorBorderColor(),
          width: _getBorderWidth(),
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(
          color: _getErrorBorderColor(),
          width: _getBorderWidth(),
        ),
      ),
      hintText: _getHintText(),
      filled: true,
      fillColor: _getFillColor(),
      hintStyle:
          hintStyle ??
          TextStyle(
            color: Colors.grey.shade600,
            fontSize: Responsive.text(context, size: TextSize.medium),
            fontWeight: FontWeight.w400,
          ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, size: Space.small) * 2,
        vertical: Responsive.space(context, size: Space.small) * 2,
      ),
      isDense: false,
      constraints: BoxConstraints(
        minHeight: Responsive.space(context, size: Space.large) * 1.5,
      ),
      suffixIcon: suffixIcon,
      prefixIcon: prefixIcon,
      counterText: counterText,
      errorText: showError && errorText != null ? errorText : null,
      errorStyle:
          errorStyle ??
          TextStyle(
            color: Colors.red,
            fontSize: Responsive.text(context, size: TextSize.small),
          ),
    );
  }

  /// Gets the appropriate border color based on state.
  Color _getBorderColor() {
    if (showError) return errorBorderColor ?? const Color(0xFFE57373);
    if (isValid) return const Color(0xFF4CAF50);
    if (!enabled) return Colors.grey.shade400;
    return borderColor ?? Colors.grey.shade300;
  }

  /// Gets the appropriate focused border color.
  Color _getFocusedBorderColor() {
    if (showError) return errorBorderColor ?? const Color(0xFFE57373);
    if (isValid) return const Color(0xFF4CAF50);
    return focusedBorderColor ?? const Color(0xFF2196F3);
  }

  /// Gets the appropriate error border color.
  Color _getErrorBorderColor() {
    return errorBorderColor ?? Colors.red;
  }

  /// Gets the appropriate border width based on state.
  double _getBorderWidth() {
    if (showError || isValid) return 2;
    return 1;
  }

  /// Gets the appropriate fill color.
  Color _getFillColor() {
    if (!enabled) return Colors.grey.shade100;
    return fillColor ?? Colors.white;
  }

  /// Gets the appropriate hint text.
  String _getHintText() {
    if (required) return '$hint *';
    return hint;
  }

  /// Gets the appropriate text style.
  TextStyle _getTextStyle(BuildContext context) {
    return textStyle ??
        TextStyle(
          color: enabled ? Colors.black87 : Colors.grey.shade600,
          fontSize: Responsive.text(context, size: TextSize.medium),
          fontWeight: FontWeight.w500,
          height: 1.2,
        );
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      textDirection: textDirection,
      textAlign: textAlign,
      textInputAction: textInputAction,
      onEditingComplete: onEditingComplete,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      enabled: enabled,
      readOnly: readOnly,
      autofocus: autofocus,
      autocorrect: autocorrect,
      enableSuggestions: enableSuggestions,
      style: _getTextStyle(context),
      minLines: minLines,
      maxLines: maxLines,
      maxLength: maxLength,
      onChanged: onChanged,
      onTap: onTap,
      decoration: _getInputDecoration(context),
      textCapitalization: textCapitalization,
    );
  }
}
