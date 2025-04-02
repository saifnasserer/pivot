import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';

/// A reusable text field component used throughout the app.
///
/// This text field is designed with consistent styling and validation
/// for use in forms across the application.
class CustomTextField extends StatelessWidget {
  /// Creates a custom text field.
  ///
  /// The [hint], [onChanged], and [validator] parameters are required.
  const CustomTextField({
    super.key,
    required this.hint,
    required this.onChanged,
    required this.validator,
    this.focusNode,
    this.textInputAction = TextInputAction.next,
    this.keyboardType = TextInputType.text,
    this.onEditingComplete,
    this.obscureText = false,
    this.suffixIcon,
    this.isValid = false,
  });

  /// The hint text to display when the field is empty.
  final String hint;

  /// Called when the text field's value changes.
  final Function(String) onChanged;

  /// Validates the text field's value.
  final String? Function(String?) validator;

  /// The focus node for this text field.
  final FocusNode? focusNode;

  /// The keyboard action button. Defaults to TextInputAction.next.
  final TextInputAction textInputAction;

  /// The type of keyboard to use. Defaults to TextInputType.text.
  final TextInputType keyboardType;

  /// Called when the user submits the text field.
  final VoidCallback? onEditingComplete;

  /// Whether to obscure the text (for passwords). Defaults to false.
  final bool obscureText;

  /// An optional widget to display at the end of the text field.
  final Widget? suffixIcon;

  /// Whether the field's current value is valid. Defaults to false.
  final bool isValid;

  /// Creates the common input decoration used across text fields.
  InputDecoration _getInputDecoration(BuildContext context) {
    return InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.medium),
        ),
        borderSide: BorderSide(color: Color(0xFFF7F7F7)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.medium),
        ),
        borderSide: BorderSide(
          color: isValid ? Colors.green : Color(0xFFF7F7F7),
          width: isValid ? 2 : 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.medium),
        ),
        borderSide: BorderSide(
          color: isValid ? Colors.green : Colors.black,
          width: isValid ? 2 : 1,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.medium),
        ),
        borderSide: BorderSide(color: Colors.red),
      ),
      hintText: hint,
      filled: true,
      fillColor: Color(0xFFF7F7F7),
      hintStyle: TextStyle(
        color: Colors.black,
        fontSize: Responsive.text(context, size: TextSize.medium),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, size: Space.medium),
        vertical: Responsive.space(context, size: Space.small),
      ),
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      focusNode: focusNode,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
      textInputAction: textInputAction,
      onEditingComplete: onEditingComplete,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: TextStyle(
        color: Colors.black,
        fontSize: Responsive.text(context, size: TextSize.medium),
      ),
      onChanged: onChanged,
      decoration: _getInputDecoration(context),
      textCapitalization: TextCapitalization.words,
    );
  }
}
