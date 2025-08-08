import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pivot/services/permission_service.dart';
import 'package:pivot/screens/section2/adminstration/announcement/add_announcement_controller.dart';
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

  Future<void> _pickPdfFile(BuildContext context) async {
    try {
      FilePickerResult? result = await AddAnnouncementController.pickPdfFile();

      if (result != null && result.files.single.path != null) {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => AlertDialog(
                content: Row(
                  children: [
                    const CircularProgressIndicator(),
                    SizedBox(
                      width: Responsive.space(context, size: Space.medium),
                    ),
                    const Text('جاري رفع الملف...'),
                  ],
                ),
              ),
        );

        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;

        final downloadUrl = await AddAnnouncementController.uploadPdfFile(
          file,
          fileName,
        );

        Navigator.of(context).pop(); // Close loading dialog

        // Get custom title for the file
        String? linkTitle = await AddAnnouncementController.showFileTitleDialog(
          context,
          fileName,
        );

        final newLinks = List<Map<String, String>>.from(links);
        if (!newLinks.any((l) => l['url'] == downloadUrl)) {
          newLinks.add({'title': linkTitle ?? fileName, 'url': downloadUrl!});
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

  void _showAddLinkDialog(BuildContext context) {
    AddAnnouncementController.showAddLinkDialog(context, (newLink) {
      final newLinks = List<Map<String, String>>.from(links);
      if (!newLinks.any((l) => l['url'] == newLink['url'])) {
        newLinks.add(newLink);
      }
      onLinksChanged(newLinks);
    });
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
                child: Container(
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
                                    'أضف الصور والملفات والروابط (اختياري)',
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
                          _buildAttachmentButton(
                            context,
                            icon: Icons.image,
                            label: 'صورة',
                            color: Colors.green,
                            onTap: () => _pickImages(context),
                          ),
                          _buildAttachmentButton(
                            context,
                            icon: Icons.picture_as_pdf,
                            label: 'ملف PDF',
                            color: Colors.orange,
                            onTap: () => _pickPdfFile(context),
                          ),
                          _buildAttachmentButton(
                            context,
                            icon: Icons.add_link,
                            label: 'رابط',
                            color: Colors.blue,
                            onTap: () => _showAddLinkDialog(context),
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
                                    title: Text(img.name ?? 'صورة'),
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
                                                  img.name ?? 'صورة',
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
                                  return ListTile(
                                    leading: Icon(
                                      Icons.link,
                                      color: Colors.blue,
                                    ),
                                    title: Text(link['title'] ?? ''),
                                    subtitle: Text(link['url'] ?? ''),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.edit,
                                            color: Colors.blue,
                                          ),
                                          onPressed: () async {
                                            final result =
                                                await AddAnnouncementController.showEditLinkDialog(
                                                  context,
                                                  link['title'] ?? '',
                                                  link['url'] ?? '',
                                                );
                                            if (result != null) {
                                              final newLinks = List<
                                                Map<String, String>
                                              >.from(links);
                                              newLinks[idx] = result;
                                              onLinksChanged(newLinks);
                                            }
                                          },
                                        ),
                                        IconButton(
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
                                      ],
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
