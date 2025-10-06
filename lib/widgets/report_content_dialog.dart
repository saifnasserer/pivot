import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pivot/responsive.dart';

class ReportContentDialog extends StatefulWidget {
  final String contentId;
  final String contentType; // 'comment', 'post', 'user', 'announcement'
  final String? contentAuthorId;

  const ReportContentDialog({
    super.key,
    required this.contentId,
    required this.contentType,
    this.contentAuthorId,
  });

  @override
  State<ReportContentDialog> createState() => _ReportContentDialogState();
}

class _ReportContentDialogState extends State<ReportContentDialog> {
  String? _selectedReason;
  final TextEditingController _detailsController = TextEditingController();
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _reportReasons = [
    {'value': 'spam', 'label': 'بريد عشوائي أو محتوى ترويجي'},
    {'value': 'harassment', 'label': 'مضايقة أو تنمر'},
    {'value': 'hate_speech', 'label': 'خطاب كراهية أو تمييز'},
    {'value': 'inappropriate', 'label': 'محتوى غير لائق'},
    {'value': 'misinformation', 'label': 'معلومات مضللة'},
    {'value': 'copyright', 'label': 'انتهاك حقوق النشر'},
    {'value': 'other', 'label': 'أخرى'},
  ];

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار سبب الإبلاغ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('يجب تسجيل الدخول للإبلاغ');
      }

      await FirebaseFirestore.instance.collection('reports').add({
        'contentId': widget.contentId,
        'contentType': widget.contentType,
        'contentAuthorId': widget.contentAuthorId,
        'reason': _selectedReason,
        'details': _detailsController.text.trim(),
        'reporterId': currentUser.uid,
        'status': 'pending', // pending, reviewed, resolved
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم إرسال البلاغ بنجاح. سنقوم بمراجعته قريباً'),
            backgroundColor: Colors.green.shade600,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            Responsive.space(context, size: Space.large),
          ),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 500,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          padding: EdgeInsets.all(Responsive.space(context, size: Space.large)),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(
                        Responsive.space(context, size: Space.small),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.flag,
                        color: Colors.red.shade700,
                        size: Responsive.text(context, size: TextSize.heading),
                      ),
                    ),
                    SizedBox(
                      width: Responsive.space(context, size: Space.small),
                    ),
                    Expanded(
                      child: Text(
                        'الإبلاغ عن محتوى',
                        style: TextStyle(
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.heading,
                          ),
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: Colors.grey[600]),
                    ),
                  ],
                ),
                SizedBox(height: Responsive.space(context, size: Space.medium)),

                // Description
                Text(
                  'ساعدنا في الحفاظ على مجتمع آمن ومحترم',
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.small),
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: Responsive.space(context, size: Space.large)),

                // Reason selection
                Text(
                  'سبب الإبلاغ *',
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.medium),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: Responsive.space(context, size: Space.small)),

                ..._reportReasons.map((reason) {
                  return RadioListTile<String>(
                    title: Text(
                      reason['label'],
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.small,
                        ),
                      ),
                    ),
                    value: reason['value'],
                    groupValue: _selectedReason,
                    onChanged: (value) {
                      setState(() {
                        _selectedReason = value;
                      });
                    },
                    activeColor: Colors.red.shade700,
                    contentPadding: EdgeInsets.zero,
                  );
                }),

                SizedBox(height: Responsive.space(context, size: Space.medium)),

                // Additional details
                Text(
                  'تفاصيل إضافية (اختياري)',
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.medium),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: Responsive.space(context, size: Space.small)),

                TextField(
                  controller: _detailsController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'اكتب أي تفاصيل إضافية تساعدنا في المراجعة...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  textDirection: TextDirection.rtl,
                ),

                SizedBox(height: Responsive.space(context, size: Space.large)),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _isSubmitting ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    SizedBox(
                      width: Responsive.space(context, size: Space.small),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitReport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child:
                            _isSubmitting
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : const Text('إرسال البلاغ'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
