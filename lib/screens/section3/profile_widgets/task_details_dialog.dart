import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/widgets/unified_dialog.dart';
import 'package:pivot/screens/models/task.dart';
import 'package:url_launcher/url_launcher.dart';

class TaskDetailsDialog extends StatelessWidget {
  final Task task;

  const TaskDetailsDialog({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final String formattedDayOfWeek = DateFormat(
      'EEEE',
      'ar',
    ).format(task.dueDate);
    final String formattedDate = DateFormat(
      'dd MMM, yyyy',
      'ar',
    ).format(task.dueDate);
    final String fullFormattedDate = '$formattedDayOfWeek، $formattedDate';
    final Color headerColor = _getImportanceColor(task.importance);

    return UnifiedDialog(
      title: task.title,
      subtitle: 'تفاصيل المهمة',
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Task importance indicator
            Container(
              padding: EdgeInsets.all(
                Responsive.space(context, size: Space.medium),
              ),
              decoration: BoxDecoration(
                color: headerColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(
                  Responsive.space(context, size: Space.large),
                ),
                border: Border.all(color: headerColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.task_alt,
                    color: headerColor,
                    size: Responsive.space(context, size: Space.large),
                  ),
                  SizedBox(
                    width: Responsive.space(context, size: Space.medium),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _getImportanceText(task.importance),
                          style: TextStyle(
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.medium,
                            ),
                            fontWeight: FontWeight.bold,
                            color: headerColor,
                          ),
                          textAlign: TextAlign.right,
                        ),
                        SizedBox(
                          height: Responsive.space(context, size: Space.tiny),
                        ),
                        Text(
                          'أولوية المهمة',
                          style: TextStyle(
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.small,
                            ),
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: Responsive.space(context, size: Space.medium)),

            // Due date section
            UnifiedSectionHeader(
              title: 'تاريخ الاستحقاق',
              icon: Icons.calendar_today,
            ),
            Container(
              padding: EdgeInsets.all(
                Responsive.space(context, size: Space.medium),
              ),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(
                  Responsive.space(context, size: Space.large),
                ),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: Colors.grey[600],
                    size: Responsive.space(context, size: Space.medium),
                  ),
                  SizedBox(
                    width: Responsive.space(context, size: Space.medium),
                  ),
                  Text(
                    fullFormattedDate,
                    style: TextStyle(
                      fontSize: Responsive.text(context, size: TextSize.medium),
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
            SizedBox(height: Responsive.space(context, size: Space.medium)),

            // Description section
            UnifiedSectionHeader(title: 'وصف المهمة', icon: Icons.description),
            Container(
              padding: EdgeInsets.all(
                Responsive.space(context, size: Space.medium),
              ),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(
                  Responsive.space(context, size: Space.large),
                ),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                task.description,
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.medium),
                  color: Colors.black87,
                  height: 1.5,
                ),
                textAlign: TextAlign.right,
              ),
            ),

            // Attachments Section
            if (task.attachments != null && task.attachments!.isNotEmpty) ...[
              SizedBox(height: Responsive.space(context, size: Space.medium)),
              UnifiedSectionHeader(title: 'المرفقات', icon: Icons.attach_file),
              ...task.attachments!.map((attachment) {
                return Container(
                  margin: EdgeInsets.only(
                    bottom: Responsive.space(context, size: Space.small),
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
                    onTap: () async {
                      final url = attachment['url'];
                      if (url != null) {
                        try {
                          final uri = Uri.parse(url);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('تعذر فتح الملف'),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      Responsive.space(
                                        context,
                                        size: Space.large,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('خطأ في فتح الملف: $e'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    Responsive.space(
                                      context,
                                      size: Space.large,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                        }
                      }
                    },
                    child: Padding(
                      padding: EdgeInsets.all(
                        Responsive.space(context, size: Space.medium),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(
                            Icons.open_in_new,
                            color: headerColor,
                            size: Responsive.space(context, size: Space.medium),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  attachment['title'] ?? 'ملف مرفق',
                                  style: TextStyle(
                                    fontSize: Responsive.text(
                                      context,
                                      size: TextSize.medium,
                                    ),
                                    fontWeight: FontWeight.w500,
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
                                  'اضغط لفتح الملف',
                                  style: TextStyle(
                                    fontSize: Responsive.text(
                                      context,
                                      size: TextSize.small,
                                    ),
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.attach_file,
                            color: headerColor,
                            size: Responsive.space(context, size: Space.medium),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
      onCancel: () => Navigator.of(context).pop(),
    );
  }

  Color _getImportanceColor(TaskImportance importance) {
    switch (importance) {
      case TaskImportance.high:
        return Colors.red.shade300;
      case TaskImportance.mid:
        return Colors.amber.shade400;
      case TaskImportance.low:
        return Colors.green.shade300;
    }
  }

  String _getImportanceText(TaskImportance importance) {
    switch (importance) {
      case TaskImportance.high:
        return 'عالية';
      case TaskImportance.mid:
        return 'متوسطة';
      case TaskImportance.low:
        return 'منخفضة';
    }
  }
}
