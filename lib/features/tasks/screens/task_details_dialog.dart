import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/widgets/unified_dialog.dart';
import 'package:pivot/screens/models/task.dart';
import 'package:pivot/features/tasks/providers/tasks_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaskDetailsDialog extends ConsumerStatefulWidget {
  final Task task;

  const TaskDetailsDialog({super.key, required this.task});

  @override
  ConsumerState<TaskDetailsDialog> createState() => _TaskDetailsDialogState();
}

class _TaskDetailsDialogState extends ConsumerState<TaskDetailsDialog> {
  final TextEditingController _noteController = TextEditingController();
  bool _isAddingNote = false;
  Task? _currentTask;
  List<TaskNote> _userNotes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentTask = widget.task;
    _fetchLatestTaskData();
  }

  Future<void> _fetchLatestTaskData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Fetch task data
      final taskDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('tasks')
              .doc(widget.task.id)
              .get();

      // Fetch user-specific notes separately
      final notesDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('task_notes')
              .doc(widget.task.id)
              .get();

      if (mounted) {
        setState(() {
          if (taskDoc.exists) {
            _currentTask = Task.fromMap(taskDoc.data() as Map<String, dynamic>);
          }

          if (notesDoc.exists && notesDoc.data()?['notes'] != null) {
            _userNotes =
                (notesDoc.data()!['notes'] as List)
                    .map((n) => TaskNote.fromMap(n as Map<String, dynamic>))
                    .toList();
          } else {
            _userNotes = [];
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _addNote() async {
    if (_noteController.text.trim().isEmpty) return;
    if (!mounted) return;

    setState(() => _isAddingNote = true);

    try {
      // Use the service directly to avoid provider dispose issues
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final noteDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('task_notes')
          .doc(widget.task.id);

      final doc = await noteDoc.get();
      final existingNotes =
          doc.exists && doc.data()?['notes'] != null
              ? (doc.data()!['notes'] as List)
                  .map((n) => TaskNote.fromMap(n as Map<String, dynamic>))
                  .toList()
              : <TaskNote>[];

      final updatedNotes = [
        ...existingNotes,
        TaskNote(content: _noteController.text.trim()),
      ];

      await noteDoc.set({
        'notes': updatedNotes.map((n) => n.toMap()).toList(),
        'taskId': widget.task.id,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      _noteController.clear();

      // Refresh task data to show new note
      await _fetchLatestTaskData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إضافة الملاحظة بنجاح'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                Responsive.space(context, size: Space.large),
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في إضافة الملاحظة: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                Responsive.space(context, size: Space.large),
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAddingNote = false);
      }
    }
  }

  Future<void> _deleteNote(String noteId) async {
    if (!mounted) return;

    try {
      // Use the service directly to avoid provider dispose issues
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final noteDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('task_notes')
          .doc(widget.task.id);

      final doc = await noteDoc.get();
      if (!doc.exists) return;

      final existingNotes =
          doc.data()?['notes'] != null
              ? (doc.data()!['notes'] as List)
                  .map((n) => TaskNote.fromMap(n as Map<String, dynamic>))
                  .toList()
              : <TaskNote>[];

      final updatedNotes =
          existingNotes.where((note) => note.id != noteId).toList();

      await noteDoc.set({
        'notes': updatedNotes.map((n) => n.toMap()).toList(),
        'taskId': widget.task.id,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      // Refresh task data to remove deleted note from UI
      await _fetchLatestTaskData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حذف الملاحظة بنجاح'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                Responsive.space(context, size: Space.large),
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في حذف الملاحظة: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                Responsive.space(context, size: Space.large),
              ),
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleDelete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            // title: Text('حذف التاسك'),
            content: Text(
              'متأكد؟',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.medium),
                fontWeight: FontWeight.w600,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                Responsive.space(context, size: Space.large),
              ),
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text('إلغاء'),
                  ),
                  SizedBox(
                    width: Responsive.space(context, size: Space.medium),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('حذف'),
                  ),
                ],
              ),
            ],
          ),
    );

    if (shouldDelete == true && mounted) {
      try {
        // Delete the task using TasksProvider
        await ref.read(tasksProvider.notifier).deleteTask(widget.task.id);

        if (mounted) {
          Navigator.of(context).pop(); // Close the dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم حذف التاسك بنجاح'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  Responsive.space(context, size: Space.large),
                ),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('فشل في حذف التاسك: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  Responsive.space(context, size: Space.large),
                ),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _currentTask == null) {
      return UnifiedDialog(
        title: 'جاري التحميل...',
        subtitle: '',
        content: Center(child: CircularProgressIndicator(color: Colors.black)),
        onCancel: () => Navigator.of(context).pop(),
      );
    }

    final task = _currentTask!;
    final String formattedDayOfWeek = DateFormat(
      'EEEE',
      'ar',
    ).format(task.dueDate);
    final String formattedDate = DateFormat(
      'dd MMM, yyyy',
      'ar',
    ).format(task.dueDate);
    final String fullFormattedDate = '$formattedDayOfWeek، $formattedDate';
    final Color headerColor = _getImportanceColor(task.importance);

    return UnifiedDialog(
      title: task.title,
      subtitle: 'تفاصيل التاسك',
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task importance indicator
            Container(
              padding: EdgeInsets.all(
                Responsive.space(context, size: Space.medium),
              ),
              decoration: BoxDecoration(
                color: headerColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(
                  Responsive.space(context, size: Space.large),
                ),
                border: Border.all(color: headerColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(
                    Icons.task_alt,
                    color: headerColor,
                    size: Responsive.space(context, size: Space.large),
                  ),
                  SizedBox(
                    width: Responsive.space(context, size: Space.medium),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getImportanceText(task.importance),
                        style: TextStyle(
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.medium,
                          ),
                          fontWeight: FontWeight.bold,
                          color: headerColor,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.tiny),
                      ),
                      Text(
                        'أولوية التاسك',
                        style: TextStyle(
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.small,
                          ),
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.start,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: Responsive.space(context, size: Space.medium)),

            // Due date section
            UnifiedSectionHeader(
              title: 'تاريخ التسليم',
              icon: Icons.calendar_today,
            ),
            Container(
              padding: EdgeInsets.all(
                Responsive.space(context, size: Space.medium),
              ),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(
                  Responsive.space(context, size: Space.large),
                ),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: Colors.grey[600],
                    size: Responsive.space(context, size: Space.medium),
                  ),
                  SizedBox(
                    width: Responsive.space(context, size: Space.medium),
                  ),
                  Text(
                    fullFormattedDate,
                    style: TextStyle(
                      fontSize:
                          Responsive.text(context, size: TextSize.medium) / 1.2,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.start,
                  ),
                ],
              ),
            ),
            SizedBox(height: Responsive.space(context, size: Space.medium)),

            // Description section
            UnifiedSectionHeader(title: 'وصف التاسك', icon: Icons.description),
            Container(
              padding: EdgeInsets.all(
                Responsive.space(context, size: Space.medium),
              ),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(
                  Responsive.space(context, size: Space.large),
                ),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                task.description,
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.medium),
                  color: Colors.black87,
                  height: 1.5,
                ),
                textAlign: TextAlign.start,
              ),
            ),

            // Attachments Section
            if (task.attachments != null && task.attachments!.isNotEmpty) ...[
              SizedBox(height: Responsive.space(context, size: Space.medium)),
              UnifiedSectionHeader(title: 'المرفقات', icon: Icons.attach_file),
              ...task.attachments!.map((attachment) {
                return Container(
                  margin: EdgeInsets.only(
                    bottom: Responsive.space(context, size: Space.small),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(
                      Responsive.space(context, size: Space.large),
                    ),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(
                      Responsive.space(context, size: Space.large),
                    ),
                    onTap: () async {
                      final url = attachment['url'];
                      if (url != null) {
                        try {
                          final uri = Uri.parse(url);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('تعذر فتح الملف'),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      Responsive.space(
                                        context,
                                        size: Space.large,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('خطأ في فتح الملف: $e'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    Responsive.space(
                                      context,
                                      size: Space.large,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                        }
                      }
                    },
                    child: Padding(
                      padding: EdgeInsets.all(
                        Responsive.space(context, size: Space.medium),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(
                            Icons.open_in_new,
                            color: headerColor,
                            size: Responsive.space(context, size: Space.medium),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  attachment['title'] ?? 'ملف مرفق',
                                  style: TextStyle(
                                    fontSize: Responsive.text(
                                      context,
                                      size: TextSize.medium,
                                    ),
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                  textAlign: TextAlign.start,
                                ),
                                SizedBox(
                                  height: Responsive.space(
                                    context,
                                    size: Space.tiny,
                                  ),
                                ),
                                Text(
                                  'اضغط لفتح الملف',
                                  style: TextStyle(
                                    fontSize: Responsive.text(
                                      context,
                                      size: TextSize.small,
                                    ),
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.start,
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.attach_file,
                            color: headerColor,
                            size: Responsive.space(context, size: Space.medium),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],

            // Notes Section
            SizedBox(height: Responsive.space(context, size: Space.medium)),
            UnifiedSectionHeader(title: 'ملاحظات', icon: Icons.notes),

            // Display existing notes first
            if (_userNotes.isNotEmpty) ...[
              SizedBox(height: Responsive.space(context, size: Space.small)),
              ..._userNotes.reversed.map((note) {
                final formattedDate = DateFormat(
                  'dd MMM, yyyy - hh:mm a',
                  'ar',
                ).format(note.createdAt);

                return Container(
                  margin: EdgeInsets.only(
                    bottom: Responsive.space(context, size: Space.small),
                  ),
                  padding: EdgeInsets.all(
                    Responsive.space(context, size: Space.medium),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      Responsive.space(context, size: Space.large),
                    ),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              note.content,
                              style: TextStyle(
                                fontSize: Responsive.text(
                                  context,
                                  size: TextSize.medium,
                                ),
                                color: Colors.black87,
                                height: 1.5,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline, size: 20),
                            color: Colors.red[400],
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder:
                                    (ctx) => AlertDialog(
                                      title: Text('حذف الملاحظة'),
                                      content: Text(
                                        'هل تريد حذف هذه الملاحظة؟',
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          Responsive.space(
                                            context,
                                            size: Space.large,
                                          ),
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: Text('إلغاء'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            _deleteNote(note.id);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                          ),
                                          child: Text('حذف'),
                                        ),
                                      ],
                                    ),
                              );
                            },
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.tiny),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          SizedBox(
                            width: Responsive.space(context, size: Space.tiny),
                          ),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: Responsive.text(
                                context,
                                size: TextSize.small,
                              ),
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],

            // Add note input at the bottom
            SizedBox(height: Responsive.space(context, size: Space.small)),
            Container(
              padding: EdgeInsets.all(
                Responsive.space(context, size: Space.medium),
              ),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(
                  Responsive.space(context, size: Space.large),
                ),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _noteController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText:
                          _userNotes.isEmpty
                              ? 'لا توجد ملاحظات، أضف ملاحظة جديدة...'
                              : 'أضف ملاحظة جديدة...',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.medium,
                        ),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: TextStyle(
                      fontSize: Responsive.text(context, size: TextSize.medium),
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(
                    height: Responsive.space(context, size: Space.small),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton.icon(
                      onPressed: _isAddingNote ? null : _addNote,
                      icon:
                          _isAddingNote
                              ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : Icon(Icons.add, size: 18),
                      label: Text('إضافة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.space(
                            context,
                            size: Space.large,
                          ),
                          vertical: Responsive.space(
                            context,
                            size: Space.small,
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            Responsive.space(context, size: Space.medium),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Cancel Button
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.space(context, size: Space.medium),
                  vertical: Responsive.space(context, size: Space.small),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    Responsive.space(context, size: Space.large),
                  ),
                ),
              ),
              child: Text(
                'إلغاء',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.medium),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Delete Button (only show for personal tasks)
            if (task.isPersonal)
              IconButton(
                onPressed: _handleDelete,
                icon: Icon(Icons.delete_outline),
                color: Colors.red[400],
                tooltip: 'حذف التاسك',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      Responsive.space(context, size: Space.large),
                    ),
                  ),
                  padding: EdgeInsets.all(
                    Responsive.space(context, size: Space.small),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

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

  String _getImportanceText(TaskImportance importance) {
    switch (importance) {
      case TaskImportance.high:
        return 'عالية';
      case TaskImportance.mid:
        return 'متوسطة';
      case TaskImportance.low:
        return 'منخفضة';
    }
  }
}
