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
  MaterialType? _selectedType;
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

    // File extensions (check these first before platform detection)
    if (lowerUrl.endsWith('.pdf')) {
      return MaterialType.pdf;
    }
    if (lowerUrl.endsWith('.jpg') ||
        lowerUrl.endsWith('.jpeg') ||
        lowerUrl.endsWith('.png') ||
        lowerUrl.endsWith('.gif') ||
        lowerUrl.endsWith('.webp') ||
        lowerUrl.endsWith('.bmp') ||
        lowerUrl.endsWith('.svg')) {
      return MaterialType.image;
    }
    if (lowerUrl.endsWith('.mp4') ||
        lowerUrl.endsWith('.avi') ||
        lowerUrl.endsWith('.mov') ||
        lowerUrl.endsWith('.wmv') ||
        lowerUrl.endsWith('.flv') ||
        lowerUrl.endsWith('.webm') ||
        lowerUrl.endsWith('.mkv') ||
        lowerUrl.endsWith('.m4v')) {
      return MaterialType.video;
    }
    if (lowerUrl.endsWith('.doc') ||
        lowerUrl.endsWith('.docx') ||
        lowerUrl.endsWith('.ppt') ||
        lowerUrl.endsWith('.pptx') ||
        lowerUrl.endsWith('.xls') ||
        lowerUrl.endsWith('.xlsx') ||
        lowerUrl.endsWith('.txt') ||
        lowerUrl.endsWith('.rtf')) {
      return MaterialType.document;
    }

    // Google Docs specific services (these are definitely documents)
    if (lowerUrl.contains('docs.google.com/document') ||
        lowerUrl.contains('docs.google.com/spreadsheets') ||
        lowerUrl.contains('docs.google.com/presentation')) {
      return MaterialType.document;
    }

    // Google Drive files - default to link since we can't determine type
    if (lowerUrl.contains('drive.google.com') && lowerUrl.contains('/file/')) {
      return MaterialType.link;
    }

    // OneDrive and other cloud storage - default to link
    if (lowerUrl.contains('onedrive.live.com') ||
        lowerUrl.contains('1drv.ms') ||
        lowerUrl.contains('sharepoint.com') ||
        lowerUrl.contains('dropbox.com')) {
      return MaterialType.link;
    }

    return MaterialType.link;
  }

  void _detectTypeFromUrl(String url) {
    if (url.isEmpty) {
      setState(() {
        _detectedType = null;
        // Reset selected type if URL is empty
        if (_selectedType != null) {
          _selectedType = null;
        }
      });
      return;
    }

    setState(() {
      _detectedType = _detectType(url);
      // Auto-select the detected type if no manual selection was made
      if (_selectedType == null) {
        _selectedType = _detectedType;
      }
    });
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
      type: _selectedType ?? _detectedType ?? MaterialType.link,
    );
  }

  String _getTypeDisplayName(MaterialType type) {
    switch (type) {
      case MaterialType.video:
        return 'فيديو';
      case MaterialType.pdf:
        return 'ملف PDF';
      case MaterialType.document:
        return 'مستند';
      case MaterialType.image:
        return 'صورة';
      case MaterialType.link:
        return 'رابط';
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
            SizedBox(height: Responsive.space(context, size: Space.medium)),
            _buildTypeSelector(),
            if (_detectedType != null && _detectedType != _selectedType) ...[
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

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'نوع المحتوى',
          style: TextStyle(
            fontSize: Responsive.text(context, size: TextSize.medium),
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        SizedBox(height: Responsive.space(context, size: Space.small)),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.space(context, size: Space.medium),
            vertical: Responsive.space(context, size: Space.small),
          ),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(
              Responsive.space(context, size: Space.small),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<MaterialType>(
              value: _selectedType,
              hint: Text(
                'اختر نوع المحتوى',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.medium),
                  color: Colors.grey.shade600,
                ),
              ),
              isExpanded: true,
              items:
                  MaterialType.values.map((MaterialType type) {
                    return DropdownMenuItem<MaterialType>(
                      value: type,
                      child: Row(
                        children: [
                          Icon(
                            _getTypeIcon(type),
                            color: Colors.grey.shade600,
                            size: Responsive.space(context, size: Space.medium),
                          ),
                          SizedBox(
                            width: Responsive.space(context, size: Space.small),
                          ),
                          Text(
                            _getTypeDisplayName(type),
                            style: TextStyle(
                              fontSize: Responsive.text(
                                context,
                                size: TextSize.medium,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
              onChanged: (MaterialType? newValue) {
                setState(() {
                  _selectedType = newValue;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeIndicator() {
    return Container(
      padding: EdgeInsets.all(Responsive.space(context, size: Space.small)),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.small),
        ),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: Colors.blue.shade600,
            size: Responsive.space(context, size: Space.medium),
          ),
          SizedBox(width: Responsive.space(context, size: Space.small)),
          Expanded(
            child: Text(
              'تم اكتشاف نوع المحتوى تلقائياً: ${_getTypeDisplayName(_detectedType!)}',
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.small),
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w500,
              ),
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
