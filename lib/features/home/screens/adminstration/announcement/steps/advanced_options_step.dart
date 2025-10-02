import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:intl/intl.dart';

class AdvancedOptionsStep extends StatefulWidget {
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
  State<AdvancedOptionsStep> createState() => _AdvancedOptionsStepState();
}

class _AdvancedOptionsStepState extends State<AdvancedOptionsStep> {
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: widget.fadeAnimation,
      child: SlideTransition(
        position: widget.slideAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'خيارات متقدمة',
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.heading),
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.right,
            ),
            SizedBox(height: Responsive.space(context, size: Space.small)),
            Text(
              'تحكم في وقت النشر وحالة الإعلان',
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.medium),
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.right,
            ),
            SizedBox(height: Responsive.space(context, size: Space.large)),

            // Pinned Toggle Section
            _buildSectionCard(
              context,
              title: 'التثبيت',
              icon: Icons.push_pin,
              iconColor: Colors.orange,
              children: [
                _buildToggleTile(
                  context,
                  title: 'تثبيت الإعلان',
                  subtitle: 'سيظهر الإعلان في أعلى القائمة دائماً',
                  icon: Icons.push_pin_outlined,
                  value: widget.isPinned,
                  onChanged: widget.onPinnedChanged,
                ),
              ],
            ),

            SizedBox(height: Responsive.space(context, size: Space.large)),

            // Scheduling Section
            _buildSectionCard(
              context,
              title: 'جدولة النشر والانتهاء',
              icon: Icons.schedule,
              iconColor: Colors.blue,
              children: [
                // Publish At
                _buildDateTimeTile(
                  context,
                  title: 'تاريخ النشر',
                  subtitle:
                      widget.publishAt == null
                          ? 'نشر فوري (الآن)'
                          : DateFormat(
                            'yyyy-MM-dd - hh:mm a',
                            'ar',
                          ).format(widget.publishAt!),
                  icon: Icons.publish,
                  dateTime: widget.publishAt,
                  onClear: () => widget.onPublishAtChanged(null),
                  onSelect: () => _selectPublishDate(context),
                ),
                Divider(height: 1, color: Colors.grey[200]),

                // Expire At
                _buildDateTimeTile(
                  context,
                  title: 'تاريخ الانتهاء',
                  subtitle:
                      widget.expireAt == null
                          ? 'بدون تاريخ انتهاء'
                          : DateFormat(
                            'yyyy-MM-dd - hh:mm a',
                            'ar',
                          ).format(widget.expireAt!),
                  icon: Icons.event_busy,
                  dateTime: widget.expireAt,
                  onClear: () => widget.onExpireAtChanged(null),
                  onSelect: () => _selectExpireDate(context),
                ),
              ],
            ),

            // Info box
            SizedBox(height: Responsive.space(context, size: Space.large)),
            Container(
              padding: Responsive.padding(context, size: Space.medium),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[50]!, Colors.green[50]!],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[100]!, width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 24),
                  SizedBox(width: Responsive.space(context, size: Space.small)),
                  Expanded(
                    child: Text(
                      _getInfoMessage(),
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.medium,
                        ),
                        color: Colors.blue[900],
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.right,
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

  String _getInfoMessage() {
    final now = DateTime.now();
    final isScheduled =
        widget.publishAt != null && widget.publishAt!.isAfter(now);
    final hasExpiry = widget.expireAt != null;
    final isPinned = widget.isPinned;

    if (isScheduled && hasExpiry && isPinned) {
      return '📌 إعلان مثبت مجدول: سيُنشر في ${DateFormat('yyyy-MM-dd HH:mm').format(widget.publishAt!)} وينتهي في ${DateFormat('yyyy-MM-dd HH:mm').format(widget.expireAt!)}';
    }
    if (isScheduled && hasExpiry) {
      return 'إعلان مجدول: سيُنشر في ${DateFormat('yyyy-MM-dd HH:mm').format(widget.publishAt!)} وينتهي في ${DateFormat('yyyy-MM-dd HH:mm').format(widget.expireAt!)}';
    }
    if (isScheduled && isPinned) {
      return '📌 إعلان مثبت مجدول: سيُنشر في ${DateFormat('yyyy-MM-dd HH:mm').format(widget.publishAt!)} ويبقى مثبتاً';
    }
    if (isScheduled) {
      return 'الإعلان مجدول: لن يظهر للمستخدمين حتى ${DateFormat('yyyy-MM-dd HH:mm').format(widget.publishAt!)}';
    }
    if (hasExpiry && isPinned) {
      return '📌 إعلان مثبت: سيُنشر فوراً وينتهي تلقائياً في ${DateFormat('yyyy-MM-dd HH:mm').format(widget.expireAt!)}';
    }
    if (hasExpiry) {
      return 'سيُنشر فوراً ويُحذف تلقائياً بعد ${DateFormat('yyyy-MM-dd HH:mm').format(widget.expireAt!)}';
    }
    if (isPinned) {
      return '📌 إعلان مثبت: سيُنشر فوراً ويظهر في أعلى القائمة دائماً';
    }
    return 'الإعلان سيُنشر فوراً ويظل مرئياً بدون حد زمني';
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: Responsive.padding(context, size: Space.medium),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(
                    Responsive.space(context, size: Space.small),
                  ),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                SizedBox(width: Responsive.space(context, size: Space.small)),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: Responsive.text(context, size: TextSize.medium),
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: Responsive.padding(context, size: Space.medium),
        decoration: BoxDecoration(
          color: value ? Colors.orange[50] : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value ? Colors.orange[300]! : Colors.grey[200]!,
            width: value ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Checkbox indicator on the right (RTL)
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: value ? Colors.orange : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: value ? Colors.orange : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child:
                  value
                      ? Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
            ),
            SizedBox(width: Responsive.space(context, size: Space.small)),
            Icon(
              icon,
              color: value ? Colors.orange[700] : Colors.grey[400],
              size: 28,
            ),
            SizedBox(width: Responsive.space(context, size: Space.small)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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

  Widget _buildDateTimeTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required DateTime? dateTime,
    required VoidCallback onClear,
    required VoidCallback onSelect,
  }) {
    return Padding(
      padding: Responsive.padding(context, size: Space.medium),
      child: Row(
        children: [
          // Action buttons on the right (RTL)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.edit_calendar, size: 20),
                  color: Colors.blue[700],
                  onPressed: onSelect,
                  tooltip: 'تحديد التاريخ',
                ),
              ),
              if (dateTime != null) ...[
                SizedBox(width: Responsive.space(context, size: Space.tiny)),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    color: Colors.red[700],
                    onPressed: onClear,
                    tooltip: 'إزالة التاريخ',
                  ),
                ),
              ],
            ],
          ),
          SizedBox(width: Responsive.space(context, size: Space.small)),
          // Icon and text on the left (RTL)
          Icon(
            icon,
            color: dateTime != null ? Colors.blue[700] : Colors.grey[400],
            size: 24,
          ),
          SizedBox(width: Responsive.space(context, size: Space.small)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                    color:
                        dateTime != null ? Colors.blue[700] : Colors.grey[600],
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
    final initialDate = widget.publishAt ?? now;

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(now) ? now : initialDate,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );

    if (selectedDate == null || !mounted) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );

    if (selectedTime == null || !mounted) return;

    final finalDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    // Validation: publishAt must be after now
    if (finalDateTime.isBefore(DateTime.now())) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب أن يكون تاريخ النشر في المستقبل'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validation: publishAt must be before expireAt
    if (widget.expireAt != null && finalDateTime.isAfter(widget.expireAt!)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب أن يكون تاريخ النشر قبل تاريخ الانتهاء'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    widget.onPublishAtChanged(finalDateTime);
  }

  Future<void> _selectExpireDate(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = widget.expireAt ?? now.add(const Duration(days: 7));

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(now) ? now : initialDate,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );

    if (selectedDate == null || !mounted) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );

    if (selectedTime == null || !mounted) return;

    final finalDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    // Validation: expireAt must be after now
    if (finalDateTime.isBefore(DateTime.now())) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب أن يكون تاريخ الانتهاء في المستقبل'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validation: expireAt must be after publishAt
    final publishDate = widget.publishAt ?? DateTime.now();
    if (finalDateTime.isBefore(publishDate)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب أن يكون تاريخ الانتهاء بعد تاريخ النشر'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    widget.onExpireAtChanged(finalDateTime);
  }
}
