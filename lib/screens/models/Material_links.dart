import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/models/lecture_model.dart';
import 'package:provider/provider.dart';
import 'package:pivot/providers/user_profile_provider.dart';

class MaterialLinks extends StatelessWidget {
  final Lecture lecture;
  final IconData? icon;

  const MaterialLinks({super.key, required this.lecture, this.icon});

  Future<Map<String, String>?> _showAddSingleLinkDialog(
    BuildContext context,
  ) async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController urlController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    return showDialog<Map<String, String>>(
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
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final newLink = {
                    'title': titleController.text,
                    'url': urlController.text,
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

  void _showLinksDialog(
    BuildContext context,
    List<Map<String, String>> initialLinks,
  ) {
    List<Map<String, String>> links = List.from(initialLinks);
    final userRole =
        Provider.of<UserProfileProvider>(context, listen: false).userProfile?.role ??
            '';
    final canEdit = userRole != 'student' && userRole != 'miniProfessor';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text('روابط مادة: ${lecture.title}'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: links.length,
                  itemBuilder: (BuildContext context, int index) {
                    final link = links[index];
                    return ListTile(
                      leading: const Icon(Icons.link),
                      title: Text(link['title']!),
                      trailing: canEdit
                          ? IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                              onPressed: () {
                                setState(() {
                                  links.removeAt(index);
                                });
                              },
                              tooltip: 'حذف الرابط',
                            )
                          : null,
                      onTap: () {
                        print('Tapped on ${link['url']}');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Opening ${link['url']}')),
                        );
                      },
                    );
                  },
                ),
              ),
              actions: [
                if (canEdit)
                  TextButton(
                    child: const Text('إضافة رابط'),
                    onPressed: () async {
                      final newLink = await _showAddSingleLinkDialog(context);
                      if (newLink != null) {
                        setState(() {
                          links.add(newLink);
                        });
                      }
                    },
                  ),
                TextButton(
                  child: const Text('إغلاق'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
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
    return ElevatedButton(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(Colors.transparent),
        elevation: WidgetStateProperty.all(0),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
