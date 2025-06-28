import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/models/task.dart';
import 'package:pivot/screens/models/card_model.dart';
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

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, size: Space.medium),
        vertical: Responsive.space(context, size: Space.large),
      ),
      child: Stack(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with color and icon
                Container(
                  decoration: BoxDecoration(
                    color: headerColor.withOpacity(0.13),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.space(context, size: Space.large),
                    vertical: Responsive.space(context, size: Space.medium),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.task_alt, color: headerColor, size: 28),
                      SizedBox(
                        width: Responsive.space(context, size: Space.small),
                      ),
                      Expanded(
                        child: Text(
                          task.title,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize:
                                Responsive.text(
                                  context,
                                  size: TextSize.heading,
                                ) *
                                1.1,
                            fontWeight: FontWeight.bold,
                            color: Colors.black.withOpacity(0.9),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.space(context, size: Space.large),
                    vertical: Responsive.space(context, size: Space.medium),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: Colors.grey[600],
                          ),
                          SizedBox(
                            width: Responsive.space(context, size: Space.tiny),
                          ),
                          Text(
                            fullFormattedDate,
                            style: TextStyle(
                              fontSize: Responsive.text(
                                context,
                                size: TextSize.small,
                              ),
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.small),
                      ),
                      Divider(thickness: 1, color: Colors.grey[200]),
                      SizedBox(
                        height: Responsive.space(context, size: Space.small),
                      ),
                      Text(
                        task.description,
                        style: TextStyle(
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.medium,
                          ),
                          color: Colors.black.withOpacity(0.85),
                        ),
                        textAlign: TextAlign.right,
                      ),
                      // Attachments Section
                      if (task.attachments != null &&
                          task.attachments!.isNotEmpty) ...[
                        SizedBox(
                          height: Responsive.space(context, size: Space.medium),
                        ),
                        Divider(thickness: 1, color: Colors.grey[200]),
                        SizedBox(
                          height: Responsive.space(context, size: Space.small),
                        ),
                        Text(
                          'المرفقات:',
                          style: TextStyle(
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.medium,
                            ),
                            fontWeight: FontWeight.bold,
                            color: Colors.black.withOpacity(0.8),
                          ),
                          textAlign: TextAlign.right,
                        ),
                        SizedBox(
                          height: Responsive.space(context, size: Space.small),
                        ),
                        ...task.attachments!.map((attachment) {
                          return Container(
                            margin: EdgeInsets.only(
                              bottom: Responsive.space(
                                context,
                                size: Space.small,
                              ),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(
                                Responsive.space(context, size: Space.large),
                              ),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: ListTile(
                              leading: Icon(
                                Icons.attach_file,
                                color: headerColor,
                                size: 24,
                              ),
                              title: Text(
                                attachment['title'] ?? 'ملف مرفق',
                                style: TextStyle(
                                  fontSize: Responsive.text(
                                    context,
                                    size: TextSize.medium,
                                  ),
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black.withOpacity(0.8),
                                ),
                                textAlign: TextAlign.right,
                              ),
                              subtitle: Text(
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
                              trailing: Icon(
                                Icons.open_in_new,
                                color: headerColor,
                                size: 20,
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
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text('تعذر فتح الملف'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('خطأ في فتح الملف: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: Responsive.space(context, size: Space.small)),
              ],
            ),
          ),
          // Floating close button
          Positioned(
            top: 8,
            right: 8,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 2,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.black87),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
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
}
