import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/widgets/unified_dialog.dart';
import 'package:pivot/services/file_upload_service.dart';

/// Dialog for uploading files as materials
class AddMaterialFileDialog extends StatefulWidget {
  const AddMaterialFileDialog({super.key});

  @override
  State<AddMaterialFileDialog> createState() => _AddMaterialFileDialogState();
}

class _AddMaterialFileDialogState extends State<AddMaterialFileDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FileUploadService _uploadService = FileUploadService();

  PickedFileInfo? _selectedFile;
  bool _isUploading = false;
  UploadProgress? _uploadProgress;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final file = await _uploadService.pickFile();
      if (file != null) {
        setState(() {
          _selectedFile = file;
          // Auto-fill title with file name (without extension)
          if (_titleController.text.isEmpty) {
            _titleController.text = file.name.split('.').first;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadFile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء اختيار ملف'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    // Will be set by parent widget when calling the dialog
    // For now, return the data and let parent handle the upload
    Navigator.of(context).pop({
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'file': _selectedFile,
    });
  }

  @override
  Widget build(BuildContext context) {
    return UnifiedDialog(
      title: 'رفع ملف جديد',
      subtitle: 'قم برفع ملف PDF أو مستند أو صورة',
      isLoading: _isUploading,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // File picker button
            _buildFilePicker(),
            
            if (_selectedFile != null) ...[
              SizedBox(height: Responsive.space(context, size: Space.medium)),
              _buildFileInfo(),
            ],
            
            SizedBox(height: Responsive.space(context, size: Space.medium)),
            
            // Title field
            UnifiedFormField(
              controller: _titleController,
              label: 'العنوان',
              hint: 'أدخل عنوان المحتوى',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'يرجى إدخال العنوان';
                }
                return null;
              },
            ),
            
            SizedBox(height: Responsive.space(context, size: Space.medium)),
            
            // Description field
            UnifiedFormField(
              controller: _descriptionController,
              label: 'الوصف (اختياري)',
              hint: 'أدخل وصفاً للمادة',
              maxLines: 3,
              keyboardType: TextInputType.multiline,
            ),
            
            if (_uploadProgress != null) ...[
              SizedBox(height: Responsive.space(context, size: Space.medium)),
              _buildUploadProgress(),
            ],
          ],
        ),
      ),
      confirmText: 'رفع',
      confirmIcon: Icons.upload_file,
      onConfirm: _isUploading ? null : _uploadFile,
      onCancel: _isUploading ? null : () => Navigator.of(context).pop(null),
    );
  }

  Widget _buildFilePicker() {
    return GestureDetector(
      onTap: _isUploading ? null : _pickFile,
      child: Container(
        padding: EdgeInsets.all(Responsive.space(context, size: Space.large)),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(
            Responsive.space(context, size: Space.large),
          ),
          border: Border.all(
            color: _selectedFile != null ? Colors.green : Colors.grey.shade300,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Icon(
              _selectedFile != null
                  ? Icons.check_circle
                  : Icons.cloud_upload_outlined,
              size: 48,
              color: _selectedFile != null ? Colors.green : Colors.grey.shade400,
            ),
            SizedBox(height: Responsive.space(context, size: Space.small)),
            Text(
              _selectedFile != null ? 'تم اختيار الملف' : 'اضغط لاختيار ملف',
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.medium),
                fontWeight: FontWeight.w600,
                color: _selectedFile != null
                    ? Colors.green
                    : Colors.grey.shade600,
              ),
            ),
            SizedBox(height: Responsive.space(context, size: Space.tiny)),
            Text(
              'PDF, DOCX, PPTX, JPG, PNG (حتى 20 ميجابايت)',
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.small),
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileInfo() {
    if (_selectedFile == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(Responsive.space(context, size: Space.medium)),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.medium),
        ),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(
            _getFileIcon(_selectedFile!.extension),
            size: 32,
            color: Colors.blue.shade700,
          ),
          SizedBox(width: Responsive.space(context, size: Space.medium)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedFile!.name,
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.medium),
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  _selectedFile!.formattedSize,
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.small),
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.red.shade400),
            onPressed: _isUploading
                ? null
                : () {
                    setState(() {
                      _selectedFile = null;
                    });
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildUploadProgress() {
    if (_uploadProgress == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LinearProgressIndicator(
          value: _uploadProgress!.progress,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(
            _uploadProgress!.stage == UploadStage.error
                ? Colors.red
                : Colors.blue,
          ),
        ),
        SizedBox(height: Responsive.space(context, size: Space.small)),
        Text(
          _uploadProgress!.message,
          style: TextStyle(
            fontSize: Responsive.text(context, size: TextSize.small),
            color: _uploadProgress!.stage == UploadStage.error
                ? Colors.red
                : Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'docx':
      case 'doc':
        return Icons.description;
      case 'pptx':
      case 'ppt':
        return Icons.slideshow;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }
}

