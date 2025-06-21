import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:pivot/screens/section2/adminstration/models/announcement_data.dart';
import 'package:provider/provider.dart';
import '../../models/custom_text_field.dart';
import 'package:pivot/providers/announcement_provider.dart';
// import 'package:permission_handler/permission_handler.dart';
import 'package:pivot/services/permission_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

// Available colors for selection
final List<Color> availableColors = [
  const Color(0xffff5252), // Red
  const Color(0xFFFFEF86), // Yellow
  const Color(0xFF99F16C), // Green
];

// Available tags (categories) for selection
final List<String> availableTags = [
  'اخبار قسم SC',
  'اخبار قسم AI',
  'اخبار قسم CS',
  'اخبار قسم IS',
];

// Show dialog to add or edit an announcement
void showAddAnnouncementDialog({
  required BuildContext context,
  required Function(AnnouncementData) onSave,
  bool isEditing = false,
  AnnouncementData? announcement,
}) {
  // Use String state variables
  String title = announcement?.title ?? '';
  String description = announcement?.description ?? '';

  // Selected color and tags
  Color selectedColor = announcement?.color ?? availableColors[0];
  List<String> selectedTags = List<String>.from(announcement?.tags ?? []);

  // State for images and links
  List<XFile> pickedImages = [];
  List<Map<String, String>> links = List<Map<String, String>>.from(
    announcement?.links ?? [],
  );
  final ImagePicker picker = ImagePicker();

  // State for draft, publishAt, expireAt
  bool isDraft = announcement?.draft ?? false;
  DateTime? publishAt = announcement?.publishAt;
  DateTime? expireAt = announcement?.expireAt;

  // Form key for validation
  final formKey = GlobalKey<FormState>();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            insetPadding: EdgeInsets.symmetric(
              horizontal: Responsive.space(context, size: Space.medium),
              vertical: Responsive.space(context, size: Space.medium),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: Responsive.padding(context, size: Space.medium),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Dialog title
                      Text(
                        isEditing ? 'تعديل الخبر' : 'خبر جديد',
                        style: TextStyle(
                          fontSize:
                              Responsive.text(context, size: TextSize.heading) *
                              1.2,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.medium),
                      ),

                      // Title field
                      CustomTextField(
                        hint: 'العنوان',
                        onChanged: (value) {
                          title = value;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'الرجاء إدخال العنوان';
                          }
                          return null;
                        },
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.small),
                      ),

                      // Description field
                      CustomTextField(
                        hint: 'الوصف',
                        onChanged: (value) {
                          description = value;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'الرجاء إدخال الوصف';
                          }
                          return null;
                        },
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        minLines: 1,
                        maxLines: 5,
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.medium),
                      ),

                      // Links Section
                      _buildLinksSection(context, setState, links),
                      SizedBox(
                        height: Responsive.space(context, size: Space.medium),
                      ),

                      // File Picker Section (for PDFs and other files)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.attach_file),
                        label: const Text('ملف (PDF)'),
                        onPressed: () async {
                          final hasPermission =
                              await PermissionService.requestStoragePermissionWithRationale(
                                context,
                              );
                          if (!hasPermission) return;
                          FilePickerResult? result = await FilePicker.platform
                              .pickFiles(
                                type: FileType.custom,
                                allowedExtensions: ['pdf'],
                              );
                          if (result != null &&
                              result.files.single.path != null) {
                            final file = File(result.files.single.path!);
                            final fileName = result.files.single.name;
                            // Upload to Firebase Storage
                            final storageRef = FirebaseStorage.instance.ref().child(
                              'announcements/attachments/${DateTime.now().millisecondsSinceEpoch}_$fileName',
                            );
                            final uploadTask = storageRef.putFile(file);
                            final snapshot = await uploadTask.whenComplete(
                              () {},
                            );
                            final downloadUrl =
                                await snapshot.ref.getDownloadURL();
                            // Ask user for a title or use file name
                            String? linkTitle = await showDialog<String>(
                              context: context,
                              builder: (context) {
                                String tempTitle = fileName;
                                return AlertDialog(
                                  title: const Text('عنوان الملف'),
                                  content: TextField(
                                    decoration: const InputDecoration(
                                      hintText: 'أدخل عنوان الرابط',
                                    ),
                                    controller: TextEditingController(
                                      text: fileName,
                                    ),
                                    onChanged: (v) => tempTitle = v,
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () =>
                                              Navigator.pop(context, tempTitle),
                                      child: const Text('موافق'),
                                    ),
                                  ],
                                );
                              },
                            );
                            setState(() {
                              links.add({
                                'title': linkTitle ?? fileName,
                                'url': downloadUrl,
                              });
                            });
                          }
                        },
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.medium),
                      ),

                      // Image Picker Section
                      _buildImagePickerSection(
                        context,
                        setState,
                        pickedImages,
                        picker,
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.medium),
                      ),

                      // Color selection
                      // Align(
                      //   alignment: Alignment.centerRight,
                      //   child: Text(
                      //     'اختر اللون:',
                      //     style: TextStyle(
                      //       fontSize:
                      //           Responsive.text(context, size: TextSize.small) *
                      //           1.1,
                      //       fontWeight: FontWeight.bold,
                      //     ),
                      //     textAlign: TextAlign.right,
                      //   ),
                      // ),
                      SizedBox(
                        height:
                            Responsive.space(context, size: Space.small) * 0.5,
                      ),

                      // Enhanced color selection
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Important - Red
                          Column(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedColor = Color(0xFFFF5252);
                                  });
                                },
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Color(0xFFFF5252).withOpacity(0.3),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color:
                                          selectedColor == Color(0xFFFF5252)
                                              ? Colors.black
                                              : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child:
                                      selectedColor == Color(0xFFFF5252)
                                          ? Center(
                                            child: Icon(
                                              Icons.check,
                                              color: Colors.black87,
                                              size: 30,
                                            ),
                                          )
                                          : null,
                                ),
                              ),
                              SizedBox(
                                height: Responsive.space(
                                  context,
                                  size: Space.tiny,
                                ),
                              ),
                              Text(
                                'مهم',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight:
                                      selectedColor == Color(0xFFFF5252)
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            width: Responsive.space(context, size: Space.large),
                          ),

                          // Medium - Yellow
                          Column(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedColor = Color(0xFFFFEF86);
                                  });
                                },
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Color(0xFFFFEF86).withOpacity(0.3),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color:
                                          selectedColor == Color(0xFFFFEF86)
                                              ? Colors.black
                                              : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child:
                                      selectedColor == Color(0xFFFFEF86)
                                          ? Center(
                                            child: Icon(
                                              Icons.check,
                                              color: Colors.black87,
                                              size: 30,
                                            ),
                                          )
                                          : null,
                                ),
                              ),
                              SizedBox(
                                height: Responsive.space(
                                  context,
                                  size: Space.tiny,
                                ),
                              ),
                              Text(
                                'نص نص',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight:
                                      selectedColor == Color(0xFFFFEF86)
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            width: Responsive.space(context, size: Space.large),
                          ),

                          // Normal - Green
                          Column(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedColor = Color(0xFF99F16C);
                                  });
                                },
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Color(0xFF99F16C).withOpacity(0.3),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color:
                                          selectedColor == Color(0xFF99F16C)
                                              ? Colors.black
                                              : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child:
                                      selectedColor == Color(0xFF99F16C)
                                          ? Center(
                                            child: Icon(
                                              Icons.check,
                                              color: Colors.black87,
                                              size: 30,
                                            ),
                                          )
                                          : null,
                                ),
                              ),
                              SizedBox(
                                height: Responsive.space(
                                  context,
                                  size: Space.tiny,
                                ),
                              ),
                              Text(
                                'عادي',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight:
                                      selectedColor == Color(0xFF99F16C)
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.medium),
                      ),

                      // Tags selection
                      Align(
                        alignment: Alignment.centerRight,
                        // child: Text(
                        //   'اختر الأقسام:',
                        //   style: TextStyle(
                        //     fontSize:
                        //         Responsive.text(context, size: TextSize.small) *
                        //         1.1,
                        //     fontWeight: FontWeight.bold,
                        //   ),
                        //   textAlign: TextAlign.right,
                        // ),
                      ),
                      SizedBox(
                        height:
                            Responsive.space(context, size: Space.small) * 0.5,
                      ),

                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: EdgeInsets.all(12),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.end,
                          children:
                              availableTags.map((tag) {
                                final isSelected = selectedTags.contains(tag);
                                return Container(
                                  margin: EdgeInsets.only(
                                    bottom:
                                        Responsive.space(
                                          context,
                                          size: Space.small,
                                        ) *
                                        .1,
                                  ),
                                  child: FilterChip(
                                    label: Text(tag),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          selectedTags.add(tag);
                                        } else {
                                          selectedTags.remove(tag);
                                        }
                                      });
                                    },
                                    selectedColor: selectedColor.withOpacity(
                                      0.3,
                                    ),
                                    checkmarkColor: Colors.black,
                                    labelStyle: TextStyle(
                                      color: Colors.black,
                                      fontWeight:
                                          isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: Responsive.space(context),
                                      vertical: Responsive.space(context) * .5,
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.medium),
                      ),

                      // Draft checkbox
                      CheckboxListTile(
                        value: isDraft,
                        onChanged: (v) => setState(() => isDraft = v ?? false),
                        title: const Text('حفظ كمسودة'),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      // Scheduled publish date
                      ListTile(
                        title: const Text('تاريخ النشر (اختياري)'),
                        subtitle: Text(
                          publishAt != null
                              ? DateFormat(
                                'yyyy/MM/dd HH:mm',
                              ).format(publishAt!)
                              : 'غير محدد',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: publishAt ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (picked != null) {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(
                                  (publishAt ?? DateTime.now()),
                                ),
                              );
                              if (time != null) {
                                setState(() {
                                  publishAt = DateTime(
                                    picked.year,
                                    picked.month,
                                    picked.day,
                                    time.hour,
                                    time.minute,
                                  );
                                });
                              }
                            }
                          },
                        ),
                        onLongPress: () => setState(() => publishAt = null),
                      ),
                      // Expiry date
                      ListTile(
                        title: const Text('تاريخ الانتهاء (اختياري)'),
                        subtitle: Text(
                          expireAt != null
                              ? DateFormat('yyyy/MM/dd HH:mm').format(expireAt!)
                              : 'غير محدد',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: expireAt ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (picked != null) {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(
                                  (expireAt ?? DateTime.now()),
                                ),
                              );
                              if (time != null) {
                                setState(() {
                                  expireAt = DateTime(
                                    picked.year,
                                    picked.month,
                                    picked.day,
                                    time.hour,
                                    time.minute,
                                  );
                                });
                              }
                            }
                          },
                        ),
                        onLongPress: () => setState(() => expireAt = null),
                      ),

                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                if (selectedTags.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'الرجاء اختيار قسم واحد على الأقل',
                                        textAlign: TextAlign.right,
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                // Show loading indicator
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (BuildContext context) {
                                    return const Dialog(
                                      child: Padding(
                                        padding: EdgeInsets.all(20.0),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CircularProgressIndicator(),
                                            SizedBox(width: 20),
                                            Text("جاري رفع الصور..."),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );

                                final announcementProvider =
                                    Provider.of<AnnouncementProvider>(
                                      context,
                                      listen: false,
                                    );
                                List<String> imageUrls = [];

                                // Upload images and collect URLs
                                for (XFile image in pickedImages) {
                                  final String? imageUrl =
                                      await announcementProvider.uploadImage(
                                        image,
                                      );
                                  if (imageUrl != null) {
                                    imageUrls.add(imageUrl);
                                  } else {
                                    // Handle upload failure
                                    Navigator.of(
                                      context,
                                    ).pop(); // Dismiss loading dialog
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'فشل رفع الصورة، الرجاء المحاولة مرة أخرى',
                                          textAlign: TextAlign.right,
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }
                                }

                                // Add existing URLs if editing
                                if (announcement?.imageUrls != null) {
                                  imageUrls.addAll(announcement!.imageUrls);
                                }

                                final newAnnouncement = AnnouncementData(
                                  id: announcement?.id,
                                  title: title,
                                  date: DateFormat(
                                    'yyyy-MM-dd',
                                  ).format(DateTime.now()),
                                  color: selectedColor,
                                  description: description,
                                  tags: selectedTags,
                                  imageUrls: imageUrls,
                                  links: links,
                                  timestamp: DateTime.now(),
                                  draft: isDraft,
                                  publishAt: publishAt,
                                  expireAt: expireAt,
                                );

                                // Hide loading indicator
                                Navigator.of(context).pop();

                                // Call the onSave callback
                                onSave(newAnnouncement);

                                // Close the dialog
                                Navigator.of(context).pop();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: selectedColor.withOpacity(.3),
                              elevation: 0,
                              padding: EdgeInsets.symmetric(
                                horizontal: Responsive.space(
                                  context,
                                  size: Space.large,
                                ),
                                vertical: Responsive.space(
                                  context,
                                  size: Space.small,
                                ),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Text(
                              isEditing ? 'تحديث' : 'إضافة',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
                              ),
                            ),
                            child: const Text(
                              'إلغاء',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

// Helper method to build the image picker UI
Widget _buildImagePickerSection(
  BuildContext context,
  void Function(void Function()) setState,
  List<XFile> pickedImages,
  ImagePicker picker,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'الصور',
        style: TextStyle(
          fontSize: Responsive.text(context, size: TextSize.medium),
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.right,
      ),
      SizedBox(height: Responsive.space(context, size: Space.small)),
      OutlinedButton.icon(
        icon: Icon(Icons.image),
        label: Text('إرفاق صورة'),
        onPressed: () async {
          final hasPermission =
              await PermissionService.requestPhotosPermissionWithRationale(
                context,
              );
          if (!hasPermission) return;
          final List<XFile> images = await picker.pickMultiImage();
          if (images.isNotEmpty) {
            setState(() {
              pickedImages.addAll(images);
            });
          }
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          side: BorderSide(color: Colors.grey.shade400),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      if (pickedImages.isNotEmpty)
        Container(
          height: 100,
          margin: EdgeInsets.only(
            top: Responsive.space(context, size: Space.small),
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: pickedImages.length,
            itemBuilder: (context, index) {
              return Stack(
                alignment: Alignment.topLeft,
                children: [
                  Container(
                    margin: EdgeInsets.only(right: 8),
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image:
                            (kIsWeb
                                    ? CachedNetworkImageProvider(
                                      pickedImages[index].path,
                                    )
                                    : FileImage(File(pickedImages[index].path)))
                                as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        pickedImages.removeAt(index);
                      });
                    },
                  ),
                ],
              );
            },
          ),
        ),
    ],
  );
}

// Helper method to build the links UI
Widget _buildLinksSection(
  BuildContext context,
  void Function(void Function()) setState,
  List<Map<String, String>> links,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'الروابط',
        style: TextStyle(
          fontSize: Responsive.text(context, size: TextSize.medium),
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.right,
      ),
      SizedBox(height: Responsive.space(context, size: Space.small)),
      OutlinedButton.icon(
        icon: Icon(Icons.add_link),
        label: Text('إضافة رابط'),
        onPressed: () {
          _showAddLinkDialog(context, (newLink) {
            setState(() {
              links.add(newLink);
            });
          });
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          side: BorderSide(color: Colors.grey.shade400),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      if (links.isNotEmpty)
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          alignment: WrapAlignment.end,
          children:
              links.map((link) {
                return Chip(
                  label: Text(link['title'] ?? 'Link'),
                  onDeleted: () {
                    setState(() {
                      links.remove(link);
                    });
                  },
                );
              }).toList(),
        ),
    ],
  );
}

// Dialog to add a single link
void _showAddLinkDialog(
  BuildContext context,
  Function(Map<String, String>) onSave,
) {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController urlController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('إضافة رابط جديد'),
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
            onPressed: () => Navigator.of(context).pop(),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                onSave({
                  'title': titleController.text,
                  'url': urlController.text,
                });
                Navigator.of(context).pop();
              }
            },
            child: Text('حفظ'),
          ),
        ],
      );
    },
  );
}
