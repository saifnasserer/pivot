import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';
import 'package:intl/intl.dart';

class AdvancedOptionsStep extends StatefulWidget {
  final bool isDraft;
  final bool isPinned;
  final DateTime? publishAt;
  final DateTime? expireAt;
  final ValueChanged<bool> onDraftChanged;
  final ValueChanged<bool> onPinnedChanged;
  final ValueChanged<DateTime?> onPublishAtChanged;
  final ValueChanged<DateTime?> onExpireAtChanged;
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;

  const AdvancedOptionsStep({
    super.key,
    required this.isDraft,
    required this.isPinned,
    required this.publishAt,
    required this.expireAt,
    required this.onDraftChanged,
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
            ),
            SizedBox(height: Responsive.space(context, size: Space.small)),
            Text(
              'تحكم في وقت النشر وحالة الإعلان',
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.medium),
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: Responsive.space(context, size: Space.large)),

            // Publishing Options Section
            _buildSectionCard(
              context,
              title: 'حالة النشر',
              icon: Icons.publish,
              iconColor: Colors.blue,
              children: [
                // Draft Toggle
                _buildToggleTile(
                  context,
                  title: 'حفظ كمسودة',
                  subtitle: 'لن يتم نشر الإعلان ولن يراه المستخدمون',
                  icon: Icons.drafts,
                  value: widget.isDraft,
                  onChanged: (value) {
                    widget.onDraftChanged(value);
                    // If draft is enabled, clear schedule
                    if (value && widget.publishAt != null) {
                      widget.onPublishAtChanged(null);
                    }
                  },
                ),
                Divider(height: 1, color: Colors.grey[200]),

                // Pinned Toggle
                _buildToggleTile(
                  context,
                  title: 'تثبيت الإعلان',
                  subtitle: 'سيظهر الإعلان في أعلى القائمة',
                  icon: Icons.push_pin,
                  value: widget.isPinned,
                  onChanged: widget.onPinnedChanged,
                ),
              ],
            ),

            SizedBox(height: Responsive.space(context, size: Space.large)),

            // Scheduling Section
            if (!widget.isDraft) ...[
              _buildSectionCard(
                context,
                title: 'جدولة النشر',
                icon: Icons.schedule,
                iconColor: Colors.orange,
                children: [
                  // Publish At
                  _buildDateTimeTile(
                    context,
                    title: 'تاريخ النشر',
                    subtitle:
                        widget.publishAt == null
                            ? 'نشر فوري (الآن)'
                            : DateFormat(
                              'yyyy-MM-dd HH:mm',
                              'ar',
                            ).format(widget.publishAt!),
                    icon: Icons.calendar_today,
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
                              'yyyy-MM-dd HH:mm',
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
              SizedBox(height: Responsive.space(context, size: Space.medium)),
              Container(
                padding: Responsive.padding(context, size: Space.medium),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[100]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    SizedBox(
                      width: Responsive.space(context, size: Space.small),
                    ),
                    Expanded(
                      child: Text(
                        _getInfoMessage(),
                        style: TextStyle(
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.small,
                          ),
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Draft info box
            if (widget.isDraft) ...[
              Container(
                padding: Responsive.padding(context, size: Space.medium),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[100]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      color: Colors.orange[700],
                      size: 20,
                    ),
                    SizedBox(
                      width: Responsive.space(context, size: Space.small),
                    ),
                    Expanded(
                      child: Text(
                        'المسودات لن تظهر للمستخدمين ولن يتم إرسال إشعارات عنها',
                        style: TextStyle(
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.small,
                          ),
                          color: Colors.orange[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getInfoMessage() {
    if (widget.publishAt != null && widget.publishAt!.isAfter(DateTime.now())) {
      return 'الإعلان مجدول للنشر. لن يظهر للمستخدمين حتى ${DateFormat('yyyy-MM-dd HH:mm', 'ar').format(widget.publishAt!)}';
    }
    if (widget.expireAt != null) {
      return 'سيتم إخفاء الإعلان تلقائياً بعد ${DateFormat('yyyy-MM-dd HH:mm', 'ar').format(widget.expireAt!)}';
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
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
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                SizedBox(width: Responsive.space(context, size: Space.small)),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.medium),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          ...children,
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
    return ListTile(
      leading: Icon(icon, color: value ? Colors.green : Colors.grey),
      title: Text(
        title,
        style: TextStyle(
          fontSize: Responsive.text(context, size: TextSize.medium),
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: Responsive.text(context, size: TextSize.small),
          color: Colors.grey[600],
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.green,
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
    return ListTile(
      leading: Icon(icon, color: dateTime != null ? Colors.blue : Colors.grey),
      title: Text(
        title,
        style: TextStyle(
          fontSize: Responsive.text(context, size: TextSize.medium),
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: Responsive.text(context, size: TextSize.small),
          color: dateTime != null ? Colors.blue[700] : Colors.grey[600],
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dateTime != null)
            IconButton(
              icon: const Icon(Icons.clear, size: 20),
              color: Colors.red,
              onPressed: onClear,
            ),
          IconButton(
            icon: const Icon(Icons.edit_calendar),
            color: Colors.blue,
            onPressed: onSelect,
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
      locale: const Locale('ar'),
    );

    if (selectedDate == null) return;

    if (!mounted) return;

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
      locale: const Locale('ar'),
    );

    if (selectedDate == null) return;

    if (!mounted) return;

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
