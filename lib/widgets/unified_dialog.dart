import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'dart:ui' as ui;

/// A unified dialog component that follows the app's design system
/// This can be reused across all dialogs in the application
class UnifiedDialog extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget content;
  final List<Widget>? actions;
  final bool showActions;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;
  final String? cancelText;
  final String? confirmText;
  final IconData? confirmIcon;
  final bool isLoading;
  final double? maxWidth;
  final double? maxHeight;

  const UnifiedDialog({
    super.key,
    required this.title,
    this.subtitle,
    required this.content,
    this.actions,
    this.showActions = true,
    this.onCancel,
    this.onConfirm,
    this.cancelText = 'إلغاء',
    this.confirmText,
    this.confirmIcon,
    this.isLoading = false,
    this.maxWidth,
    this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            Responsive.space(context, size: Space.large),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 8,
        titlePadding: EdgeInsets.only(
          top: Responsive.space(context, size: Space.large),
          left: Responsive.space(context, size: Space.large),
          right: Responsive.space(context, size: Space.large),
          bottom: Responsive.space(context, size: Space.small),
        ),
        title: Column(
          children: [
            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.heading),
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            if (subtitle != null) ...[
              SizedBox(height: Responsive.space(context, size: Space.small)),
              // Subtitle
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.small),
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: Responsive.width(context) * 0.9,
            maxWidth: maxWidth ?? Responsive.width(context) * 0.9,
            maxHeight: maxHeight ?? Responsive.height(context) * 0.8,
          ),
          child: content,
        ),
        actionsPadding: EdgeInsets.symmetric(
          horizontal: Responsive.space(context, size: Space.large),
          vertical: Responsive.space(context, size: Space.medium),
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: showActions ? _buildActions(context) : null,
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    if (actions != null) {
      return actions!;
    }

    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Cancel Button
          if (onCancel != null)
            TextButton(
              onPressed: isLoading ? null : onCancel,
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.space(context, size: Space.medium),
                  vertical: Responsive.space(context, size: Space.small),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    Responsive.space(context, size: Space.large),
                  ),
                ),
              ),
              child: Text(
                cancelText ?? 'إلغاء',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.medium),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          // Confirm Button
          if (onConfirm != null)
            ElevatedButton.icon(
              icon:
                  isLoading
                      ? SizedBox(
                        width: Responsive.space(context, size: Space.medium),
                        height: Responsive.space(context, size: Space.medium),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : Icon(
                        confirmIcon ?? Icons.check,
                        size: Responsive.space(context, size: Space.medium),
                      ),
              label: Text(
                confirmText ?? 'حفظ',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.medium),
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    Responsive.space(context, size: Space.large),
                  ),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.space(context, size: Space.large),
                  vertical: Responsive.space(context, size: Space.small),
                ),
                elevation: 0,
              ),
              onPressed: isLoading ? null : onConfirm,
            ),
        ],
      ),
    ];
  }
}

/// A unified form field component for consistent styling
class UnifiedFormField extends StatelessWidget {
  final String? hint;
  final String? label;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLines;
  final int? minLines;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final bool readOnly;
  final VoidCallback? onTap;

  const UnifiedFormField({
    super.key,
    this.hint,
    this.label,
    this.controller,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.large),
        ),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        onChanged: onChanged,
        onFieldSubmitted: onFieldSubmitted,
        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLines: maxLines,
        minLines: minLines,
        enabled: enabled,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          hintText: hint,
          labelText: label,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              Responsive.space(context, size: Space.large),
            ),
            borderSide: BorderSide(color: Color(0xFFF7F7F7)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              Responsive.space(context, size: Space.large),
            ),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              Responsive.space(context, size: Space.large),
            ),
            borderSide: BorderSide(color: Colors.black, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              Responsive.space(context, size: Space.large),
            ),
            borderSide: BorderSide(color: Colors.red, width: 1.5),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }
}

/// A unified dropdown field component
class UnifiedDropdownField<T> extends StatelessWidget {
  final String? hint;
  final String? label;
  final T? value;
  final List<T> items;
  final String Function(T) itemToString;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;
  final bool enabled;

  const UnifiedDropdownField({
    super.key,
    this.hint,
    this.label,
    required this.value,
    required this.items,
    required this.itemToString,
    this.onChanged,
    this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.large),
        ),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        items:
            items.map((T item) {
              return DropdownMenuItem<T>(
                value: item,
                child: Text(
                  itemToString(item),
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.medium),
                  ),
                ),
              );
            }).toList(),
        onChanged: enabled ? onChanged : null,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              Responsive.space(context, size: Space.large),
            ),
            borderSide: BorderSide(color: Color(0xFFF7F7F7)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              Responsive.space(context, size: Space.large),
            ),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              Responsive.space(context, size: Space.large),
            ),
            borderSide: BorderSide(color: Colors.black, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              Responsive.space(context, size: Space.large),
            ),
            borderSide: BorderSide(color: Colors.red, width: 1.5),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        isExpanded: true,
        alignment: Alignment.centerRight,
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.large),
        ),
      ),
    );
  }
}

/// A unified section header component
class UnifiedSectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final VoidCallback? onTap;

  const UnifiedSectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Row(
            children: [
              Icon(
                icon,
                color: Colors.black,
                size: Responsive.space(context, size: Space.medium),
              ),
              SizedBox(width: Responsive.space(context, size: Space.small)),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.medium),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          Text(
            title,
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.medium),
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.right,
          ),
        ],
        SizedBox(height: Responsive.space(context, size: Space.small)),
      ],
    );
  }
}

/// A unified chip component for selections
class UnifiedChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const UnifiedChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        left: Responsive.space(context, size: Space.small),
      ),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: Responsive.text(context, size: TextSize.small),
          ),
        ),
        selected: isSelected,
        onSelected: onTap != null ? (bool selected) => onTap!() : null,
        selectedColor: Colors.black,
        backgroundColor: Colors.grey[200],
        checkmarkColor: Colors.white,
        deleteIcon: onDelete != null ? Icon(Icons.close, size: 16) : null,
        onDeleted: onDelete,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            Responsive.space(context, size: Space.large),
          ),
        ),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
