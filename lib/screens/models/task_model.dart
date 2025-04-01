import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'task.dart'; // Import the Task data model

class TaskModel extends StatelessWidget {
  final Task task;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onStatusChanged;
  bool admin;

  TaskModel({
    super.key,
    required this.task,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChanged,
    this.admin = false,
  });

  // Helper to get color based on importance
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

  @override
  Widget build(BuildContext context) {
    // Format date and day of the week in Arabic
    final String formattedDayOfWeek = DateFormat(
      'EEEE',
      'ar',
    ).format(task.dueDate);
    final String formattedDate = DateFormat(
      'dd MMM',
      'ar',
    ).format(task.dueDate);
    final String fullFormattedDate = '$formattedDayOfWeek، $formattedDate';
    final Color importanceColor = _getImportanceColor(task.importance);

    // Compute contrasting text color based on completion status
    final Color textColor = task.isCompleted ? Colors.grey : Colors.black87;
    final Color primaryColor = task.isCompleted ? Colors.grey : importanceColor;
    final IconData checkboxIcon =
        task.isCompleted
            ? Icons.check_box_rounded
            : Icons.check_box_outline_blank_rounded;

    return Padding(
      padding: EdgeInsets.only(
        top: Responsive.space(context, size: Space.medium),
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: primaryColor,
            width: 1.5,
          ), // Slightly thinner border
        ),
        child: Padding(
          padding: EdgeInsets.all(Responsive.space(context, size: Space.large)),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start, // Align content to start
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end, // Space out elements
                children: [
                  Expanded(
                    child: AutoSizeText(
                      task.title,
                      minFontSize: 12,
                      textAlign: TextAlign.end,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        decoration:
                            task.isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                        fontSize:
                            Responsive.text(context, size: TextSize.medium) *
                            1.1,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                  ),
                  SizedBox(width: Responsive.space(context, size: Space.small)),
                  // Checkbox
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor,
                    ),
                    child: IconButton(
                      onPressed: () {
                        onStatusChanged(!task.isCompleted);
                      },
                      icon: Icon(checkboxIcon, color: Colors.white),
                      tooltip:
                          task.isCompleted
                              ? 'Mark as incomplete'
                              : 'Mark as complete',
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.only(
                    right: Responsive.space(context, size: Space.large) * 2.0,
                    top: Responsive.space(context, size: Space.small),
                  ),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.space(context, size: Space.small),
                      vertical:
                          Responsive.space(context, size: Space.small) * 0.5,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'اخر معاد للتسليم : $fullFormattedDate', // Use combined date and day
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.small,
                        ),
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: Responsive.space(context, size: Space.medium) * .5,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: EdgeInsets.all(
                    Responsive.space(context, size: Space.medium),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    task.description.isNotEmpty
                        ? task.description
                        : 'مفيش تفاصيل', // Use task description
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize:
                          Responsive.text(context, size: TextSize.medium) * 0.9,
                      color: textColor,
                      // height: Responsive.space(context, size: Space.tiny) * .5,
                    ),
                  ),
                ),
              ),
              // SizedBox(height: Responsive.space(context, size: Space.medium)),
              // Edit and Delete Buttons
              admin
                  ? Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.edit_outlined,
                          color: Colors.blueGrey,
                          size: Responsive.text(context) * 1.2,
                        ),
                        onPressed: onEdit,
                        tooltip: 'تعديل التاسك',
                      ),
                      SizedBox(
                        width: Responsive.space(context, size: Space.small),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                          size: Responsive.text(context) * 1.2,
                        ),
                        onPressed: onDelete,
                        tooltip: 'امسح التاسك',
                      ),
                    ],
                  )
                  : SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}
