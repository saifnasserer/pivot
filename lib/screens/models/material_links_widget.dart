import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/widgets/unified_dialog.dart';
import 'package:pivot/models/lecture_model.dart';
import 'package:pivot/providers/doctor_subject_provider.dart';
import 'package:pivot/screens/section4/doctor/profile/material_links_screen.dart';
import 'package:pivot/screens/section4/doctor/profile/material_links_route.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SubjectModel extends StatelessWidget {
  final Lecture lecture;
  final IconData? icon;
  final bool canEdit;

  const SubjectModel({
    super.key,
    required this.lecture,
    this.icon,
    this.canEdit = false,
  });

  Future<Map<String, String>?> _showAddSingleLinkDialog(
    BuildContext context,
  ) async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController urlController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final borderRadius = BorderRadius.circular(
      Responsive.space(context, size: Space.large),
    );
    final commonDecoration = InputDecoration(
      border: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: const BorderSide(color: Colors.teal, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 12.0,
      ),
      fillColor: Colors.grey.shade100,
      filled: true,
      labelStyle: TextStyle(color: Colors.grey.shade700),
      hintStyle: TextStyle(color: Colors.grey.shade500),
      alignLabelWithHint: true,
    );

    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return UnifiedDialog(
              title: 'إضافة رابط جديد',
              subtitle: 'أضف رابط جديد للمادة',
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    UnifiedFormField(
                      controller: titleController,
                      label: 'العنوان',
                      hint: 'أدخل عنوان الرابط',
                      validator:
                          (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'يرجى إدخال العنوان'
                                  : null,
                    ),
                    SizedBox(
                      height: Responsive.space(context, size: Space.medium),
                    ),
                    UnifiedFormField(
                      controller: urlController,
                      label: 'الرابط',
                      hint: 'https://example.com',
                      keyboardType: TextInputType.url,
                      validator:
                          (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'يرجى إدخال الرابط'
                                  : null,
                    ),
                  ],
                ),
              ),
              confirmText: 'حفظ',
              confirmIcon: Icons.save,
              onConfirm: () {
                if (formKey.currentState!.validate()) {
                  final newLink = {
                    'title': titleController.text.trim(),
                    'url': urlController.text.trim(),
                  };
                  Navigator.of(context).pop(newLink);
                }
              },
              onCancel: () => Navigator.of(context).pop(null),
            );
          },
        );
      },
    );
  }

  Future<void> _launchURL(BuildContext context, String urlString) async {
    final Uri? url = Uri.tryParse(urlString);
    if (url != null && await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('تعذر فتح الرابط: $urlString')));
      }
    }
  }

  void _showLinksDialog(
    BuildContext context,
    List<Map<String, String>> initialLinks,
  ) {
    final provider = Provider.of<DoctorSubjectProvider>(context, listen: false);
    List<Map<String, String>> links = List.from(initialLinks);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final borderRadius = BorderRadius.circular(
              Responsive.space(context, size: Space.large),
            );
            final cardRadius = BorderRadius.circular(
              Responsive.space(context, size: Space.large),
            );
            return UnifiedDialog(
              title: 'روابط مادة',
              subtitle: lecture.title,
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (links.isEmpty)
                      Container(
                        padding: EdgeInsets.all(
                          Responsive.space(context, size: Space.large),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(
                            Responsive.space(context, size: Space.large),
                          ),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.link_off,
                              size:
                                  Responsive.space(context, size: Space.large) *
                                  2,
                              color: Colors.grey[400],
                            ),
                            SizedBox(
                              height: Responsive.space(
                                context,
                                size: Space.medium,
                              ),
                            ),
                            Text(
                              'لا توجد روابط بعد',
                              style: TextStyle(
                                fontSize: Responsive.text(
                                  context,
                                  size: TextSize.medium,
                                ),
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(
                              height: Responsive.space(
                                context,
                                size: Space.small,
                              ),
                            ),
                            Text(
                              'اضغط على "إضافة رابط" لإضافة روابط جديدة',
                              style: TextStyle(
                                fontSize: Responsive.text(
                                  context,
                                  size: TextSize.small,
                                ),
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      ...links.asMap().entries.map((entry) {
                        final index = entry.key;
                        final link = entry.value;
                        return Directionality(
                          textDirection: TextDirection.rtl,
                          child: Container(
                            margin: EdgeInsets.only(
                              bottom: Responsive.space(
                                context,
                                size: Space.small,
                              ),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(
                                Responsive.space(context, size: Space.large),
                              ),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(
                                Responsive.space(context, size: Space.large),
                              ),
                              onTap: () => _launchURL(context, link['url']!),
                              child: Padding(
                                padding: EdgeInsets.all(
                                  Responsive.space(context, size: Space.medium),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (canEdit)
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                        ),
                                        onPressed: () {
                                          final linkToDelete = links[index];
                                          setState(() {
                                            links.removeAt(index);
                                          });
                                          provider.deleteLinkFromLecture(
                                            lecture.id,
                                            linkToDelete,
                                          );
                                        },
                                        tooltip: 'حذف الرابط',
                                      ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            link['title']!,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: Responsive.text(
                                                context,
                                                size: TextSize.medium,
                                              ),
                                              color: Colors.black87,
                                            ),
                                            textAlign: TextAlign.right,
                                          ),
                                          SizedBox(
                                            height: Responsive.space(
                                              context,
                                              size: Space.tiny,
                                            ),
                                          ),
                                          Text(
                                            link['url']!,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: Responsive.text(
                                                context,
                                                size: TextSize.small,
                                              ),
                                            ),
                                            textAlign: TextAlign.right,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.open_in_new,
                                      color: Colors.grey[400],
                                      size: Responsive.space(
                                        context,
                                        size: Space.medium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                  ],
                ),
              ),
              confirmText: canEdit ? 'إضافة رابط' : null,
              confirmIcon: canEdit ? Icons.add_link : null,
              onConfirm:
                  canEdit
                      ? () async {
                        final newLink = await _showAddSingleLinkDialog(context);
                        if (newLink != null) {
                          setState(() {
                            links.add(newLink);
                          });
                          provider.addLinkToLecture(lecture.id, newLink);
                        }
                      }
                      : null,
              onCancel: () => Navigator.of(context).pop(),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DoctorSubjectProvider>(context, listen: false);
    return ElevatedButton(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(Colors.transparent),
        elevation: WidgetStateProperty.all(0),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              Responsive.space(context, size: Space.large),
            ),
          ),
        ),
      ),
      onPressed: () {
        // Navigate to MaterialLinksScreen instead of showing dialog
        Navigator.of(context).push(
          MaterialLinksRoute(
            lecture: lecture,
            child: MaterialLinksScreen(
              lecture: lecture,
              loggedInUser: null, // TODO: Pass the actual logged in user
            ),
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.all(Responsive.space(context, size: Space.small)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (canEdit)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      final borderRadius = BorderRadius.circular(
                        Responsive.space(context, size: Space.large),
                      );
                      return AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: borderRadius,
                        ),
                        title: const Text(
                          'حذف المادة',
                          textAlign: TextAlign.center,
                        ),
                        content: const Text(
                          'هل أنت متأكد من رغبتك في حذف هذه المادة؟',
                          textAlign: TextAlign.right,
                        ),
                        actionsPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        actionsAlignment: MainAxisAlignment.spaceBetween,
                        actions: <Widget>[
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey.shade700,
                            ),
                            child: const Text('إلغاء'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                            ),
                            child: const Text('حذف'),
                            onPressed: () {
                              provider.deleteLecture(lecture.id);
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          lecture.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: Responsive.text(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: Responsive.space(context)),
                  Container(
                    width: Responsive.space(context, size: Space.large) * 3,
                    height: Responsive.space(context, size: Space.large) * 3,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon ?? Icons.menu_book_rounded,
                      size: Responsive.space(context, size: Space.xlarge),
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
