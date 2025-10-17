import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/models/task.dart';
import 'package:pivot/features/tasks/providers/tasks_provider.dart';
import 'package:pivot/features/home/screens/adminstration/animated_route.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';

class TaskDetailsScreen extends ConsumerStatefulWidget {
  final Task task;

  const TaskDetailsScreen({super.key, required this.task});

  @override
  ConsumerState<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends ConsumerState<TaskDetailsScreen>
    with TickerProviderStateMixin {
  final TextEditingController _noteController = TextEditingController();
  bool _isAddingNote = false;
  Task? _currentTask;
  List<TaskNote> _userNotes = [];
  bool _isLoading = true;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _currentTask = widget.task;
    _fetchLatestTaskData();

    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
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
          Navigator.of(context).pop(); // Close the screen
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'تفاصيل التاسك',
            style: TextStyle(
              color: Colors.black,
              fontSize: Responsive.text(context, size: TextSize.medium),
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            // Delete Button (only show for personal tasks)
            if (_currentTask?.isPersonal == true)
              IconButton(
                onPressed: _handleDelete,
                icon: Icon(Icons.delete_outline),
                color: Colors.red[400],
                tooltip: 'حذف التاسك',
              ),
          ],
        ),
        body:
            _isLoading || _currentTask == null
                ? Center(child: CircularProgressIndicator(color: Colors.black))
                : FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildContent(),
                  ),
                ),
      ),
    );
  }

  Widget _buildContent() {
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

    return SingleChildScrollView(
      padding: EdgeInsets.all(Responsive.space(context, size: Space.large)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Task Title
          Text(
            task.title,
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.heading),
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.right,
          ),
          SizedBox(height: Responsive.space(context, size: Space.medium)),

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
                SizedBox(width: Responsive.space(context, size: Space.medium)),
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
          _buildSectionHeader('تاريخ التسليم', Icons.calendar_today),
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
                SizedBox(width: Responsive.space(context, size: Space.medium)),
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
          _buildSectionHeader('وصف التاسك', Icons.description),
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

          // Source information section
          if (task.sourceInfo.isNotEmpty &&
              task.sourceInfo != 'مصدر غير محدد') ...[
            SizedBox(height: Responsive.space(context, size: Space.medium)),
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
                  Expanded(
                    child: Text(
                      task.sourceInfo,
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.medium,
                        ),
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.start,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Attachments Section
          if (task.attachments != null && task.attachments!.isNotEmpty) ...[
            SizedBox(height: Responsive.space(context, size: Space.medium)),
            _buildSectionHeader('المرفقات', Icons.attach_file),
            _buildAttachmentsSection(task.attachments!, headerColor),
          ],

          // Notes Section
          SizedBox(height: Responsive.space(context, size: Space.medium)),
          _buildSectionHeader('ملاحظات', Icons.notes),

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
                                    content: Text('هل تريد حذف هذه الملاحظة؟'),
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
                      fontSize: Responsive.text(context, size: TextSize.medium),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.medium),
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: Responsive.space(context, size: Space.small)),
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
                        vertical: Responsive.space(context, size: Space.small),
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
    );
  }

  Widget _buildAttachmentsSection(
    List<Map<String, String>> attachments,
    Color headerColor,
  ) {
    print(
      '📎 [TaskDetails] Building attachments section with ${attachments.length} attachments',
    );
    for (var att in attachments) {
      print(
        '📎 [TaskDetails] Attachment: ${att['title']} - Type: ${att['type']} - URL: ${att['url']}',
      );
    }

    // Separate images from other attachments
    final images = attachments.where((att) => att['type'] == 'image').toList();
    final otherAttachments =
        attachments.where((att) => att['type'] != 'image').toList();

    print(
      '📎 [TaskDetails] Found ${images.length} images and ${otherAttachments.length} other attachments',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image Gallery (if there are images)
        if (images.isNotEmpty) ...[
          _buildImageGallery(images),
          if (otherAttachments.isNotEmpty)
            SizedBox(height: Responsive.space(context, size: Space.medium)),
        ],

        // Other Attachments (files, links, materials)
        if (otherAttachments.isNotEmpty) ...[
          ...otherAttachments.map((attachment) {
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
                                  Responsive.space(context, size: Space.large),
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
                                Responsive.space(context, size: Space.large),
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
                        _getAttachmentIcon(attachment['type']),
                        color: headerColor,
                        size: Responsive.space(context, size: Space.medium),
                      ),
                      SizedBox(
                        width: Responsive.space(context, size: Space.small),
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
                        Icons.open_in_new,
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
      ],
    );
  }

  Widget _buildImageGallery(List<Map<String, String>> images) {
    return Container(
      height: Responsive.space(context, size: Space.large) * 2,
      margin: EdgeInsets.only(
        top: Responsive.space(context, size: Space.medium),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        itemBuilder: (context, index) {
          final image = images[index];
          final imageUrl = image['url'] ?? '';
          return Padding(
            padding: EdgeInsets.only(
              left: Responsive.space(context, size: Space.small),
            ),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (context) => FullScreenImageViewer(imageUrl: imageUrl),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  Responsive.space(context, size: Space.large),
                ),
                child: Hero(
                  tag: imageUrl,
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: Responsive.space(context, size: Space.large) * 2,
                    height: Responsive.space(context, size: Space.large) * 2,
                    fit: BoxFit.cover,
                    placeholder: (context, url) {
                      print('🖼️ [TaskDetails] Loading image: $url');
                      return Container(
                        width: Responsive.space(context, size: Space.large),
                        height: Responsive.space(context, size: Space.large),
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorWidget: (context, url, error) {
                      print(
                        '❌ [TaskDetails] Error loading image: $url - Error: $error',
                      );
                      return Container(
                        width: Responsive.space(context, size: Space.large) * 2,
                        height:
                            Responsive.space(context, size: Space.large) * 2,
                        color: Colors.grey[200],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                              size: 24,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'خطأ في تحميل الصورة',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getAttachmentIcon(String? type) {
    switch (type) {
      case 'file':
        return Icons.upload_file;
      case 'link':
        return Icons.link;
      case 'image':
        return Icons.image;
      default:
        return Icons.attach_file;
    }
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: Responsive.space(context, size: Space.small),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.grey[600],
            size: Responsive.space(context, size: Space.medium),
          ),
          SizedBox(width: Responsive.space(context, size: Space.small)),
          Text(
            title,
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.medium),
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
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

class FullScreenImageViewer extends StatefulWidget {
  final String imageUrl;

  const FullScreenImageViewer({super.key, required this.imageUrl});

  @override
  _FullScreenImageViewerState createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer>
    with SingleTickerProviderStateMixin {
  late TransformationController _transformationController;
  late AnimationController _animationController;
  Animation<Offset>? _animation;
  Offset _dragOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animationController.addListener(() {
      if (_animation != null && mounted) {
        setState(() {
          _dragOffset = _animation!.value;
        });
      }
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    // Only allow dragging when not scaled
    if (_transformationController.value.getMaxScaleOnAxis() <= 1.0 && mounted) {
      setState(() {
        _dragOffset += details.delta;
      });
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (_transformationController.value.getMaxScaleOnAxis() > 1.0) {
      return; // Don't dismiss if zoomed
    }

    final screenHeight = MediaQuery.of(context).size.height;
    // Dismiss if dragged down far enough or with enough velocity
    if ((details.primaryVelocity ?? 0) > 500 ||
        _dragOffset.dy > screenHeight / 4) {
      Navigator.of(context).pop();
    } else {
      // Animate back to center
      _animation = Tween<Offset>(begin: _dragOffset, end: Offset.zero).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
      );
      _animationController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate background opacity based on drag distance
    final double opacity = (1.0 -
            (_dragOffset.dy.abs() / (MediaQuery.of(context).size.height / 2)))
        .clamp(0.4, 1.0);

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(opacity),
      body: Stack(
        children: [
          GestureDetector(
            onVerticalDragUpdate: _onVerticalDragUpdate,
            onVerticalDragEnd: _onVerticalDragEnd,
            child: Transform.translate(
              offset: _dragOffset,
              child: Center(
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Hero(
                    tag: widget.imageUrl,
                    child: CachedNetworkImage(
                      imageUrl: widget.imageUrl,
                      placeholder: (context, url) {
                        print('🖼️ [FullScreen] Loading image: $url');
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorWidget: (context, url, error) {
                        print(
                          '❌ [FullScreen] Error loading image: $url - Error: $error',
                        );
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error,
                              size: 48,
                              color: Colors.red,
                            ),
                            SizedBox(height: 16),
                            Text('خطأ في تحميل الصورة'),
                            Text('URL: $url'),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Back button
          Positioned(
            top: Responsive.space(context, size: Space.medium),
            left: Responsive.space(context, size: Space.medium),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 24.0,
              ),
              onPressed: () => Navigator.of(context).pop(),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withOpacity(0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showTaskDetailsScreen({
  required BuildContext context,
  required Task task,
}) async {
  await Navigator.of(context).push(
    AnimatedAddRoute(
      child: TaskDetailsScreen(task: task),
      startPosition: Offset(0, 1),
    ),
  );
}
