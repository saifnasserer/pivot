import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pivot/features/home/screens/adminstration/announcement/add_announcement_controller.dart';
import 'package:pivot/responsive.dart';


class SchedulingStep extends StatelessWidget {
  final DateTime? publishAt;
  final DateTime? expireAt;
  final bool isDraft;
  final bool isPinned;
  final Function(DateTime?) onPublishAtChanged;
  final Function(DateTime?) onExpireAtChanged;
  final Function(bool) onDraftChanged;
  final Function(bool) onPinnedChanged;
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;

  const SchedulingStep({
    super.key,
    required this.publishAt,
    required this.expireAt,
    required this.isDraft,
    required this.isPinned,
    required this.onPublishAtChanged,
    required this.onExpireAtChanged,
    required this.onDraftChanged,
    required this.onPinnedChanged,
    required this.fadeAnimation,
    required this.slideAnimation,
  });

  Future<void> _selectDateTime(BuildContext context, bool isPublishDate) async {
    final selectedDateTime = await AddAnnouncementController.selectDateTime(
      context,
      isPublishDate,
      isPublishDate ? publishAt : expireAt,
    );

    if (selectedDateTime != null) {
      if (isPublishDate) {
        onPublishAtChanged(selectedDateTime);
      } else {
        onExpireAtChanged(selectedDateTime);
      }
    }
  }

  Widget _buildDateTimeSelector(
    BuildContext context, {
    required String title,
    required DateTime? value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: Responsive.padding(context, size: Space.large),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(
            Responsive.space(context, size: Space.large),
          ),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            if (value != null)
              IconButton(
                icon: Icon(Icons.clear, size: 24, color: Colors.red[400]),
                onPressed: () {
                  if (title.contains('النشر')) {
                    onPublishAtChanged(null);
                  } else {
                    onExpireAtChanged(null);
                  }
                },
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: Responsive.text(context, size: TextSize.medium),
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.right,
                  ),
                  Text(
                    value != null
                        ? DateFormat('yyyy/MM/dd HH:mm').format(value)
                        : 'غير محدد',
                    style: TextStyle(
                      fontSize: Responsive.text(context, size: TextSize.medium),
                      color: value != null ? color : Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
            SizedBox(width: Responsive.space(context, size: Space.medium)),
            Icon(
              icon,
              color: color,
              size: Responsive.space(context, size: Space.large),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: fadeAnimation,
          child: AnimatedBuilder(
            animation: slideAnimation,
            builder: (context, child) {
              return SlideTransition(
                position: slideAnimation,
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Container(
                        padding: Responsive.padding(context, size: Space.large),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            Responsive.space(context, size: Space.large),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'جدولة النشر',
                                    style: TextStyle(
                                      fontSize:
                                          Responsive.text(
                                            context,
                                            size: TextSize.heading,
                                          ) *
                                          1.2,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange[700],
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                  Text(
                                    'حدد مواعيد النشر والانتهاء (اختياري)',
                                    style: TextStyle(
                                      fontSize: Responsive.text(
                                        context,
                                        size: TextSize.medium,
                                      ),
                                      color: Colors.orange[600],
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: Responsive.space(
                                context,
                                size: Space.medium,
                              ),
                            ),
                            Icon(
                              Icons.schedule,
                              color: Colors.orange[700],
                              size:
                                  Responsive.space(context, size: Space.large) *
                                  1.5,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.large),
                      ),

                      // Publish date
                      _buildDateTimeSelector(
                        context,
                        title: 'تاريخ النشر',
                        value: publishAt,
                        icon: Icons.publish,
                        color: Colors.blue,
                        onTap: () => _selectDateTime(context, true),
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.medium),
                      ),

                      // Expiry date
                      _buildDateTimeSelector(
                        context,
                        title: 'تاريخ الانتهاء',
                        value: expireAt,
                        icon: Icons.event_busy,
                        color: Colors.red,
                        onTap: () => _selectDateTime(context, false),
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.large),
                      ),

                      // Info card
                      Container(
                        padding: Responsive.padding(context, size: Space.large),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(
                            Responsive.space(context, size: Space.large),
                          ),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'إذا لم تحدد مواعيد، سيتم نشر الإعلان فوراً',
                                style: TextStyle(
                                  fontSize: Responsive.text(
                                    context,
                                    size: TextSize.medium,
                                  ),
                                  color: Colors.blue[700],
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            SizedBox(
                              width: Responsive.space(
                                context,
                                size: Space.medium,
                              ),
                            ),
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue[600],
                              size: Responsive.space(
                                context,
                                size: Space.large,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.large),
                      ),

                      // Draft and Pinned options
                      Text(
                        'خيارات الإعلان:',
                        style: TextStyle(
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.heading,
                          ),
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.medium),
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Draft option
                          GestureDetector(
                            onTap: () => onDraftChanged(!isDraft),
                            child: Container(
                              padding: Responsive.padding(
                                context,
                                size: Space.medium,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isDraft
                                        ? Colors.orange.withOpacity(0.1)
                                        : Colors.grey[50],
                                borderRadius: BorderRadius.circular(
                                  Responsive.space(context, size: Space.large),
                                ),
                                border: Border.all(
                                  color:
                                      isDraft
                                          ? Colors.orange
                                          : Colors.grey[300]!,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    isDraft ? Icons.save : Icons.save_outlined,
                                    color:
                                        isDraft
                                            ? Colors.orange[700]
                                            : Colors.grey[600],
                                    size: Responsive.space(
                                      context,
                                      size: Space.large,
                                    ),
                                  ),
                                  SizedBox(
                                    height: Responsive.space(
                                      context,
                                      size: Space.small,
                                    ),
                                  ),
                                  Text(
                                    'مسودة',
                                    style: TextStyle(
                                      fontSize: Responsive.text(
                                        context,
                                        size: TextSize.medium,
                                      ),
                                      fontWeight:
                                          isDraft
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                      color:
                                          isDraft
                                              ? Colors.orange[700]
                                              : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Pinned option
                          GestureDetector(
                            onTap: () => onPinnedChanged(!isPinned),
                            child: Container(
                              padding: Responsive.padding(
                                context,
                                size: Space.medium,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isPinned
                                        ? Colors.red.withOpacity(0.1)
                                        : Colors.grey[50],
                                borderRadius: BorderRadius.circular(
                                  Responsive.space(context, size: Space.large),
                                ),
                                border: Border.all(
                                  color:
                                      isPinned ? Colors.red : Colors.grey[300]!,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    isPinned
                                        ? Icons.push_pin
                                        : Icons.push_pin_outlined,
                                    color:
                                        isPinned
                                            ? Colors.red[700]
                                            : Colors.grey[600],
                                    size: Responsive.space(
                                      context,
                                      size: Space.large,
                                    ),
                                  ),
                                  SizedBox(
                                    height: Responsive.space(
                                      context,
                                      size: Space.small,
                                    ),
                                  ),
                                  Text(
                                    'مثبت',
                                    style: TextStyle(
                                      fontSize: Responsive.text(
                                        context,
                                        size: TextSize.medium,
                                      ),
                                      fontWeight:
                                          isPinned
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                      color:
                                          isPinned
                                              ? Colors.red[700]
                                              : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
