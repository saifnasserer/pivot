import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/services/file_upload_service.dart';
import 'package:pivot/services/permission_service.dart';
import 'package:pivot/widgets/unified_dialog.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class FileUploadFeature {
  final FileUploadService _fileUploadService = FileUploadService();
  final ImagePicker _imagePicker = ImagePicker();

  /// Direct image upload without bottom sheet
  Future<void> pickAndUploadImageDirect(
    BuildContext context, {
    required Function(Map<String, String>) onImageUploaded,
  }) async {
    await pickAndUploadImage(context, onImageUploaded: onImageUploaded);
  }

  /// Direct file upload without bottom sheet
  Future<void> pickAndUploadFileDirect(
    BuildContext context, {
    required Function(Map<String, String>) onFileUploaded,
    String? subjectId,
    String? assistantId,
  }) async {
    await pickAndUploadFile(
      context,
      onFileUploaded: onFileUploaded,
      subjectId: subjectId,
      assistantId: assistantId,
    );
  }

  /// Direct link addition without bottom sheet
  Future<void> showAddLinkDialogDirect(
    BuildContext context, {
    required Function(Map<String, String>) onLinkAdded,
  }) async {
    await showAddLinkDialog(context, onLinkAdded: onLinkAdded);
  }

  /// Show file upload options dialog
  Future<void> showFileUploadDialog(
    BuildContext context, {
    required Function(Map<String, String>) onImageUploaded,
    required Function(Map<String, String>) onFileUploaded,
    required Function(Map<String, String>) onLinkAdded,
    required VoidCallback onAddMaterials,
    String? subjectId,
    String? assistantId,
  }) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Responsive.space(context, size: Space.large)),
        ),
      ),
      builder:
          (context) => Container(
            padding: Responsive.padding(context, size: Space.large),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.only(
                    bottom: Responsive.space(context, size: Space.medium),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'إضافة مرفق',
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.heading),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: Responsive.space(context, size: Space.large)),

                // Materials option
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Use post frame callback to ensure context is valid
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        onAddMaterials();
                      });
                    },
                    icon: Icon(Icons.library_books),
                    label: Text('من الماتيريال الموجودة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          Responsive.space(context, size: Space.large),
                        ),
                      ),
                      side: BorderSide(color: Colors.black, width: 1),
                    ),
                  ),
                ),
                SizedBox(height: Responsive.space(context, size: Space.large)),

                // New attachments row - circular outlined icons only
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Image button
                    Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.green[600]!,
                              width: 2,
                            ),
                          ),
                          child: IconButton(
                            onPressed: () {
                              print(
                                '🔄 [FileUploadFeature] Image button pressed',
                              );
                              // Store context before popping
                              final parentContext = context;
                              Navigator.pop(context);
                              // Use post frame callback to ensure context is valid
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                print(
                                  '🔄 [FileUploadFeature] Post frame callback executing...',
                                );
                                pickAndUploadImage(
                                  parentContext,
                                  onImageUploaded: onImageUploaded,
                                );
                              });
                            },
                            icon: Icon(
                              Icons.image,
                              color: Colors.green[600],
                              size: 24,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: Responsive.space(context, size: Space.tiny),
                        ),
                        Text(
                          'صورة',
                          style: TextStyle(
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.small,
                            ),
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    // File button
                    Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.green[600]!,
                              width: 2,
                            ),
                          ),
                          child: IconButton(
                            onPressed: () {
                              // Store context before popping
                              final parentContext = context;
                              Navigator.pop(context);
                              // Use post frame callback to ensure context is valid
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                pickAndUploadFile(
                                  parentContext,
                                  onFileUploaded: onFileUploaded,
                                  subjectId: subjectId,
                                  assistantId: assistantId,
                                );
                              });
                            },
                            icon: Icon(
                              Icons.upload_file,
                              color: Colors.green[600],
                              size: 24,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: Responsive.space(context, size: Space.tiny),
                        ),
                        Text(
                          'ملف',
                          style: TextStyle(
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.small,
                            ),
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    // Link button
                    Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.green[600]!,
                              width: 2,
                            ),
                          ),
                          child: IconButton(
                            onPressed: () {
                              // Store context before popping
                              final parentContext = context;
                              Navigator.pop(context);
                              // Use post frame callback to ensure context is valid
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                showAddLinkDialog(
                                  parentContext,
                                  onLinkAdded: onLinkAdded,
                                );
                              });
                            },
                            icon: Icon(
                              Icons.link,
                              color: Colors.green[600],
                              size: 24,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: Responsive.space(context, size: Space.tiny),
                        ),
                        Text(
                          'رابط',
                          style: TextStyle(
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.small,
                            ),
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: Responsive.space(context, size: Space.medium)),
              ],
            ),
          ),
    );
  }

  /// Pick and upload image with permission handling
  Future<void> pickAndUploadImage(
    BuildContext context, {
    required Function(Map<String, String>) onImageUploaded,
  }) async {
    try {
      print('🔄 [FileUploadFeature] pickAndUploadImage called');

      // Request photos permission first
      print('🔄 [FileUploadFeature] Requesting photos permission...');
      final hasPermission =
          await PermissionService.requestPhotosPermissionWithRationale(context);
      if (!hasPermission) {
        print('❌ [FileUploadFeature] Permission denied');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('يجب منح صلاحية الوصول للصور لاختيار الصور'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      print('✅ [FileUploadFeature] Permission granted, picking image...');
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) {
        print('❌ [FileUploadFeature] No image selected');
        return;
      }

      print('✅ [FileUploadFeature] Image selected: ${image.path}');

      // Add to preview immediately (like announcements)
      final imageData = {
        'title': 'صورة مرفقة',
        'url': image.path, // Use local path for preview
        'type': 'image',
        'isLocal': 'true', // Mark as local for preview
      };

      // Add to preview immediately
      onImageUploaded(imageData);

      print('✅ [FileUploadFeature] Image added to preview');
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog if open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في رفع الصورة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Pick and upload file
  Future<void> pickAndUploadFile(
    BuildContext context, {
    required Function(Map<String, String>) onFileUploaded,
    String? subjectId,
    String? assistantId,
  }) async {
    try {
      final result = await _fileUploadService.pickFile();
      if (result == null) return;

      // Add to preview immediately (like announcements)
      final fileData = <String, String>{
        'title': result.name,
        'url': result.name, // Use filename for preview
        'type': 'file',
        'isLocal': 'true', // Mark as local for preview
      };

      // Store file info separately for later upload
      // We'll handle the fileInfo in the task save method

      // Add to preview immediately
      onFileUploaded(fileData);

      print('✅ [FileUploadFeature] File added to preview');
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog if open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في رفع الملف: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Show add link dialog
  Future<void> showAddLinkDialog(
    BuildContext context, {
    required Function(Map<String, String>) onLinkAdded,
  }) async {
    print('🔗 [FileUploadFeature] showAddLinkDialog called');
    final titleController = TextEditingController();
    final urlController = TextEditingController();

    // Store the original context before showing dialog
    final originalContext = context;

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => UnifiedDialog(
            title: 'إضافة رابط',
            subtitle: 'أدخل عنوان الرابط والرابط المطلوب',
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                UnifiedFormField(
                  controller: titleController,
                  label: 'عنوان الرابط',
                  hint: 'مثال: دليل الطالب',
                ),
                SizedBox(height: Responsive.space(context, size: Space.medium)),
                UnifiedFormField(
                  controller: urlController,
                  label: 'الرابط',
                  hint: 'https://example.com',
                  keyboardType: TextInputType.url,
                ),
              ],
            ),
            onCancel: () => Navigator.pop(context, false),
            onConfirm: () {
              print('🔗 [FileUploadFeature] Confirm button pressed');
              print(
                '🔗 [FileUploadFeature] Title: "${titleController.text.trim()}"',
              );
              print(
                '🔗 [FileUploadFeature] URL: "${urlController.text.trim()}"',
              );

              if (titleController.text.trim().isNotEmpty &&
                  urlController.text.trim().isNotEmpty) {
                print(
                  '🔗 [FileUploadFeature] Validation passed, closing dialog',
                );
                Navigator.pop(context, true);
              } else {
                print(
                  '🔗 [FileUploadFeature] Validation failed - missing fields',
                );
                // Show error message
                ScaffoldMessenger.of(originalContext).showSnackBar(
                  SnackBar(
                    content: Text('يرجى ملء جميع الحقول'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            cancelText: 'إلغاء',
            confirmText: 'إضافة',
            confirmIcon: Icons.add,
          ),
    );

    print('🔗 [FileUploadFeature] Dialog result: $result');
    print('🔗 [FileUploadFeature] Context mounted: ${originalContext.mounted}');
    if (result == true && originalContext.mounted) {
      final linkData = {
        'title': titleController.text.trim(),
        'url': urlController.text.trim(),
        'type': 'link',
      };
      print('🔗 [FileUploadFeature] Link data created: $linkData');

      // Use post frame callback to ensure context is valid
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print('🔗 [FileUploadFeature] Calling onLinkAdded with: $linkData');
        onLinkAdded(linkData);
      });

      ScaffoldMessenger.of(originalContext).showSnackBar(
        SnackBar(
          content: Text('تم إضافة الرابط بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      print(
        '🔗 [FileUploadFeature] Dialog not completed or context not mounted',
      );
    }
  }
}
