import 'package:flutter/material.dart';
import 'package:pivot/screens/models/schedule_item.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/services/permission_service.dart';
import 'package:pivot/services/notification_service.dart';
import 'package:auto_size_text/auto_size_text.dart';

class SchaduleCard extends StatelessWidget {
  final ScheduleItem item;
  final VoidCallback handleDelete;
  final VoidCallback? onNotificationToggle;

  const SchaduleCard({
    super.key,
    required this.item,
    required this.handleDelete,
    this.onNotificationToggle,
  });

  @override
  Widget build(BuildContext context) {
    final Color cardColor =
        item.type == ScheduleItemType.lecture
            ? Colors.blue.shade50
            : Colors.orange.shade50;
    final IconData typeIcon =
        item.type == ScheduleItemType.lecture
            ? Icons.menu_book_rounded
            : Icons.groups_rounded;

    return Container(
      margin: EdgeInsets.only(bottom: Responsive.space(context)),
      padding: EdgeInsets.all(Responsive.space(context)),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Responsive.space(context) * 0.8),
        color: cardColor,
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(
                typeIcon,
                size: Responsive.text(context) * 1.1,
                color:
                    item.type == ScheduleItemType.lecture
                        ? Colors.blue.shade700
                        : Colors.orange.shade700,
              ),
              SizedBox(width: Responsive.space(context) * 0.5),
              if (onNotificationToggle != null)
                IconButton(
                  icon: Icon(
                    item.notificationEnabled
                        ? Icons.notifications_active
                        : Icons.notifications_off,
                    color:
                        item.notificationEnabled
                            ? Colors.green.shade600
                            : Colors.grey.shade500,
                  ),
                  iconSize: Responsive.text(context) * 1.1,
                  onPressed: () async {
                    final hasPermission =
                        await NotificationService().areNotificationsEnabled();
                    if (!hasPermission) {
                      await PermissionService.showNotificationPermissionDialog(
                        context,
                      );
                      return;
                    }
                    onNotificationToggle!();
                  },
                  tooltip:
                      item.notificationEnabled
                          ? 'إيقاف الإشعارات'
                          : 'تفعيل الإشعارات',
                ),
              SizedBox(width: Responsive.space(context) * 0.5),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded),
                iconSize: Responsive.text(context) * 1.1,
                onPressed: () {
                  handleDelete();
                },
              ),
              SizedBox(width: Responsive.space(context) * 0.5),
              Expanded(
                child: AutoSizeText(
                  (item.type == ScheduleItemType.section
                          ? 'سكشن '
                          : 'محاضرة ') +
                      item.title,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: Responsive.text(context) * 1.1,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  minFontSize: Responsive.text(context, size: TextSize.small),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.space(context) * 0.75),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                item.location,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: Responsive.text(context) * 0.95,
                ),
              ),
              SizedBox(width: Responsive.space(context) * 0.3),
              Icon(
                Icons.location_on_outlined,
                size: Responsive.text(context),
                color: Colors.black54,
              ),
              SizedBox(width: Responsive.space(context)),
              Text(
                item.time,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: Responsive.text(context) * 0.95,
                ),
              ),
              SizedBox(width: Responsive.space(context) * 0.3),
              Icon(
                Icons.access_time_outlined,
                size: Responsive.text(context),
                color: Colors.black54,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
