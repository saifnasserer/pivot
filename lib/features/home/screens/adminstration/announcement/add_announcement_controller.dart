import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

// Enum to map display names to full tag formats
enum DepartmentTag {
  general('اخبار عامة', 'اخبار عامة'),
  sc('SC', 'اخبار قسم SC'),
  ai('AI', 'اخبار قسم AI'),
  cs('CS', 'اخبار قسم CS'),
  informationSystems('IS', 'اخبار قسم IS'),
  generalDept('General', 'اخبار قسم General');

  const DepartmentTag(this.displayName, this.fullTag);
  final String displayName;
  final String fullTag;
}

class AddAnnouncementController {
  // Available colors for selection
  static final List<Color> availableColors = [
    const Color(0xffff5252), // Red
    const Color(0xFFFFEF86), // Yellow
    const Color(0xFF99F16C), // Green
  ];

  // Available tags (categories) for selection
  static final List<String> availableTags =
      DepartmentTag.values.map((tag) => tag.displayName).toList();

  // Department tags for easy access
  static final List<DepartmentTag> departmentTags =
      DepartmentTag.values.toList();

  // Image picker instance
  static final ImagePicker _picker = ImagePicker();

  // File picking methods
  static Future<List<XFile>> pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    return images;
  }

  static Future<FilePickerResult?> pickPdfFile() async {
    return await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
  }

  // File upload methods
  static Future<String?> uploadPdfFile(File file, String fileName) async {
    try {
      final fileSize = await file.length();

      if (fileSize > 10 * 1024 * 1024) {
        throw Exception('حجم الملف أكبر من 10 ميجابايت');
      }

      final storageRef = FirebaseStorage.instance.ref().child(
        'announcements/attachments/${DateTime.now().millisecondsSinceEpoch}_$fileName',
      );

      final uploadTask = storageRef.putFile(file);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('فشل في رفع الملف: $e');
    }
  }

  // Dialog methods
  static Future<String?> showFileTitleDialog(
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
        return AlertDialog(
          title: const Text('تعديل اسم الملف'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'اسم الملف',
              hintText: 'أدخل اسم الملف كما تريد أن يظهر',
            ),
            onChanged: (value) => tempTitle = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, tempTitle),
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  static Future<String?> showEditImageNameDialog(
    BuildContext context,
    String currentName,
  ) async {
    String tempName = currentName;
    final controller = TextEditingController(text: currentName);
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('تعديل اسم الصورة'),
          content: TextField(
            controller: controller,
            onChanged: (value) => tempName = value,
            decoration: InputDecoration(labelText: 'اسم الصورة'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, tempName),
              child: Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  static Future<Map<String, String>?> showEditLinkDialog(
    BuildContext context,
    String currentTitle,
    String currentUrl,
  ) async {
    final titleController = TextEditingController(text: currentTitle);
    final urlController = TextEditingController(text: currentUrl);
    final formKey = GlobalKey<FormState>();
    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('تعديل الرابط'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: 'العنوان'),
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'الرجاء إدخال العنوان'
                              : null,
                ),
                TextFormField(
                  controller: urlController,
                  decoration: InputDecoration(labelText: 'الرابط'),
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'الرجاء إدخال الرابط'
                              : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, {
                    'title': titleController.text,
                    'url': urlController.text,
                  });
                }
              },
              child: Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  static void showAddLinkDialog(
    BuildContext context,
    Function(Map<String, String>) onLinkAdded,
  ) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController urlController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('إضافة رابط جديد'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'العنوان'),
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'الرجاء إدخال العنوان'
                              : null,
                ),
                TextFormField(
                  controller: urlController,
                  decoration: const InputDecoration(labelText: 'الرابط'),
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'الرجاء إدخال الرابط'
                              : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  onLinkAdded({
                    'title': titleController.text,
                    'url': urlController.text,
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  // DateTime selection methods
  static Future<DateTime?> selectDateTime(
    BuildContext context,
    bool isPublishDate,
    DateTime? currentValue,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: currentValue ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(currentValue ?? DateTime.now()),
      );

      if (time != null) {
        return DateTime(
          picked.year,
          picked.month,
          picked.day,
          time.hour,
          time.minute,
        );
      }
    }
    return null;
  }
}
