import 'package:flutter/material.dart' hide MaterialType;
import 'package:pivot/responsive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pivot/services/permission_service.dart';
import 'package:pivot/services/backblaze_service.dart';
import 'package:pivot/features/home/screens/adminstration/announcement/add_announcement_controller.dart';
import 'package:pivot/models/material_link.dart';
import 'package:pivot/features/home/screens/adminstration/announcement/steps/material_browser_bottom_sheet.dart';
import 'package:pivot/widgets/unified_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class AttachmentsStep extends StatelessWidget {
  final List<XFile> pickedImages;
  final List<Map<String, String>> links;
  final Function(List<XFile>) onImagesChanged;
  final Function(List<Map<String, String>>) onLinksChanged;
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;

  const AttachmentsStep({
    super.key,
    required this.pickedImages,
    required this.links,
    required this.onImagesChanged,
    required this.onLinksChanged,
    required this.fadeAnimation,
    required this.slideAnimation,
  });

  Future<void> _pickImages(BuildContext context) async {
    final hasPermission =
        await PermissionService.requestPhotosPermissionWithRationale(context);
    if (!hasPermission) return;

    final List<XFile> images = await AddAnnouncementController.pickImages();
    if (images.isNotEmpty) {
      final newImages = List<XFile>.from(pickedImages);
      for (var img in images) {
        if (!newImages.any((i) => i.path == img.path)) {
          newImages.add(img);
        }
      }
      onImagesChanged(newImages);
    }
  }

  Future<void> _showAddLinkDialog(BuildContext context) async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController urlController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    MaterialType selectedType = MaterialType.link;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => UnifiedDialog(
                  title: 'إضافة رابط جديد',
                  subtitle: 'أضف رابطاً جديداً للمحتوى',
                  content: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        UnifiedFormField(
                          controller: titleController,
                          label: 'عنوان الرابط',
                          hint: 'أدخل عنوان الرابط',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'يرجى إدخال عنوان الرابط';
                            }
                            return null;
                          },
                        ),
                        SizedBox(
                          height: Responsive.space(context, size: Space.medium),
                        ),
                        UnifiedFormField(
                          controller: urlController,
                          label: 'الرابط',
                          hint: 'https://example.com',
                          keyboardType: TextInputType.url,
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
                        SizedBox(
                          height: Responsive.space(context, size: Space.medium),
                        ),
                        // Custom Type Selector with Icons
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'نوع المحتوى',
                              style: TextStyle(
                                fontSize: Responsive.text(
                                  context,
                                  size: TextSize.medium,
                                ),
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            SizedBox(
                              height: Responsive.space(
                                context,
                                size: Space.small,
                              ),
                            ),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: Responsive.space(
                                  context,
                                  size: Space.medium,
                                ),
                                vertical: Responsive.space(
                                  context,
                                  size: Space.small,
                                ),
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(
                                  Responsive.space(context, size: Space.large),
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<MaterialType>(
                                  value: selectedType,
                                  hint: Text(
                                    'اختر نوع المحتوى',
                                    style: TextStyle(
                                      fontSize: Responsive.text(
                                        context,
                                        size: TextSize.medium,
                                      ),
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  isExpanded: true,
                                  items:
                                      MaterialType.values.map((
                                        MaterialType type,
                                      ) {
                                        return DropdownMenuItem<MaterialType>(
                                          value: type,
                                          child: Row(
                                            children: [
                                              Icon(
                                                _getMaterialTypeIcon(type.name),
                                                color: _getMaterialTypeColor(
                                                  type.name,
                                                ),
                                                size: Responsive.space(
                                                  context,
                                                  size: Space.medium,
                                                ),
                                              ),
                                              SizedBox(
                                                width: Responsive.space(
                                                  context,
                                                  size: Space.small,
                                                ),
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
                                    if (newValue != null) {
                                      setState(() {
                                        selectedType = newValue;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: Responsive.space(context, size: Space.medium),
                        ),
                        UnifiedFormField(
                          controller: descriptionController,
                          label: 'الوصف (اختياري)',
                          hint: 'أدخل وصفاً للمادة',
                          maxLines: 3,
                          keyboardType: TextInputType.multiline,
                        ),
                      ],
                    ),
                  ),
                  confirmText: 'إضافة',
                  confirmIcon: Icons.add,
                  onConfirm: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.of(context).pop({
                        'title': titleController.text.trim(),
                        'url': urlController.text.trim(),
                        'description': descriptionController.text.trim(),
                        'type': selectedType.name,
                      });
                    }
                  },
                  onCancel: () => Navigator.of(context).pop(),
                ),
          ),
    );

    if (result != null) {
      final newLinks = List<Map<String, String>>.from(links);
      if (!newLinks.any((l) => l['url'] == result['url'])) {
        newLinks.add(result);
      }
      onLinksChanged(newLinks);
    }
  }

  Future<void> _pickPdfFile(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.bytes != null) {
        final fileName = result.files.single.name;
        final fileBytes = result.files.single.bytes!;
        final fileSize = fileBytes.length;

        // Validate file size
        if (!BackblazeService.isValidFileSize(fileSize)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('حجم الملف كبير جداً. الحد الأقصى 20 ميجابايت'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => AlertDialog(
                content: SingleChildScrollView(
                  child: Row(
                    children: [
                      const CircularProgressIndicator(),
                      SizedBox(
                        width: Responsive.space(context, size: Space.medium),
                      ),
                      const Text('جاري رفع الملف...'),
                    ],
                  ),
                ),
              ),
        );

        final backblazeService = BackblazeService();

        // Generate upload URL
        final uploadAuth = await backblazeService.generateUploadUrl(
          title: 'Announcement PDF',
          fileName: fileName,
          fileSize: fileSize,
        );

        if (uploadAuth == null) {
          Navigator.of(context).pop(); // Close loading dialog
          throw Exception('فشل في الحصول على رابط التحميل');
        }

        // Upload file to Backblaze
        final uploadSuccess = await backblazeService.uploadFile(
          uploadUrl: uploadAuth['uploadUrl'],
          authorizationToken: uploadAuth['authorizationToken'],
          fileName: uploadAuth['filePath'],
          contentType: BackblazeService.getContentType(fileName),
          fileBytes: fileBytes,
        );

        if (!uploadSuccess) {
          Navigator.of(context).pop(); // Close loading dialog
          throw Exception('فشل في رفع الملف');
        }

        // Confirm upload and get download URL
        final confirmResult = await backblazeService.confirmUpload(
          title: 'Announcement PDF',
          description: 'PDF attachment for announcement',
          filePath: uploadAuth['filePath'],
          fileName: uploadAuth['fileName'],
          fileSize: fileSize,
          contentType: BackblazeService.getContentType(fileName),
        );

        Navigator.of(context).pop(); // Close loading dialog

        if (confirmResult == null || confirmResult['downloadUrl'] == null) {
          throw Exception('فشل في حفظ بيانات الملف');
        }

        final downloadUrl = confirmResult['downloadUrl'];

        // Get custom title for the file
        String? linkTitle = await _showFileTitleDialog(context, fileName);

        final newLinks = List<Map<String, String>>.from(links);
        if (!newLinks.any((l) => l['url'] == downloadUrl)) {
          newLinks.add({
            'title': linkTitle ?? fileName,
            'url': downloadUrl,
            'type': 'pdf',
          });
        }
        onLinksChanged(newLinks);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم رفع الملف بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop(); // Close loading dialog
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل في رفع الملف: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _showFileTitleDialog(
    BuildContext context,
    String fileName,
  ) async {
    String tempTitle = fileName;
    final TextEditingController controller = TextEditingController(
      text: fileName,
    );

    return showDialog<String>(
      context: context,
      builder: (context) {
        return UnifiedDialog(
          title: 'تعديل اسم الملف',
          content: UnifiedFormField(
            controller: controller,
            label: 'اسم الملف',
            hint: 'أدخل اسم الملف كما تريد أن يظهر',
            onChanged: (value) => tempTitle = value,
          ),
          confirmText: 'حفظ',
          confirmIcon: Icons.save,
          onCancel: () => Navigator.pop(context),
          onConfirm: () => Navigator.pop(context, tempTitle),
        );
      },
    );
  }

  Future<void> _showMaterialBrowser(BuildContext context) async {
    final MaterialLink? materialLink = await showModalBottomSheet<MaterialLink>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const MaterialBrowserBottomSheet(),
    );

    if (materialLink != null) {
      final newLinks = List<Map<String, String>>.from(links);
      if (!newLinks.any((l) => l['url'] == materialLink.url)) {
        newLinks.add({
          'title': materialLink.title,
          'url': materialLink.url,
          'description': materialLink.description ?? '',
          'type': materialLink.type.name,
        });
      }
      onLinksChanged(newLinks);
    }
  }

  Widget _buildAttachmentButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: Responsive.padding(context, size: Space.large),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(
            Responsive.space(context, size: Space.large),
          ),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: Responsive.space(context, size: Space.large) * 1.5,
            ),
            SizedBox(height: Responsive.space(context, size: Space.small)),
            Text(
              label,
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.medium),
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getMaterialTypeIcon(String type) {
    switch (type) {
      case 'video':
        return Icons.play_circle_outline;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'document':
        return Icons.description;
      case 'image':
        return Icons.image;
      case 'link':
      default:
        return Icons.link;
    }
  }

  Color _getMaterialTypeColor(String type) {
    switch (type) {
      case 'video':
        return Colors.red;
      case 'pdf':
        return Colors.orange;
      case 'document':
        return Colors.blue;
      case 'image':
        return Colors.green;
      case 'link':
      default:
        return Colors.grey;
    }
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: fadeAnimation,
          child: AnimatedBuilder(
            animation: slideAnimation,
            builder: (context, child) {
              return SlideTransition(
                position: slideAnimation,
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Container(
                        padding: Responsive.padding(context, size: Space.large),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            Responsive.space(context, size: Space.large),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'المرفقات',
                                    style: TextStyle(
                                      fontSize:
                                          Responsive.text(
                                            context,
                                            size: TextSize.heading,
                                          ) *
                                          1.2,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[700],
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                  Text(
                                    'أضف الصور والروابط واختر من المواد الموجودة (اختياري)',
                                    style: TextStyle(
                                      fontSize: Responsive.text(
                                        context,
                                        size: TextSize.medium,
                                      ),
                                      color: Colors.green[600],
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: Responsive.space(
                                context,
                                size: Space.medium,
                              ),
                            ),
                            Icon(
                              Icons.attach_file,
                              color: Colors.green[700],
                              size:
                                  Responsive.space(context, size: Space.large) *
                                  1.5,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.large),
                      ),

                      // Attachment buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: _buildAttachmentButton(
                              context,
                              icon: Icons.image,
                              label: 'صورة',
                              color: Colors.green,
                              onTap: () => _pickImages(context),
                            ),
                          ),
                          SizedBox(
                            width: Responsive.space(
                              context,
                              size: Space.medium,
                            ),
                          ),
                          Expanded(
                            child: _buildAttachmentButton(
                              context,
                              icon: Icons.picture_as_pdf,
                              label: 'ملف PDF',
                              color: Colors.red,
                              onTap: () => _pickPdfFile(context),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.medium),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: _buildAttachmentButton(
                              context,
                              icon: Icons.add_link,
                              label: 'رابط',
                              color: Colors.orange,
                              onTap: () => _showAddLinkDialog(context),
                            ),
                          ),
                          SizedBox(
                            width: Responsive.space(
                              context,
                              size: Space.medium,
                            ),
                          ),
                          Expanded(
                            child: _buildAttachmentButton(
                              context,
                              icon: Icons.search,
                              label: 'من الماتيريال',
                              color: Colors.blue,
                              onTap: () => _showMaterialBrowser(context),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.large),
                      ),

                      // Display selected attachments
                      if (pickedImages.isNotEmpty || links.isNotEmpty)
                        Container(
                          padding: Responsive.padding(
                            context,
                            size: Space.medium,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(
                              Responsive.space(context, size: Space.large),
                            ),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'المرفقات المحددة:',
                                style: TextStyle(
                                  fontSize: Responsive.text(
                                    context,
                                    size: TextSize.medium,
                                  ),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                                textAlign: TextAlign.right,
                              ),
                              SizedBox(
                                height: Responsive.space(
                                  context,
                                  size: Space.medium,
                                ),
                              ),

                              // Images
                              if (pickedImages.isNotEmpty) ...[
                                Text(
                                  'الصور (${pickedImages.length})',
                                  style: TextStyle(
                                    fontSize: Responsive.text(
                                      context,
                                      size: TextSize.medium,
                                    ),
                                    color: Colors.green[600],
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                                SizedBox(
                                  height: Responsive.space(
                                    context,
                                    size: Space.small,
                                  ),
                                ),
                                ...pickedImages.asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  final img = entry.value;
                                  return ListTile(
                                    leading: Image.file(
                                      File(img.path),
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                    ),
                                    title: Text(img.name),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.edit,
                                            color: Colors.blue,
                                          ),
                                          onPressed: () async {
                                            final newName =
                                                await AddAnnouncementController.showEditImageNameDialog(
                                                  context,
                                                  img.name,
                                                );
                                            if (newName != null &&
                                                newName.isNotEmpty) {
                                              final newImages =
                                                  List<XFile>.from(
                                                    pickedImages,
                                                  );
                                              newImages[idx] = XFile(
                                                img.path,
                                                name: newName,
                                              );
                                              onImagesChanged(newImages);
                                            }
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed: () {
                                            final newImages = List<XFile>.from(
                                              pickedImages,
                                            );
                                            newImages.removeAt(idx);
                                            onImagesChanged(newImages);
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                              // Links
                              if (links.isNotEmpty) ...[
                                Text(
                                  'الروابط (${links.length})',
                                  style: TextStyle(
                                    fontSize: Responsive.text(
                                      context,
                                      size: TextSize.medium,
                                    ),
                                    color: Colors.blue[600],
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                                SizedBox(
                                  height: Responsive.space(
                                    context,
                                    size: Space.small,
                                  ),
                                ),
                                ...links.asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  final link = entry.value;
                                  final materialType = link['type'] ?? 'link';
                                  final description = link['description'] ?? '';

                                  return Directionality(
                                    textDirection: TextDirection.rtl,
                                    child: ListTile(
                                      leading: Icon(
                                        _getMaterialTypeIcon(materialType),
                                        color: _getMaterialTypeColor(
                                          materialType,
                                        ),
                                      ),
                                      title: Text(link['title'] ?? ''),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(link['url'] ?? ''),
                                          if (description.isNotEmpty)
                                            Text(
                                              description,
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
                                      trailing: IconButton(
                                        icon: Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () {
                                          final newLinks =
                                              List<Map<String, String>>.from(
                                                links,
                                              );
                                          newLinks.removeAt(idx);
                                          onLinksChanged(newLinks);
                                        },
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
