import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/tasks/screens/screens.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:pivot/features/user/providers/user_profile_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'task.dart'; // Import the Task data model
import 'package:pivot/responsive.dart';

/// Enhanced TaskModel with subtle design using white/black palette
class TaskModel extends ConsumerStatefulWidget {
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
  ConsumerState<TaskModel> createState() => _TaskModelState();
}

class _TaskModelState extends ConsumerState<TaskModel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _isHovered = false;
  bool _hasNotes = false;
  bool _isCheckingNotes = true;

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

    // Check for existing notes
    _checkForNotes();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Check if the task has existing notes
  Future<void> _checkForNotes() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() {
            _isCheckingNotes = false;
          });
        }
        return;
      }

      final notesDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('task_notes')
              .doc(widget.task.id)
              .get();

      if (mounted) {
        setState(() {
          _hasNotes =
              notesDoc.exists &&
              notesDoc.data()?['notes'] != null &&
              (notesDoc.data()!['notes'] as List).isNotEmpty;
          _isCheckingNotes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasNotes = false;
          _isCheckingNotes = false;
        });
      }
    }
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
    final userProfileState = ref.read(userProfileProvider);
    final userId = userProfileState.loggedInUserProfile?.id;

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
                elevation: _isHovered ? 8 : 3,
                borderRadius: BorderRadius.circular(
                  Responsive.space(context, size: Space.large) * 1.2,
                ),
                shadowColor: borderColor.withOpacity(0.2),
                child: InkWell(
                  borderRadius: BorderRadius.circular(
                    Responsive.space(context, size: Space.large) * 1.2,
                  ),
                  onTap: () async {
                    await showDialog(
                      context: context,
                      builder: (_) => TaskDetailsDialog(task: widget.task),
                    );
                    // Refresh notes status after dialog closes
                    _checkForNotes();
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
                      gradient:
                          isCompleted
                              ? LinearGradient(
                                colors: [
                                  Colors.grey.shade50,
                                  Colors.grey.shade100,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                              : LinearGradient(
                                colors:
                                    _isHovered
                                        ? [Colors.white, Colors.grey.shade50]
                                        : [Colors.white, Colors.white],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                      borderRadius: BorderRadius.circular(
                        Responsive.space(context, size: Space.large) * 1.2,
                      ),
                      border: Border.all(
                        color:
                            isOverdue
                                ? Colors.red.shade400
                                : _isHovered
                                ? borderColor
                                : borderColor.withOpacity(0.3),
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
                            _isHovered ? 0.25 : 0.1,
                          ),
                          blurRadius: _isHovered ? 16 : 8,
                          offset: Offset(0, _isHovered ? 4 : 2),
                          spreadRadius: _isHovered ? 1 : 0,
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
                          // Header row with RTL layout: checkbox (right) -> content (center) -> indicator (left)
                          Row(
                            children: [
                              // Modern checkbox (right side for RTL)
                              GestureDetector(
                                onTap: widget.onStatusChanged,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        isCompleted
                                            ? Colors.green.shade500
                                            : Colors.transparent,
                                    border: Border.all(
                                      color:
                                          isCompleted
                                              ? Colors.green.shade500
                                              : borderColor,
                                      width: 2.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (isCompleted
                                                ? Colors.green.shade500
                                                : borderColor)
                                            .withOpacity(0.3),
                                        blurRadius: _isHovered ? 8 : 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child:
                                      isCompleted
                                          ? Icon(
                                            Icons.check_rounded,
                                            color: Colors.white,
                                            size: 18,
                                          )
                                          : null,
                                ),
                              ),

                              SizedBox(
                                width: Responsive.space(
                                  context,
                                  size: Space.medium,
                                ),
                              ),

                              // Task content (expanded center)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.end, // RTL alignment
                                  children: [
                                    // Task title (right aligned for RTL)
                                    Text(
                                      widget.task.title,
                                      textAlign:
                                          TextAlign.right, // RTL text alignment
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
                                                : FontWeight.w700,
                                        color: textColor,
                                        height: 1.3,
                                      ),
                                    ),

                                    if (!isCompleted) ...[
                                      SizedBox(
                                        height: Responsive.space(
                                          context,
                                          size: Space.small,
                                        ),
                                      ),

                                      // Due date row (RTL aligned)
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment
                                                .end, // RTL alignment
                                        children: [
                                          Text(
                                            fullFormattedDate,
                                            style: TextStyle(
                                              fontSize: Responsive.text(
                                                context,
                                                size: TextSize.small,
                                              ),
                                              color:
                                                  isOverdue
                                                      ? Colors.red.shade600
                                                      : Colors.grey.shade600,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          SizedBox(width: 4),
                                          Icon(
                                            Icons.schedule_rounded,
                                            size: 16,
                                            color: Colors.grey.shade600,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              SizedBox(
                                width: Responsive.space(
                                  context,
                                  size: Space.medium,
                                ),
                              ),

                              // Importance indicator (left side for RTL)
                              Container(
                                width: 4,
                                height: isCompleted ? 30 : 40,
                                decoration: BoxDecoration(
                                  color:
                                      isOverdue
                                          ? Colors.red.shade400
                                          : borderColor,
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: borderColor.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          if (!isCompleted) ...[
                            // Only show tags row if there are tags to display
                            if (widget.task.isPersonal ||
                                isOverdue ||
                                (_hasNotes && !_isCheckingNotes)) ...[
                              SizedBox(
                                height: Responsive.space(
                                  context,
                                  size: Space.medium,
                                ),
                              ),

                              // Modern info tags row (RTL layout)
                              Row(
                                children: [
                                  // Status tags aligned to the right (RTL)
                                  Expanded(
                                    child: Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      alignment:
                                          WrapAlignment
                                              .end, // RTL alignment - tags on right
                                      children: [
                                        // Personal task indicator
                                        // if (widget.task.isPersonal)
                                        //   _buildModernTag(
                                        //     'شخصية',
                                        //     Colors.blue.shade600,
                                        //     Icons.person,
                                        //   ),

                                        // Overdue indicator
                                        if (isOverdue)
                                          _buildModernTag(
                                            'متأخرة',
                                            Colors.red.shade600,
                                            Icons.warning_rounded,
                                          ),

                                        // Notes indicator
                                        if (_hasNotes && !_isCheckingNotes)
                                          _buildModernTag(
                                            'ملاحظات',
                                            Colors.purple.shade600,
                                            Icons.notes_rounded,
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
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

  // Modern tag widget for info display
  Widget _buildModernTag(String label, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
