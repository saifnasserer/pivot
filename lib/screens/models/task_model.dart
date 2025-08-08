import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:provider/provider.dart';
import 'package:pivot/screens/section3/profile_widgets/task_details_dialog.dart';
import 'task.dart'; // Import the Task data model

/// Enhanced TaskModel with subtle design using white/black palette
class TaskModel extends StatefulWidget {
  final Task task;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onStatusChanged;
  final bool admin;

  const TaskModel({
    super.key,
    required this.task,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChanged,
    this.admin = false,
  });

  @override
  State<TaskModel> createState() => _TaskModelState();
}

class _TaskModelState extends State<TaskModel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.01).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    // Start entrance animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Helper to get subtle color based on importance
  Color _getImportanceColor(TaskImportance importance) {
    switch (importance) {
      case TaskImportance.high:
        return Colors.red.shade400;
      case TaskImportance.mid:
        return Colors.orange.shade400;
      case TaskImportance.low:
        return Colors.green.shade400;
    }
  }

  // Helper to get importance label in Arabic
  String _getImportanceLabel(TaskImportance importance) {
    switch (importance) {
      case TaskImportance.high:
        return 'عالية';
      case TaskImportance.mid:
        return 'متوسطة';
      case TaskImportance.low:
        return 'منخفضة';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfileProvider = Provider.of<UserProfileProvider>(
      context,
      listen: false,
    );
    final userId = userProfileProvider.userProfile?.id;

    // Determine completion status for the current user
    final bool isCompleted =
        userId != null ? widget.task.isCompletedFor(userId) : false;
    final bool isOverdue =
        !isCompleted && widget.task.dueDate.isBefore(DateTime.now());

    // Format date and day of the week in Arabic
    final String formattedDayOfWeek = DateFormat(
      'EEEE',
      'ar',
    ).format(widget.task.dueDate);
    final String formattedDate = DateFormat(
      'dd MMM',
      'ar',
    ).format(widget.task.dueDate);
    final String fullFormattedDate = '$formattedDayOfWeek، $formattedDate';
    final Color importanceColor = _getImportanceColor(widget.task.importance);

    // Compute colors based on completion status
    final Color textColor = isCompleted ? Colors.grey.shade500 : Colors.black87;
    final Color borderColor =
        isOverdue
            ? Colors.red.shade400
            : (widget.task.isPersonal ? Colors.blue.shade400 : importanceColor);

    final IconData checkboxIcon =
        isCompleted
            ? Icons.check_circle_rounded
            : Icons.radio_button_unchecked_rounded;

    // Reduce size for completed tasks
    final double cardPadding =
        isCompleted
            ? Responsive.space(context, size: Space.medium)
            : Responsive.space(context, size: Space.large);
    final double titleFontSize =
        isCompleted
            ? Responsive.text(context, size: TextSize.small)
            : Responsive.text(context, size: TextSize.medium) * 1.1;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.space(context, size: Space.tiny),
                vertical: Responsive.space(context, size: Space.small),
              ),
              child: Material(
                elevation: _isHovered ? 6 : 2,
                borderRadius: BorderRadius.circular(
                  Responsive.space(context, size: Space.large),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(
                    Responsive.space(context, size: Space.large),
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => TaskDetailsDialog(task: widget.task),
                    );
                  },
                  onHover: (hovered) {
                    setState(() {
                      _isHovered = hovered;
                    });
                    if (hovered) {
                      _animationController.forward();
                    } else {
                      _animationController.reverse();
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color:
                          isCompleted
                              ? Colors.grey.shade50
                              : _isHovered
                              ? Colors.grey.shade100
                              : Colors.white,
                      borderRadius: BorderRadius.circular(
                        Responsive.space(context, size: Space.large),
                      ),
                      border: Border.all(
                        color:
                            _isHovered
                                ? borderColor
                                : borderColor.withOpacity(0.6),
                        width:
                            isOverdue
                                ? 2.5
                                : _isHovered
                                ? 2.0
                                : 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: borderColor.withOpacity(
                            _isHovered ? 0.3 : 0.1,
                          ),
                          blurRadius: _isHovered ? 12 : 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: cardPadding * 0.8,
                        vertical: cardPadding,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Main content row
                          Row(
                            children: [
                              // Enhanced checkbox with glow effect
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      isCompleted
                                          ? Colors.green.shade500
                                          : borderColor,
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isCompleted
                                              ? Colors.green
                                              : borderColor)
                                          .withOpacity(0.4),
                                      blurRadius: _isHovered ? 15 : 8,
                                      spreadRadius: _isHovered ? 2 : 1,
                                    ),
                                  ],
                                  border: Border.all(
                                    color:
                                        _isHovered
                                            ? borderColor
                                            : Colors.grey.shade300,
                                    width: 2,
                                  ),
                                ),
                                child: IconButton(
                                  onPressed: widget.onStatusChanged,
                                  icon: Icon(
                                    checkboxIcon,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  tooltip:
                                      isCompleted
                                          ? 'إلغاء الإكمال'
                                          : 'إكمال التاسك',
                                  style: IconButton.styleFrom(
                                    padding: EdgeInsets.all(
                                      Responsive.space(
                                        context,
                                        size: Space.small,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(
                                width: Responsive.space(
                                  context,
                                  size: Space.small,
                                ),
                              ),

                              // Task content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    // Task title
                                    AutoSizeText(
                                      widget.task.title,
                                      minFontSize: Responsive.text(
                                        context,
                                        size: TextSize.small,
                                      ),
                                      textAlign: TextAlign.right,
                                      maxLines: isCompleted ? 1 : 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        decoration:
                                            isCompleted
                                                ? TextDecoration.lineThrough
                                                : TextDecoration.none,
                                        fontSize: titleFontSize,
                                        fontWeight:
                                            isCompleted
                                                ? FontWeight.w400
                                                : FontWeight.w600,
                                        color: textColor,
                                      ),
                                    ),

                                    if (!isCompleted) ...[
                                      SizedBox(
                                        height: Responsive.space(
                                          context,
                                          size: Space.small,
                                        ),
                                      ),

                                      // Task info chips (only for non-completed tasks)
                                      Wrap(
                                        spacing: Responsive.space(
                                          context,
                                          size: Space.tiny,
                                        ),
                                        runSpacing: Responsive.space(
                                          context,
                                          size: Space.tiny,
                                        ),
                                        alignment: WrapAlignment.end,
                                        children: [
                                          // Importance chip
                                          _buildInfoChip(
                                            _getImportanceLabel(
                                              widget.task.importance,
                                            ),
                                            importanceColor,
                                            Icons.priority_high,
                                          ),

                                          // Personal task indicator
                                          if (widget.task.isPersonal)
                                            _buildInfoChip(
                                              'شخصية',
                                              Colors.blue.shade400,
                                              Icons.person,
                                            ),

                                          // Overdue indicator
                                          if (isOverdue)
                                            _buildInfoChip(
                                              'متأخرة',
                                              Colors.red.shade400,
                                              Icons.warning,
                                            ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),

                          if (!isCompleted) ...[
                            SizedBox(
                              height: Responsive.space(
                                context,
                                size: Space.medium,
                              ),
                            ),

                            // Due date section (only for non-completed tasks)
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: Responsive.space(
                                  context,
                                  size: Space.medium,
                                ),
                                vertical: Responsive.space(
                                  context,
                                  size: Space.small,
                                ),
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(
                                  Responsive.space(context, size: Space.medium),
                                ),
                                border: Border.all(
                                  color: borderColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    color: borderColor,
                                    size: 16,
                                  ),
                                  SizedBox(
                                    width: Responsive.space(
                                      context,
                                      size: Space.tiny,
                                    ),
                                  ),
                                  Text(
                                    'آخر موعد للتسليم: $fullFormattedDate',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontSize: Responsive.text(
                                        context,
                                        size: TextSize.small,
                                      ),
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Admin actions
                          if (widget.admin) ...[
                            SizedBox(
                              height: Responsive.space(
                                context,
                                size: Space.medium,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                _buildActionButton(
                                  icon: Icons.edit_outlined,
                                  color: Colors.grey.shade600,
                                  tooltip: 'تعديل التاسك',
                                  onPressed: widget.onEdit,
                                ),
                                SizedBox(
                                  width: Responsive.space(
                                    context,
                                    size: Space.tiny,
                                  ),
                                ),
                                _buildActionButton(
                                  icon: Icons.delete_outline,
                                  color: Colors.red.shade400,
                                  tooltip: 'حذف التاسك',
                                  onPressed: widget.onDelete,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(String label, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, size: Space.tiny),
        vertical: Responsive.space(context, size: Space.tiny),
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.small),
        ),
        border: Border.all(color: color.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          SizedBox(width: Responsive.space(context, size: Space.tiny)),
          Text(
            label,
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.small),
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(
          Responsive.space(context, size: Space.small),
        ),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 18),
        onPressed: onPressed,
        tooltip: tooltip,
        style: IconButton.styleFrom(
          padding: EdgeInsets.all(Responsive.space(context, size: Space.tiny)),
        ),
      ),
    );
  }
}
