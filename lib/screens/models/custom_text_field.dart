import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';

class CustomTextField extends StatelessWidget {
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

  final String hint;
  final Function(String) onChanged;
  final String? Function(String?) validator;
  final FocusNode? focusNode;
  final TextInputAction textInputAction;
  final TextInputType keyboardType;
  final VoidCallback? onEditingComplete;
  final bool obscureText;
  final Widget? suffixIcon;
  final bool isValid;

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
