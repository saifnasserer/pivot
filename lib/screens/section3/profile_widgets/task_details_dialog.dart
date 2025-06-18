import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/models/task.dart';

class TaskDetailsDialog extends StatelessWidget {
  final Task task;

  const TaskDetailsDialog({Key? key, required this.task}) : super(key: key);

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

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      // elevation: 8,
      title: Text(
        task.title,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: Responsive.text(context, size: TextSize.medium) * 1.2,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              task.description,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.medium),
                color: Colors.black87,
              ),
            ),
            SizedBox(height: Responsive.space(context, size: Space.large)),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  fullFormattedDate,
                  style: TextStyle(
                    fontSize:
                        Responsive.text(context, size: TextSize.small) * 1.1,
                  ),
                ),
                SizedBox(width: Responsive.space(context, size: Space.small)),
                const Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: Colors.blueGrey,
                ),
              ],
            ),
            SizedBox(height: Responsive.space(context, size: Space.medium)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إغلاق'),
        ),
      ],
    );
  }
}
