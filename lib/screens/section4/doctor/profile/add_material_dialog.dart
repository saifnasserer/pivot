import 'package:flutter/material.dart' hide MaterialType;
import 'package:pivot/models/material_link.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/widgets/unified_dialog.dart';

class AddMaterialDialog extends StatefulWidget {
  const AddMaterialDialog({super.key});

  @override
  State<AddMaterialDialog> createState() => _AddMaterialDialogState();
}

class _AddMaterialDialogState extends State<AddMaterialDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  MaterialType? _detectedType;
  bool _isValidating = false;

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  MaterialType _detectType(String url) {
    final lowerUrl = url.toLowerCase();

    // Video platforms
    if (lowerUrl.contains('youtube.com') ||
        lowerUrl.contains('youtu.be') ||
        lowerUrl.contains('vimeo.com') ||
        lowerUrl.contains('dailymotion.com')) {
      return MaterialType.video;
    }

    // Document platforms
    if (lowerUrl.contains('drive.google.com') && lowerUrl.contains('/file/')) {
      return MaterialType.document;
    }
    if (lowerUrl.contains('docs.google.com')) {
      return MaterialType.document;
    }
    if (lowerUrl.contains('onedrive.live.com')) {
      return MaterialType.document;
    }

    // File extensions
    if (lowerUrl.endsWith('.pdf')) {
      return MaterialType.pdf;
    }
    if (lowerUrl.endsWith('.jpg') ||
        lowerUrl.endsWith('.jpeg') ||
        lowerUrl.endsWith('.png') ||
        lowerUrl.endsWith('.gif') ||
        lowerUrl.endsWith('.webp')) {
      return MaterialType.image;
    }
    if (lowerUrl.endsWith('.doc') ||
        lowerUrl.endsWith('.docx') ||
        lowerUrl.endsWith('.ppt') ||
        lowerUrl.endsWith('.pptx') ||
        lowerUrl.endsWith('.xls') ||
        lowerUrl.endsWith('.xlsx')) {
      return MaterialType.document;
    }

    return MaterialType.link;
  }

  void _detectTypeFromUrl(String url) {
    if (url.isEmpty) {
      setState(() => _detectedType = null);
      return;
    }

    setState(() {
      _detectedType = _detectType(url);
    });
  }

  Future<void> _validateUrl() async {
    if (_urlController.text.isEmpty) return;

    setState(() => _isValidating = true);

    try {
      final uri = Uri.tryParse(_urlController.text);
      if (uri == null || !uri.hasScheme) {
        throw Exception('رابط غير صالح');
      }

      // For now, we'll just validate the URL format
      // In the future, we could add actual URL validation
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في الرابط: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isValidating = false);
      }
    }
  }

  MaterialLink? _createMaterialLink() {
    if (!_formKey.currentState!.validate()) return null;

    return MaterialLink(
      title: _titleController.text.trim(),
      url: _urlController.text.trim(),
      description:
          _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
      type: _detectedType ?? MaterialType.link,
    );
  }

  String _getTypeDisplayName(MaterialType type) {
    switch (type) {
      case MaterialType.video:
        return 'Video';
      case MaterialType.pdf:
        return 'PDF Document';
      case MaterialType.document:
        return 'Document';
      case MaterialType.image:
        return 'Image';
      case MaterialType.link:
        return 'Link';
    }
  }

  IconData _getTypeIcon(MaterialType type) {
    switch (type) {
      case MaterialType.video:
        return Icons.play_circle_outline;
      case MaterialType.pdf:
        return Icons.picture_as_pdf;
      case MaterialType.document:
        return Icons.description;
      case MaterialType.image:
        return Icons.image;
      case MaterialType.link:
        return Icons.link;
    }
  }

  @override
  Widget build(BuildContext context) {
    return UnifiedDialog(
      title: 'إضافة محتوى جديد',
      subtitle: 'أضف رابط جديد للمحتوى',
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTitleField(),
            SizedBox(height: Responsive.space(context, size: Space.medium)),
            _buildUrlField(),
            if (_detectedType != null) ...[
              SizedBox(height: Responsive.space(context, size: Space.small)),
              _buildTypeIndicator(),
            ],
            SizedBox(height: Responsive.space(context, size: Space.medium)),
            _buildDescriptionField(),
          ],
        ),
      ),
      confirmText: 'إضافة',
      confirmIcon: Icons.add,
      onConfirm: () {
        final materialLink = _createMaterialLink();
        if (materialLink != null) {
          Navigator.of(context).pop(materialLink);
        }
      },
      onCancel: () => Navigator.of(context).pop(null),
    );
  }

  Widget _buildTitleField() {
    return UnifiedFormField(
      controller: _titleController,
      label: 'العنوان',
      hint: 'أدخل عنوان المحتوى',
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'يرجى إدخال العنوان';
        }
        return null;
      },
    );
  }

  Widget _buildUrlField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UnifiedFormField(
          controller: _urlController,
          label: 'الرابط',
          hint: 'https://example.com',
          keyboardType: TextInputType.url,
          onChanged: _detectTypeFromUrl,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'يرجى إدخال الرابط';
            }

            final uri = Uri.tryParse(value.trim());
            if (uri == null || !uri.hasScheme) {
              return 'يرجى إدخال رابط صالح';
            }

            return null;
          },
        ),
        if (_isValidating) ...[
          SizedBox(height: Responsive.space(context, size: Space.small)),
          Row(
            children: [
              SizedBox(
                width: Responsive.space(context, size: Space.small),
                height: Responsive.space(context, size: Space.small),
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: Responsive.space(context, size: Space.small)),
              Text(
                'جاري التحقق من الرابط...',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.small),
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTypeIndicator() {
    return Container(
      padding: EdgeInsets.all(Responsive.space(context, size: Space.small)),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.small),
        ),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(
            _getTypeIcon(_detectedType!),
            color: Colors.grey.shade600,
            size: Responsive.space(context, size: Space.medium),
          ),
          SizedBox(width: Responsive.space(context, size: Space.small)),
          Text(
            'نوع المحتوى: ${_getTypeDisplayName(_detectedType!)}',
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.small),
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionField() {
    return UnifiedFormField(
      controller: _descriptionController,
      label: 'الوصف (اختياري)',
      hint: 'أدخل وصفاً للمادة',
      maxLines: 3,
      keyboardType: TextInputType.multiline,
    );
  }
}
