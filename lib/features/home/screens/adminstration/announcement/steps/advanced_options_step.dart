import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:intl/intl.dart';

class AdvancedOptionsStep extends StatelessWidget {
  final bool isPinned;
  final DateTime? publishAt;
  final DateTime? expireAt;
  final ValueChanged<bool> onPinnedChanged;
  final ValueChanged<DateTime?> onPublishAtChanged;
  final ValueChanged<DateTime?> onExpireAtChanged;
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;

  const AdvancedOptionsStep({
    super.key,
    required this.isPinned,
    required this.publishAt,
    required this.expireAt,
    required this.onPinnedChanged,
    required this.onPublishAtChanged,
    required this.onExpireAtChanged,
    required this.fadeAnimation,
    required this.slideAnimation,
  });

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
                      // Header (matching other steps pattern)
                      Container(
                        padding: Responsive.padding(context, size: Space.large),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.purple[400]!,
                              Colors.deepPurple[400]!,
                            ],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          ),
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
                                    'خيارات متقدمة',
                                    style: TextStyle(
                                      fontSize:
                                          Responsive.text(
                                            context,
                                            size: TextSize.heading,
                                          ) *
                                          1.2,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                  Text(
                                    'تحكم في وقت النشر وحالة الإعلان',
                                    style: TextStyle(
                                      fontSize: Responsive.text(
                                        context,
                                        size: TextSize.medium,
                                      ),
                                      color: Colors.white.withOpacity(0.9),
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
                              Icons.tune,
                              color: Colors.white,
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

                      // Pinned Toggle
                      _buildToggleCard(
                        context,
                        title: 'تثبيت الإعلان',
                        subtitle: 'سيظهر الإعلان في أعلى القائمة دائماً',
                        icon: Icons.push_pin,
                        value: isPinned,
                        onChanged: onPinnedChanged,
                      ),

                      SizedBox(
                        height: Responsive.space(context, size: Space.large),
                      ),

                      // Publish Date
                      _buildDateCard(
                        context,
                        title: 'تاريخ النشر',
                        subtitle:
                            publishAt == null
                                ? 'نشر فوري (الآن)'
                                : DateFormat(
                                  'yyyy-MM-dd - hh:mm a',
                                ).format(publishAt!),
                        icon: Icons.publish,
                        iconColor: Colors.blue,
                        dateTime: publishAt,
                        onClear: () => onPublishAtChanged(null),
                        onSelect: () => _selectPublishDate(context),
                      ),

                      SizedBox(
                        height: Responsive.space(context, size: Space.medium),
                      ),

                      // Expire Date
                      _buildDateCard(
                        context,
                        title: 'تاريخ الانتهاء',
                        subtitle:
                            expireAt == null
                                ? 'بدون تاريخ انتهاء'
                                : DateFormat(
                                  'yyyy-MM-dd - hh:mm a',
                                ).format(expireAt!),
                        icon: Icons.event_busy,
                        iconColor: Colors.red,
                        dateTime: expireAt,
                        onClear: () => onExpireAtChanged(null),
                        onSelect: () => _selectExpireDate(context),
                      ),

                      // Info box
                      SizedBox(
                        height: Responsive.space(context, size: Space.large),
                      ),
                      Container(
                        padding: Responsive.padding(context, size: Space.large),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue[50]!, Colors.green[50]!],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          ),
                          borderRadius: BorderRadius.circular(
                            Responsive.space(context, size: Space.large),
                          ),
                          border: Border.all(
                            color: Colors.blue[200]!,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _getInfoMessage(),
                                style: TextStyle(
                                  fontSize: Responsive.text(
                                    context,
                                    size: TextSize.medium,
                                  ),
                                  color: Colors.blue[900],
                                  fontWeight: FontWeight.w600,
                                  height: 1.5,
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
                              color: Colors.blue[700],
                              size: 28,
                            ),
                          ],
                        ),
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

  String _getInfoMessage() {
    final now = DateTime.now();
    final isScheduled = publishAt != null && publishAt!.isAfter(now);
    final hasExpiry = expireAt != null;

    if (isScheduled && hasExpiry && isPinned) {
      return '📌 إعلان مثبت مجدول: سيُنشر في ${DateFormat('yyyy-MM-dd HH:mm').format(publishAt!)} وينتهي في ${DateFormat('yyyy-MM-dd HH:mm').format(expireAt!)}';
    }
    if (isScheduled && hasExpiry) {
      return 'إعلان مجدول: سيُنشر في ${DateFormat('yyyy-MM-dd HH:mm').format(publishAt!)} وينتهي في ${DateFormat('yyyy-MM-dd HH:mm').format(expireAt!)}';
    }
    if (isScheduled && isPinned) {
      return '📌 إعلان مثبت مجدول: سيُنشر في ${DateFormat('yyyy-MM-dd HH:mm').format(publishAt!)} ويبقى مثبتاً';
    }
    if (isScheduled) {
      return 'الإعلان مجدول: لن يظهر للمستخدمين حتى ${DateFormat('yyyy-MM-dd HH:mm').format(publishAt!)}';
    }
    if (hasExpiry && isPinned) {
      return '📌 إعلان مثبت: سيُنشر فوراً وينتهي تلقائياً في ${DateFormat('yyyy-MM-dd HH:mm').format(expireAt!)}';
    }
    if (hasExpiry) {
      return 'سيُنشر فوراً ويُحذف تلقائياً بعد ${DateFormat('yyyy-MM-dd HH:mm').format(expireAt!)}';
    }
    if (isPinned) {
      return '📌 إعلان مثبت: سيُنشر فوراً ويظهر في أعلى القائمة دائماً';
    }
    return 'الإعلان سيُنشر فوراً ويظل مرئياً بدون حد زمني';
  }

  Widget _buildToggleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(
        Responsive.space(context, size: Space.large),
      ),
      child: Container(
        padding: Responsive.padding(context, size: Space.large),
        decoration: BoxDecoration(
          gradient:
              value
                  ? LinearGradient(
                    colors: [Colors.orange[50]!, Colors.deepOrange[50]!],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  )
                  : null,
          color: value ? null : Colors.grey[50],
          borderRadius: BorderRadius.circular(
            Responsive.space(context, size: Space.large),
          ),
          border: Border.all(
            color: value ? Colors.orange[300]! : Colors.grey[200]!,
            width: value ? 2.5 : 1.5,
          ),
        ),
        child: Row(
          children: [
            // Checkbox indicator on the right (RTL)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient:
                    value
                        ? LinearGradient(
                          colors: [
                            Colors.orange[400]!,
                            Colors.deepOrange[500]!,
                          ],
                        )
                        : null,
                color: value ? null : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: value ? Colors.orange[600]! : Colors.grey[300]!,
                  width: 2,
                ),
                boxShadow:
                    value
                        ? [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ]
                        : null,
              ),
              child:
                  value
                      ? Icon(Icons.check, color: Colors.white, size: 20)
                      : null,
            ),
            SizedBox(width: Responsive.space(context, size: Space.medium)),
            Icon(
              icon,
              color: value ? Colors.orange[700] : Colors.grey[400],
              size: 32,
            ),
            SizedBox(width: Responsive.space(context, size: Space.medium)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: Responsive.text(context, size: TextSize.medium),
                      fontWeight: FontWeight.bold,
                      color: value ? Colors.orange[900] : Colors.black87,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  SizedBox(height: Responsive.space(context, size: Space.tiny)),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: Responsive.text(context, size: TextSize.small),
                      color: value ? Colors.orange[700] : Colors.grey[600],
                    ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required DateTime? dateTime,
    required VoidCallback onClear,
    required VoidCallback onSelect,
  }) {
    return Container(
      padding: Responsive.padding(context, size: Space.large),
      decoration: BoxDecoration(
        color: dateTime != null ? iconColor.withOpacity(0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.large),
        ),
        border: Border.all(
          color:
              dateTime != null ? iconColor.withOpacity(0.3) : Colors.grey[200]!,
          width: dateTime != null ? 2 : 1.5,
        ),
      ),
      child: Row(
        children: [
          // Action buttons on the right (RTL)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: const Icon(Icons.edit_calendar, size: 22),
                  color: iconColor,
                  onPressed: onSelect,
                  tooltip: 'تحديد التاريخ',
                ),
              ),
              if (dateTime != null) ...[
                SizedBox(width: Responsive.space(context, size: Space.tiny)),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.clear, size: 22),
                    color: Colors.red[700],
                    onPressed: onClear,
                    tooltip: 'إزالة التاريخ',
                  ),
                ),
              ],
            ],
          ),
          SizedBox(width: Responsive.space(context, size: Space.medium)),
          // Icon
          // Container(
          //   padding: EdgeInsets.all(
          //     Responsive.space(context, size: Space.small),
          //   ),
          //   decoration: BoxDecoration(
          //     color:
          //         dateTime != null
          //             ? iconColor.withOpacity(0.15)
          //             : Colors.grey[200],
          //     borderRadius: BorderRadius.circular(12),
          //   ),
          //   child: Icon(
          //     icon,
          //     color: dateTime != null ? iconColor : Colors.grey[400],
          //     size: 28,
          //   ),
          // ),
          // SizedBox(width: Responsive.space(context, size: Space.medium)),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.medium),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.right,
                ),
                SizedBox(height: Responsive.space(context, size: Space.tiny)),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.small),
                    color: dateTime != null ? iconColor : Colors.grey[600],
                    fontWeight:
                        dateTime != null ? FontWeight.w600 : FontWeight.normal,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectPublishDate(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = publishAt ?? now;

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(now) ? now : initialDate,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );

    if (selectedDate == null) return;

    if (!context.mounted) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );

    if (selectedTime == null) return;

    final finalDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    // Validation: publishAt must be after now
    if (finalDateTime.isBefore(DateTime.now())) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب أن يكون تاريخ النشر في المستقبل'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validation: publishAt must be before expireAt
    if (expireAt != null && finalDateTime.isAfter(expireAt!)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب أن يكون تاريخ النشر قبل تاريخ الانتهاء'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    onPublishAtChanged(finalDateTime);
  }

  Future<void> _selectExpireDate(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = expireAt ?? now.add(const Duration(days: 7));

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(now) ? now : initialDate,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );

    if (selectedDate == null) return;

    if (!context.mounted) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );

    if (selectedTime == null) return;

    final finalDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    // Validation: expireAt must be after now
    if (finalDateTime.isBefore(DateTime.now())) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب أن يكون تاريخ الانتهاء في المستقبل'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validation: expireAt must be after publishAt
    final publishDate = publishAt ?? DateTime.now();
    if (finalDateTime.isBefore(publishDate)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب أن يكون تاريخ الانتهاء بعد تاريخ النشر'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    onExpireAtChanged(finalDateTime);
  }
}
