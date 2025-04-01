import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:intl/intl.dart';
import 'package:pivot/screens/section2/adminstration/models/announcement_data.dart';

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
  int? index,
}) {
  // Form controllers
  final titleController = TextEditingController(
    text: announcement?.title ?? '',
  );
  final descriptionController = TextEditingController(
    text: announcement?.description ?? '',
  );

  // Selected color and tags
  Color selectedColor = announcement?.color ?? availableColors[0];
  List<String> selectedTags = List<String>.from(announcement?.tags ?? []);

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
                              Responsive.text(context, size: TextSize.medium) *
                              1.2,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.medium),
                      ),

                      // Title field
                      TextFormField(
                        controller: titleController,
                        textAlign: TextAlign.right,
                        decoration: InputDecoration(
                          labelText: 'العنوان',
                          alignLabelWithHint: true,
                          floatingLabelAlignment: FloatingLabelAlignment.start,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
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
                      TextFormField(
                        controller: descriptionController,
                        textAlign: TextAlign.right,
                        decoration: InputDecoration(
                          labelText: 'الوصف',
                          alignLabelWithHint: true,
                          floatingLabelAlignment: FloatingLabelAlignment.start,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'الرجاء إدخال الوصف';
                          }
                          return null;
                        },
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.medium),
                      ),

                      // Color selection
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'اختر اللون:',
                          style: TextStyle(
                            fontSize:
                                Responsive.text(context, size: TextSize.small) *
                                1.1,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
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
                              SizedBox(height: 4),
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
                          SizedBox(width: 20),

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
                              SizedBox(height: 4),
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
                          SizedBox(width: 20),

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
                              SizedBox(height: 4),
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
                        child: Text(
                          'اختر الأقسام:',
                          style: TextStyle(
                            fontSize:
                                Responsive.text(context, size: TextSize.small) *
                                1.1,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.right,
                        ),
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

                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              if (formKey.currentState!.validate()) {
                                if (selectedTags.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'الرجاء اختيار قسم واحد على الأقل',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                // Get current date formatted as day/month
                                final now = DateTime.now();
                                final formatter = DateFormat('d/M');
                                final formattedDate = formatter.format(now);

                                final newAnnouncement = AnnouncementData(
                                  title: titleController.text,
                                  date: formattedDate,
                                  color: selectedColor,
                                  description: descriptionController.text,
                                  tags: selectedTags,
                                  timestamp: now,
                                );

                                // Call the onSave callback with the new announcement
                                onSave(newAnnouncement);

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
                            child: const Text(
                              'إلغاء',
                              style: TextStyle(fontSize: 16),
                            ),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
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
