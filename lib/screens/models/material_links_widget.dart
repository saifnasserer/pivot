import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/models/lecture_model.dart';
import 'package:pivot/providers/doctor_subject_provider.dart';
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
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          title: Text(
            'إضافة رابط جديد',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          content: Directionality(
            textDirection: TextDirection.rtl,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: commonDecoration.copyWith(labelText: 'العنوان'),
                    textAlign: TextAlign.right,
                    validator:
                        (value) =>
                            value == null || value.trim().isEmpty
                                ? 'يرجى إدخال العنوان'
                                : null,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: urlController,
                    decoration: commonDecoration.copyWith(labelText: 'الرابط'),
                    textAlign: TextAlign.right,
                    validator:
                        (value) =>
                            value == null || value.trim().isEmpty
                                ? 'يرجى إدخال الرابط'
                                : null,
                  ),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
              ),
              child: const Text('إلغاء'),
              onPressed: () => Navigator.of(context).pop(null),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: borderRadius),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final newLink = {
                    'title': titleController.text.trim(),
                    'url': urlController.text.trim(),
                  };
                  Navigator.of(context).pop(newLink);
                }
              },
              child: const Text('حفظ'),
            ),
          ],
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
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: borderRadius),
              elevation: 8,
              backgroundColor: Colors.white,
              titlePadding: EdgeInsets.only(
                top: Responsive.space(context, size: Space.large),
                left: Responsive.space(context, size: Space.large),
                right: Responsive.space(context, size: Space.large),
                bottom: Responsive.space(context, size: Space.small),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'روابط مادة',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.text(
                        context,
                        size: TextSize.heading,
                      ),
                    ),
                  ),
                  SizedBox(height: Responsive.space(context, size: Space.tiny)),
                  Text(
                    lecture.title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                      fontSize: Responsive.text(context, size: TextSize.medium),
                    ),
                  ),
                  SizedBox(
                    height: Responsive.space(context, size: Space.small),
                  ),
                  Divider(
                    thickness: 1,
                    height: Responsive.space(context, size: Space.tiny),
                  ),
                ],
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: Responsive.space(context, size: Space.medium),
                vertical: Responsive.space(context, size: Space.small),
              ),
              content: Directionality(
                textDirection: TextDirection.rtl,
                child: SizedBox(
                  width: double.maxFinite,
                  child:
                      links.isEmpty
                          ? Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: Responsive.space(
                                context,
                                size: Space.xlarge,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'لا توجد روابط بعد',
                                style: TextStyle(
                                  fontSize: Responsive.text(
                                    context,
                                    size: TextSize.medium,
                                  ),
                                ),
                              ),
                            ),
                          )
                          : ListView.separated(
                            shrinkWrap: true,
                            reverse: true,

                            itemCount: links.length,
                            separatorBuilder:
                                (_, __) => SizedBox(
                                  height: Responsive.space(
                                    context,
                                    size: Space.small,
                                  ),
                                ),
                            itemBuilder: (BuildContext context, int index) {
                              final link = links[index];
                              return Material(
                                color: Colors.grey[100],
                                borderRadius: cardRadius,
                                child: InkWell(
                                  borderRadius: cardRadius,
                                  onTap:
                                      () => _launchURL(context, link['url']!),
                                  child: Padding(
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
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      textDirection: TextDirection.rtl,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                link['title']!,
                                                textAlign: TextAlign.right,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize:
                                                      Responsive.text(
                                                        context,
                                                        size: TextSize.medium,
                                                      ) *
                                                      0.85,
                                                ),
                                              ),
                                              SizedBox(
                                                height: Responsive.space(
                                                  context,
                                                  size: Space.tiny,
                                                ),
                                              ),
                                              Text(
                                                link['url']!,
                                                textAlign: TextAlign.right,
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: Responsive.text(
                                                    context,
                                                    size: TextSize.small,
                                                  ),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (canEdit)
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.redAccent,
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
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                ),
              ),
              actionsPadding: EdgeInsets.only(
                left: Responsive.space(context, size: Space.large),
                right: Responsive.space(context, size: Space.large),
                bottom: Responsive.space(context, size: Space.xlarge),
                top: Responsive.space(context, size: Space.small),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                if (canEdit)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_link_rounded),
                      label: const Text(
                        'إضافة رابط',
                        style: TextStyle(fontSize: null),
                      ),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            Responsive.space(context, size: Space.large),
                          ),
                        ),
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        padding: EdgeInsets.symmetric(
                          vertical: Responsive.space(
                            context,
                            size: Space.small,
                          ),
                        ),
                        textStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.medium,
                          ),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        final newLink = await _showAddSingleLinkDialog(context);
                        if (newLink != null) {
                          setState(() {
                            links.add(newLink);
                          });
                          provider.addLinkToLecture(lecture.id, newLink);
                        }
                      },
                    ),
                  ),
                SizedBox(height: Responsive.space(context, size: Space.small)),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          Responsive.space(context, size: Space.large),
                        ),
                      ),
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: EdgeInsets.symmetric(
                        vertical: Responsive.space(context, size: Space.small),
                      ),
                      textStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.medium,
                        ),
                      ),
                    ),
                    child: Text(
                      'إغلاق',
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.medium,
                        ),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
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
        _showLinksDialog(context, lecture.links);
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
