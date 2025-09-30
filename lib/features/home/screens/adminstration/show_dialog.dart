import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:pivot/features/home/screens/adminstration/models/announcement_data.dart';
import 'package:pivot/providers/announcement_provider.dart';
import 'package:provider/provider.dart';
// import 'package:permission_handler/permission_handler.dart';
import 'package:pivot/services/permission_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/widgets/custom_text_field.dart';
import 'package:flutter/foundation.dart';

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

// Available colors for selection
final List<Color> availableColors = [
  const Color(0xffff5252), // Red
  const Color(0xFFFFEF86), // Yellow
  const Color(0xFF99F16C), // Green
];

// Available tags (categories) for selection - using display names
final List<String> availableTags =
    DepartmentTag.values.map((tag) => tag.displayName).toList();

// Show dialog to add or edit an announcement
void showAddAnnouncementDialog({
  required BuildContext context,
  required Function(AnnouncementData) onSave,
  bool isEditing = false,
  AnnouncementData? announcement,
}) {
  // Create controllers with initial values for editing
  final TextEditingController titleController = TextEditingController(
    text: announcement?.title ?? '',
  );
  final TextEditingController descriptionController = TextEditingController(
    text: announcement?.description ?? '',
  );

  // Use String state variables
  String title = announcement?.title ?? '';
  String description = announcement?.description ?? '';

  // Selected color and tags
  Color selectedColor = announcement?.color ?? availableColors[0];
  List<String> selectedTags = List<String>.from(announcement?.tags ?? []);

  // Convert full tags to display names for editing
  if (announcement != null && announcement.tags.isNotEmpty) {
    selectedTags =
        announcement.tags
            .map((fullTag) {
              final match =
                  DepartmentTag.values
                      .where((tag) => tag.fullTag == fullTag)
                      .toList();
              return match.isNotEmpty ? match.first.displayName : null;
            })
            .whereType<String>() // Remove nulls
            .toList();
  }

  // State for images and links
  List<XFile> pickedImages = [];
  List<Map<String, String>> links = List<Map<String, String>>.from(
    announcement?.links ?? [],
  );
  final ImagePicker picker = ImagePicker();

  // State for draft, publishAt, expireAt
  DateTime? publishAt = announcement?.publishAt;
  DateTime? expireAt = announcement?.expireAt;

  // Form key for validation
  final formKey = GlobalKey<FormState>();

  // Helper to check if the form is valid (must be inside to access local vars)
  bool isFormValid() {
    return title.trim().isNotEmpty &&
        description.trim().isNotEmpty &&
        selectedTags.isNotEmpty &&
        (publishAt == null || expireAt == null || expireAt.isAfter(publishAt));
  }

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
                        controller: titleController,
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
                        controller: descriptionController,
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              Tooltip(
                                message: 'إرفاق صورة',
                                child: IconButton(
                                  icon: Icon(
                                    Icons.image,
                                    color: Colors.green,
                                    size: 30,
                                  ),
                                  onPressed: () async {
                                    final hasPermission =
                                        await PermissionService.requestPhotosPermissionWithRationale(
                                          context,
                                        );
                                    if (!hasPermission) return;
                                    final List<XFile> images =
                                        await picker.pickMultiImage();
                                    if (images.isNotEmpty) {
                                      setState(() {
                                        for (var img in images) {
                                          if (!pickedImages.any(
                                            (i) => i.path == img.path,
                                          )) {
                                            pickedImages.add(img);
                                          }
                                        }
                                      });
                                    }
                                  },
                                ),
                              ),
                              Text(
                                'صورة',
                                style: TextStyle(
                                  fontSize: Responsive.text(
                                    context,
                                    size: TextSize.small,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            width: Responsive.space(context, size: Space.large),
                          ),
                          Column(
                            children: [
                              Tooltip(
                                message: 'إرفاق ملف PDF',
                                child: IconButton(
                                  icon: Icon(
                                    Icons.attach_file,
                                    color: Colors.orange,
                                    size: 30,
                                  ),
                                  onPressed: () async {
                                    try {
                                      FilePickerResult? result =
                                          await FilePicker.platform.pickFiles(
                                            type: FileType.custom,
                                            allowedExtensions: ['pdf'],
                                          );
                                      if (result != null &&
                                          result.files.single.path != null) {
                                        showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder:
                                              (context) => AlertDialog(
                                                content: Row(
                                                  children: [
                                                    CircularProgressIndicator(),
                                                    SizedBox(
                                                      width: Responsive.space(
                                                        context,
                                                        size: Space.medium,
                                                      ),
                                                    ),
                                                    Text('جاري رفع الملف...'),
                                                  ],
                                                ),
                                              ),
                                        );
                                        final file = File(
                                          result.files.single.path!,
                                        );
                                        final fileName =
                                            result.files.single.name;
                                        final fileSize = await file.length();
                                        if (fileSize > 10 * 1024 * 1024) {
                                          Navigator.of(context).pop();
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'حجم الملف أكبر من 10 ميجابايت',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                          return;
                                        }
                                        final storageRef = FirebaseStorage
                                            .instance
                                            .ref()
                                            .child(
                                              'announcements/attachments/${DateTime.now().millisecondsSinceEpoch}_$fileName',
                                            );
                                        final uploadTask = storageRef.putFile(
                                          file,
                                        );
                                        final snapshot = await uploadTask
                                            .whenComplete(() {});
                                        final downloadUrl =
                                            await snapshot.ref.getDownloadURL();
                                        Navigator.of(context).pop();
                                        String?
                                        linkTitle = await showDialog<String>(
                                          context: context,
                                          builder: (context) {
                                            String tempTitle = fileName;
                                            final TextEditingController
                                            controller = TextEditingController(
                                              text: fileName,
                                            );
                                            return Dialog(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Container(
                                                padding: EdgeInsets.all(
                                                  Responsive.space(
                                                    context,
                                                    size: Space.large,
                                                  ),
                                                ),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    // Header with icon
                                                    Container(
                                                      padding: EdgeInsets.all(
                                                        Responsive.space(
                                                          context,
                                                          size: Space.medium,
                                                        ),
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.blue
                                                            .withOpacity(0.1),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              15,
                                                            ),
                                                      ),
                                                      child: Icon(
                                                        Icons.edit_note,
                                                        size:
                                                            Responsive.space(
                                                              context,
                                                              size: Space.large,
                                                            ) *
                                                            2,
                                                        color: Colors.blue[700],
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      height: Responsive.space(
                                                        context,
                                                        size: Space.medium,
                                                      ),
                                                    ),

                                                    // Title
                                                    Text(
                                                      'تعديل اسم الملف',
                                                      style: TextStyle(
                                                        fontSize:
                                                            Responsive.text(
                                                              context,
                                                              size:
                                                                  TextSize
                                                                      .heading,
                                                            ),
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.black87,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                    SizedBox(
                                                      height: Responsive.space(
                                                        context,
                                                        size: Space.small,
                                                      ),
                                                    ),

                                                    // Subtitle
                                                    Text(
                                                      'أدخل اسم الملف كما تريد أن يظهر في الإعلان',
                                                      style: TextStyle(
                                                        fontSize:
                                                            Responsive.text(
                                                              context,
                                                              size:
                                                                  TextSize
                                                                      .small,
                                                            ),
                                                        color: Colors.grey[600],
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                    SizedBox(
                                                      height: Responsive.space(
                                                        context,
                                                        size: Space.large,
                                                      ),
                                                    ),

                                                    // File info card
                                                    Container(
                                                      padding: EdgeInsets.all(
                                                        Responsive.space(
                                                          context,
                                                          size: Space.medium,
                                                        ),
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey[50],
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                        border: Border.all(
                                                          color:
                                                              Colors.grey[200]!,
                                                        ),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .picture_as_pdf,
                                                            color:
                                                                Colors.red[600],
                                                            size: Responsive.space(
                                                              context,
                                                              size:
                                                                  Space.medium,
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width:
                                                                Responsive.space(
                                                                  context,
                                                                  size:
                                                                      Space
                                                                          .small,
                                                                ),
                                                          ),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  'الملف المرفوع:',
                                                                  style: TextStyle(
                                                                    fontSize: Responsive.text(
                                                                      context,
                                                                      size:
                                                                          TextSize
                                                                              .small,
                                                                    ),
                                                                    color:
                                                                        Colors
                                                                            .grey[600],
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                  ),
                                                                ),
                                                                Text(
                                                                  fileName,
                                                                  style: TextStyle(
                                                                    fontSize: Responsive.text(
                                                                      context,
                                                                      size:
                                                                          TextSize
                                                                              .medium,
                                                                    ),
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    color:
                                                                        Colors
                                                                            .black87,
                                                                  ),
                                                                  maxLines: 1,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      height: Responsive.space(
                                                        context,
                                                        size: Space.large,
                                                      ),
                                                    ),

                                                    // Input field using CustomTextField
                                                    CustomTextField(
                                                      hint:
                                                          'أدخل اسم الملف الجديد',
                                                      controller: controller,
                                                      onChanged: (value) {
                                                        tempTitle = value;
                                                      },
                                                    ),
                                                    SizedBox(
                                                      height: Responsive.space(
                                                        context,
                                                        size: Space.large,
                                                      ),
                                                    ),

                                                    // Action buttons
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: TextButton(
                                                            onPressed:
                                                                () =>
                                                                    Navigator.pop(
                                                                      context,
                                                                    ),
                                                            style: TextButton.styleFrom(
                                                              padding: EdgeInsets.symmetric(
                                                                vertical:
                                                                    Responsive.space(
                                                                      context,
                                                                      size:
                                                                          Space
                                                                              .small,
                                                                    ),
                                                              ),
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      10,
                                                                    ),
                                                              ),
                                                            ),
                                                            child: Text(
                                                              'إلغاء',
                                                              style: TextStyle(
                                                                fontSize: Responsive.text(
                                                                  context,
                                                                  size:
                                                                      TextSize
                                                                          .medium,
                                                                ),
                                                                color:
                                                                    Colors
                                                                        .grey[600],
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width:
                                                              Responsive.space(
                                                                context,
                                                                size:
                                                                    Space.small,
                                                              ),
                                                        ),
                                                        Expanded(
                                                          child: ElevatedButton(
                                                            onPressed:
                                                                () =>
                                                                    Navigator.pop(
                                                                      context,
                                                                      tempTitle,
                                                                    ),
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor:
                                                                  Colors
                                                                      .blue[600],
                                                              foregroundColor:
                                                                  Colors.white,
                                                              padding: EdgeInsets.symmetric(
                                                                vertical:
                                                                    Responsive.space(
                                                                      context,
                                                                      size:
                                                                          Space
                                                                              .small,
                                                                    ),
                                                              ),
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      10,
                                                                    ),
                                                              ),
                                                              elevation: 0,
                                                            ),
                                                            child: Text(
                                                              'حفظ',
                                                              style: TextStyle(
                                                                fontSize: Responsive.text(
                                                                  context,
                                                                  size:
                                                                      TextSize
                                                                          .medium,
                                                                ),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                        setState(() {
                                          if (!links.any(
                                            (l) => l['url'] == downloadUrl,
                                          )) {
                                            links.add({
                                              'title': linkTitle ?? 'File',
                                              'url': downloadUrl,
                                            });
                                          }
                                        });
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text('تم رفع الملف بنجاح'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (Navigator.canPop(context)) {
                                        Navigator.of(context).pop();
                                      }
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('فشل في رفع الملف: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                              Text(
                                'ملف',
                                style: TextStyle(
                                  fontSize: Responsive.text(
                                    context,
                                    size: TextSize.small,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            width: Responsive.space(context, size: Space.large),
                          ),
                          Column(
                            children: [
                              Tooltip(
                                message: 'إضافة رابط',
                                child: IconButton(
                                  icon: Icon(
                                    Icons.add_link,
                                    color: Colors.blue,
                                    size: 30,
                                  ),
                                  onPressed: () {
                                    _showAddLinkDialog(context, (newLink) {
                                      setState(() {
                                        if (!links.any(
                                          (l) => l['url'] == newLink['url'],
                                        )) {
                                          links.add(newLink);
                                        }
                                      });
                                    });
                                  },
                                ),
                              ),
                              Text(
                                'رابط',
                                style: TextStyle(
                                  fontSize: Responsive.text(
                                    context,
                                    size: TextSize.small,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.medium),
                      ),

                      // Image Picker Section
                      if (links.isNotEmpty)
                        Padding(
                          padding: Responsive.paddingVertical(
                            context,
                            size: Space.small,
                          ),
                          child: Wrap(
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
                                                    : FileImage(
                                                      File(
                                                        pickedImages[index]
                                                            .path,
                                                      ),
                                                    ))
                                                as ImageProvider,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.remove_circle,
                                      color: Colors.red,
                                    ),
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

                      // Display existing images when editing
                      if (isEditing &&
                          announcement?.imageUrls.isNotEmpty == true)
                        Container(
                          height: 100,
                          margin: EdgeInsets.only(
                            top: Responsive.space(context, size: Space.small),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'الصور المرفقة حالياً:',
                                style: TextStyle(
                                  fontSize: Responsive.text(
                                    context,
                                    size: TextSize.small,
                                  ),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                              SizedBox(
                                height: Responsive.space(
                                  context,
                                  size: Space.tiny,
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: announcement!.imageUrls.length,
                                  itemBuilder: (context, index) {
                                    return Container(
                                      margin: EdgeInsets.only(right: 8),
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        image: DecorationImage(
                                          image: CachedNetworkImageProvider(
                                            announcement.imageUrls[index],
                                          ),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
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
                                  fontSize: Responsive.text(
                                    context,
                                    size: TextSize.medium,
                                  ),
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
                                  fontSize: Responsive.text(
                                    context,
                                    size: TextSize.medium,
                                  ),
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
                                  fontSize: Responsive.text(
                                    context,
                                    size: TextSize.medium,
                                  ),
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
                        height: Responsive.space(context, size: Space.small),
                      ),

                      // Simple horizontal scrollable tags
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        reverse: true,
                        child: Row(
                          children:
                              availableTags.map((tag) {
                                final isSelected = selectedTags.contains(tag);
                                return Container(
                                  margin: EdgeInsets.only(left: 8),
                                  child: FilterChip(
                                    label: Text(
                                      tag,
                                      style: TextStyle(
                                        color:
                                            isSelected
                                                ? Colors.white
                                                : Colors.black87,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          if (!selectedTags.contains(tag)) {
                                            selectedTags.add(tag);
                                          }
                                        } else {
                                          selectedTags.remove(tag);
                                        }
                                      });
                                    },
                                    selectedColor: selectedColor,
                                    backgroundColor: Colors.grey[200],
                                    checkmarkColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ),

                      // Scheduled publish date
                      // Row(
                      //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      //   children: [
                      //     Column(
                      //       children: [
                      //         Row(
                      //           mainAxisAlignment: MainAxisAlignment.center,
                      //           children: [
                      //             IconButton(
                      //               icon: Icon(
                      //                 publishAt != null
                      //                     ? Icons.schedule
                      //                     : Icons.schedule_outlined,
                      //                 color:
                      //                     publishAt != null
                      //                         ? Colors.blue[600]
                      //                         : Colors.grey[600],
                      //                 size:
                      //                     Responsive.space(
                      //                       context,
                      //                       size: Space.medium,
                      //                     ) *
                      //                     1.5,
                      //               ),
                      //               onPressed: () async {
                      //                 final picked = await showDatePicker(
                      //                   context: context,
                      //                   initialDate:
                      //                       publishAt ?? DateTime.now(),
                      //                   firstDate: DateTime.now(),
                      //                   lastDate: DateTime.now().add(
                      //                     const Duration(days: 365),
                      //                   ),
                      //                 );
                      //                 if (picked != null) {
                      //                   final time = await showTimePicker(
                      //                     context: context,
                      //                     initialTime: TimeOfDay.fromDateTime(
                      //                       (publishAt ?? DateTime.now()),
                      //                     ),
                      //                   );
                      //                   if (time != null) {
                      //                     setState(() {
                      //                       publishAt = DateTime(
                      //                         picked.year,
                      //                         picked.month,
                      //                         picked.day,
                      //                         time.hour,
                      //                         time.minute,
                      //                       );
                      //                     });
                      //                   }
                      //                 }
                      //               },
                      //             ),
                      //             if (publishAt != null) ...[
                      //               SizedBox(width: 8),
                      //               IconButton(
                      //                 icon: Icon(
                      //                   Icons.clear,
                      //                   size: 20,
                      //                   color: Colors.red[400],
                      //                 ),
                      //                 onPressed:
                      //                     () =>
                      //                         setState(() => publishAt = null),
                      //               ),
                      //           ],
                      //         ),
                      //         Text(
                      //           'جدول النشر',
                      //           style: TextStyle(
                      //             fontSize:
                      //                 Responsive.text(
                      //                   context,
                      //                   size: TextSize.small,
                      //                 ) *
                      //                 1.1,
                      //             color: Colors.grey[600],
                      //             fontWeight: FontWeight.w500,
                      //           ),
                      //         ),
                      //         Text(
                      //           publishAt != null
                      //               ? DateFormat(
                      //                 'yyyy/MM/dd HH:mm',
                      //               ).format(publishAt!)
                      //               : 'غير محدد',
                      //           style: TextStyle(
                      //             fontSize: Responsive.text(
                      //               context,
                      //               size: TextSize.small,
                      //             ),
                      //             color:
                      //                 publishAt != null
                      //                     ? Colors.blue[600]
                      //                     : Colors.grey[500],
                      //             fontWeight: FontWeight.w600,
                      //           ),
                      //         ),
                      //       ],
                      //     ),

                      //     // Expiry date
                      //     Column(
                      //       children: [
                      //         Row(
                      //           mainAxisAlignment: MainAxisAlignment.center,
                      //           children: [
                      //             IconButton(
                      //               icon: Icon(
                      //                 expireAt != null
                      //                     ? Icons.event
                      //                     : Icons.event_outlined,
                      //                 color:
                      //                     expireAt != null
                      //                         ? Colors.red[600]
                      //                         : Colors.grey[600],
                      //                 size:
                      //                     Responsive.space(
                      //                       context,
                      //                       size: Space.medium,
                      //                     ) *
                      //                     1.5,
                      //               ),
                      //               onPressed: () async {
                      //                 final picked = await showDatePicker(
                      //                   context: context,
                      //                   initialDate: expireAt ?? DateTime.now(),
                      //                   firstDate: DateTime.now(),
                      //                   lastDate: DateTime.now().add(
                      //                     const Duration(days: 365),
                      //                   ),
                      //                 );
                      //                 if (picked != null) {
                      //                   final time = await showTimePicker(
                      //                     context: context,
                      //                     initialTime: TimeOfDay.fromDateTime(
                      //                       (expireAt ?? DateTime.now()),
                      //                     ),
                      //                   );
                      //                   if (time != null) {
                      //                     setState(() {
                      //                       expireAt = DateTime(
                      //                         picked.year,
                      //                         picked.month,
                      //                         picked.day,
                      //                         time.hour,
                      //                         time.minute,
                      //                       );
                      //                     });
                      //                   }
                      //                 }
                      //               },
                      //             ),
                      //             if (expireAt != null) ...[
                      //               SizedBox(width: 8),
                      //               IconButton(
                      //                 icon: Icon(
                      //                   Icons.clear,
                      //                   size: 20,
                      //                   color: Colors.red[400],
                      //                 ),
                      //                 onPressed:
                      //                     () => setState(() => expireAt = null),
                      //               ),
                      //           ],
                      //         ),
                      //         Text(
                      //           'تاريخ الانتهاء',
                      //           style: TextStyle(
                      //             fontSize:
                      //                 Responsive.text(
                      //                   context,
                      //                   size: TextSize.small,
                      //                 ) *
                      //                 1.1,
                      //             color: Colors.grey[600],
                      //             fontWeight: FontWeight.w500,
                      //           ),
                      //         ),
                      //         Text(
                      //           expireAt != null
                      //               ? DateFormat(
                      //                 'yyyy/MM/dd HH:mm',
                      //               ).format(expireAt!)
                      //               : 'غير محدد',
                      //           style: TextStyle(
                      //             fontSize: 14,
                      //             color:
                      //                 expireAt != null
                      //                     ? Colors.red[600]
                      //                     : Colors.grey[500],
                      //             fontWeight: FontWeight.w600,
                      //           ),
                      //         ),
                      //       ],
                      //     ),
                      //   ],
                      // ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.medium),
                      ),
                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
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
                            child: Text(
                              'إلغاء',
                              style: TextStyle(
                                fontSize: Responsive.text(
                                  context,
                                  size: TextSize.medium,
                                ),
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed:
                                isFormValid()
                                    ? () async {
                                      if (!isFormValid()) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'يرجى ملء جميع الحقول المطلوبة بشكل صحيح',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return;
                                      }
                                      if (publishAt != null &&
                                          expireAt != null &&
                                          !expireAt.isAfter(publishAt)) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'تاريخ الانتهاء يجب أن يكون بعد تاريخ النشر',
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
                                          return Dialog(
                                            child: Padding(
                                              padding: Responsive.padding(
                                                context,
                                                size: Space.large,
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  CircularProgressIndicator(),
                                                  SizedBox(
                                                    width: Responsive.space(
                                                      context,
                                                      size: Space.medium,
                                                    ),
                                                  ),
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

                                      // Start with existing images if editing
                                      if (isEditing &&
                                          announcement?.imageUrls != null) {
                                        imageUrls.addAll(
                                          announcement!.imageUrls,
                                        );
                                      }

                                      // Upload images and collect URLs
                                      for (XFile image in pickedImages) {
                                        try {
                                          // Defensive checks
                                          if (image.path.isEmpty) {
                                            throw Exception(
                                              'مسار الصورة غير صالح',
                                            );
                                          }
                                          final file = File(image.path);
                                          if (!await file.exists()) {
                                            throw Exception(
                                              'الملف غير موجود: ${image.path}',
                                            );
                                          }
                                          final fileSize = await file.length();
                                          if (fileSize > 10 * 1024 * 1024) {
                                            // 10MB limit
                                            throw Exception(
                                              'حجم الصورة أكبر من 10 ميجابايت',
                                            );
                                          }
                                          final allowedExtensions = [
                                            'jpg',
                                            'jpeg',
                                            'png',
                                          ];
                                          final ext =
                                              image.path
                                                  .split('.')
                                                  .last
                                                  .toLowerCase();
                                          if (!allowedExtensions.contains(
                                            ext,
                                          )) {
                                            throw Exception(
                                              'نوع الصورة غير مدعوم: $ext',
                                            );
                                          }
                                          final String? imageUrl =
                                              await announcementProvider
                                                  .uploadImage(image);
                                          if (imageUrl != null) {
                                            if (!imageUrls.contains(imageUrl)) {
                                              imageUrls.add(imageUrl);
                                            }
                                          } else {
                                            if (Navigator.canPop(context)) {
                                              Navigator.of(context).pop();
                                            }
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text('فشل رفع الصورة'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                            return;
                                          }
                                        } catch (e) {
                                          if (Navigator.canPop(context)) {
                                            Navigator.of(context).pop();
                                          }
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'خطأ في رفع الصورة: $e',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                          return;
                                        }
                                      }

                                      // Prevent duplicate links
                                      final uniqueLinks =
                                          <String, Map<String, String>>{};
                                      for (var link in links) {
                                        uniqueLinks[link['url'] ?? ''] = link;
                                      }

                                      // Before saving, add this debug print:
                                      final convertedTags =
                                          selectedTags.map((displayName) {
                                            final departmentTag = DepartmentTag
                                                .values
                                                .firstWhere(
                                                  (tag) =>
                                                      tag.displayName ==
                                                      displayName,
                                                  orElse:
                                                      () =>
                                                          DepartmentTag.general,
                                                );
                                            return departmentTag.fullTag;
                                          }).toList();

                                      final newAnnouncement = AnnouncementData(
                                        id: announcement?.id,
                                        title: title,
                                        date: DateFormat(
                                          'yyyy-MM-dd',
                                        ).format(DateTime.now()),
                                        color: selectedColor,
                                        description: description,
                                        tags: convertedTags,
                                        imageUrls: imageUrls,
                                        links: uniqueLinks.values.toList(),
                                        timestamp: DateTime.now(),
                                        draft: false,
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
                                    : null,
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
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: Responsive.text(
                                  context,
                                  size: TextSize.medium,
                                ),
                              ),
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
