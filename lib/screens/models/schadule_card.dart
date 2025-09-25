import 'package:flutter/material.dart';
import 'package:pivot/screens/models/schedule_item.dart';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:pivot/responsive.dart';

class SchaduleCard extends StatelessWidget {
  final ScheduleItem item;
  final VoidCallback handleDelete;
  final VoidCallback? onNotificationToggle;
  final VoidCallback? onEditItem;
  final Widget? trailingWidget;

  const SchaduleCard({
    super.key,
    required this.item,
    required this.handleDelete,
    this.onNotificationToggle,
    this.onEditItem,
    this.trailingWidget,
  });

  @override
  Widget build(BuildContext context) {
    final Color cardColor =
        item.type == ScheduleItemType.lecture
            ? Colors.blue.shade50
            : Colors.orange.shade50;

    return Container(
      margin: EdgeInsets.only(
        bottom: Responsive.space(context, size: Space.small),
      ),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.medium),
        ),
        gradient: LinearGradient(
          colors: [cardColor, cardColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color:
              item.type == ScheduleItemType.lecture
                  ? Colors.blue.shade200
                  : Colors.orange.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(Responsive.space(context, size: Space.medium)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header row with title and action buttons
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Action menu (left side)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Add trailing widget if provided (like drag handle)
                    if (trailingWidget != null) ...[
                      trailingWidget!,
                      SizedBox(
                        width: Responsive.space(context, size: Space.small),
                      ),
                    ],
                    // Three dots menu button
                    _buildThreeDotsMenu(context),
                  ],
                ),
                SizedBox(width: Responsive.space(context, size: Space.medium)),
                // Title (right side)
                Expanded(
                  child: AutoSizeText(
                    item.title,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: Responsive.text(context, size: TextSize.medium),
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    minFontSize:
                        Responsive.text(
                          context,
                          size: TextSize.small,
                        ).floorToDouble(),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: Responsive.space(context, size: Space.medium)),
            // Details row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Location
                Flexible(
                  flex: 1,
                  child: _buildDetailItem(
                    context,
                    Icons.location_on_outlined,
                    item.location,
                    Colors.grey.shade600,
                  ),
                ),
                SizedBox(width: Responsive.space(context, size: Space.medium)),
                // Time
                Flexible(
                  flex: 1,
                  child: _buildDetailItem(
                    context,
                    Icons.access_time_outlined,
                    item.time,
                    Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds three dots menu button that opens action sheet
  Widget _buildThreeDotsMenu(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showActionMenu(context),
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.small),
        ),
        child: Container(
          padding: EdgeInsets.all(Responsive.space(context, size: Space.small)),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(
              Responsive.space(context, size: Space.small),
            ),
            border: Border.all(color: Colors.grey.shade300, width: 0.5),
          ),
          child: Icon(
            Icons.more_vert,
            size: Responsive.text(context, size: TextSize.small) * 1.2,
            color: Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  /// Shows action menu with edit, notification toggle, and delete options
  void _showActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            margin: EdgeInsets.all(
              Responsive.space(context, size: Space.medium),
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                Responsive.space(context, size: Space.medium),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(
                    Responsive.space(context, size: Space.medium),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(
                        Responsive.space(context, size: Space.medium),
                      ),
                      topRight: Radius.circular(
                        Responsive.space(context, size: Space.medium),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(
                          Responsive.space(context, size: Space.small),
                        ),
                        decoration: BoxDecoration(
                          color:
                              item.type == ScheduleItemType.lecture
                                  ? Colors.blue.shade100
                                  : Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(
                            Responsive.space(context, size: Space.small),
                          ),
                        ),
                        child: Icon(
                          item.type == ScheduleItemType.lecture
                              ? Icons.menu_book_rounded
                              : Icons.groups_rounded,
                          color:
                              item.type == ScheduleItemType.lecture
                                  ? Colors.blue.shade700
                                  : Colors.orange.shade700,
                          size:
                              Responsive.text(context, size: TextSize.small) *
                              1.2,
                        ),
                      ),
                      SizedBox(
                        width: Responsive.space(context, size: Space.small),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: TextStyle(
                                fontSize: Responsive.text(
                                  context,
                                  size: TextSize.medium,
                                ),
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(
                              height:
                                  Responsive.space(context, size: Space.small) *
                                  0.5,
                            ),
                            Text(
                              '${item.time} • ${item.location}',
                              style: TextStyle(
                                fontSize: Responsive.text(
                                  context,
                                  size: TextSize.small,
                                ),
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Action items
                if (onEditItem != null)
                  _buildActionMenuItem(
                    context,
                    Icons.edit_outlined,
                    'تعديل',
                    Colors.blue.shade600,
                    onEditItem!,
                  ),
                if (onNotificationToggle != null)
                  _buildActionMenuItem(
                    context,
                    item.notificationEnabled
                        ? Icons.notifications_active
                        : Icons.notifications_off,
                    item.notificationEnabled
                        ? 'إيقاف الإشعارات'
                        : 'تفعيل الإشعارات',
                    item.notificationEnabled
                        ? Colors.green.shade600
                        : Colors.grey.shade600,
                    onNotificationToggle!,
                  ),
                _buildActionMenuItem(
                  context,
                  Icons.delete_outline_rounded,
                  'حذف',
                  Colors.red.shade600,
                  handleDelete,
                  isDestructive: true,
                ),
                // Cancel button
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(
                    Responsive.space(context, size: Space.medium),
                  ),
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'إلغاء',
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.medium,
                        ),
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds individual action menu item
  Widget _buildActionMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop();
          onTap();
        },
        child: Container(
          padding: EdgeInsets.all(
            Responsive.space(context, size: Space.medium),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(
                  Responsive.space(context, size: Space.small),
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    Responsive.space(context, size: Space.small),
                  ),
                ),
                child: Icon(
                  icon,
                  size: Responsive.text(context, size: TextSize.small) * 1.2,
                  color: color,
                ),
              ),
              SizedBox(width: Responsive.space(context, size: Space.medium)),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.medium),
                    color: isDestructive ? Colors.red.shade700 : Colors.black87,
                    fontWeight:
                        isDestructive ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_back_ios,
                size: Responsive.text(context, size: TextSize.small),
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds detail item with icon and text
  Widget _buildDetailItem(
    BuildContext context,
    IconData icon,
    String text,
    Color color,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: Responsive.text(context, size: TextSize.small) * 1.1,
          color: color,
        ),
        SizedBox(width: Responsive.space(context, size: Space.small) * 0.5),
        Flexible(
          child: AutoSizeText(
            text,
            style: TextStyle(
              color: color,
              fontSize: Responsive.text(context, size: TextSize.small),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            minFontSize:
                (Responsive.text(context, size: TextSize.small) * 0.8)
                    .floorToDouble(),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
