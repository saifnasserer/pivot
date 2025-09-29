import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pivot/widgets/no_internet_message.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/widgets/unified_dialog.dart';
import 'package:pivot/features/feedback/providers/feedback_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackManagementScreen extends ConsumerStatefulWidget {
  const FeedbackManagementScreen({super.key});

  @override
  ConsumerState<FeedbackManagementScreen> createState() =>
      _FeedbackManagementScreenState();
}

class _FeedbackManagementScreenState
    extends ConsumerState<FeedbackManagementScreen> {
  Future<void> _updateFeedbackStatus(String docId, String status) async {
    final success = await ref
        .read(feedbackProvider.notifier)
        .updateFeedbackStatus(docId, status);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تحديث حالة الملاحظة إلى $status'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تحديث الحالة'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _showFeedbackDetails(Map<String, dynamic> feedback, String docId) {
    showDialog(
      context: context,
      builder:
          (context) => UnifiedDialog(
            title: 'تفاصيل الملاحظة',
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('المستخدم', feedback['userName'] ?? 'غير محدد'),
                _buildDetailRow(
                  'البريد الإلكتروني',
                  feedback['userEmail'] ?? 'غير محدد',
                ),
                _buildDetailRow('النوع', feedback['category'] ?? 'غير محدد'),
                _buildDetailRow('الحالة', _getStatusText(feedback['status'])),
                _buildDetailRow(
                  'التاريخ',
                  _formatTimestamp(feedback['timestamp']),
                ),
                SizedBox(height: Responsive.space(context, size: Space.medium)),
                Text(
                  'المحتوى:',
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.medium),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: Responsive.space(context, size: Space.small)),
                Container(
                  width: double.infinity,
                  padding: Responsive.padding(context, size: Space.medium),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Text(
                    feedback['feedback'] ?? 'لا يوجد محتوى',
                    style: TextStyle(
                      fontSize: Responsive.text(context, size: TextSize.small),
                      color: Colors.grey[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: Responsive.space(context, size: Space.medium)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.space(
                          context,
                          size: Space.small,
                        ),
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        feedback['status'] ?? 'pending',
                        style: TextStyle(
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.small,
                          ),
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      _formatTimestamp(feedback['timestamp']),
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.small,
                        ),
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              if (feedback['status'] == 'pending') ...[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _updateFeedbackStatus(docId, 'resolved');
                  },
                  child: Text('حل'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _updateFeedbackStatus(docId, 'rejected');
                  },
                  child: Text('رفض'),
                ),
              ],
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('إغلاق'),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: Responsive.paddingVertical(context, size: Space.tiny),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.small),
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.small),
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedbackState = ref.watch(feedbackProvider);

    // Load feedback data when the screen is built
    ref.listen(feedbackProvider, (previous, next) {
      if (next.feedback.isEmpty && !next.isLoading) {
        ref.read(feedbackProvider.notifier).loadAllFeedback();
      }
    });

    return NoInternetMessage(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            'إدارة الملاحظات',
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.heading),
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: _buildFeedbackList(feedbackState),
      ),
    );
  }

  Widget _buildFeedbackList(FeedbackState feedbackState) {
    if (feedbackState.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.black),
            SizedBox(height: Responsive.space(context, size: Space.medium)),
            Text(
              'جاري تحميل الملاحظات...',
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.medium),
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (feedbackState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            SizedBox(height: Responsive.space(context, size: Space.medium)),
            Text(
              'خطأ في تحميل الملاحظات',
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.medium),
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            SizedBox(height: Responsive.space(context, size: Space.small)),
            Text(
              feedbackState.error!,
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.small),
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Responsive.space(context, size: Space.medium)),
            ElevatedButton(
              onPressed: () {
                ref.read(feedbackProvider.notifier).loadAllFeedback();
              },
              child: Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (feedbackState.feedback.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.feedback_outlined, size: 64, color: Colors.grey[400]),
            SizedBox(height: Responsive.space(context, size: Space.medium)),
            Text(
              'لا توجد ملاحظات',
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.medium),
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: Responsive.space(context, size: Space.small)),
            Text(
              'لم يتم إرسال أي ملاحظات بعد',
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.small),
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: Responsive.padding(context, size: Space.medium),
      itemCount: feedbackState.feedback.length,
      itemBuilder: (context, index) {
        final feedback = feedbackState.feedback[index];
        final docId = feedback['id'] as String;
        return _buildFeedbackCard(feedback, docId);
      },
    );
  }

  Widget _buildFeedbackCard(Map<String, dynamic> feedback, String docId) {
    return Container(
      margin: Responsive.paddingVertical(context, size: Space.small),
      padding: Responsive.padding(context, size: Space.medium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  feedback['userName'] ?? 'مستخدم غير معروف',
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.medium),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              _buildStatusChip(feedback['status'] ?? 'pending'),
            ],
          ),
          SizedBox(height: Responsive.space(context, size: Space.small)),
          Text(
            feedback['category'] ?? 'غير محدد',
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.small),
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: Responsive.space(context, size: Space.small)),
          Text(
            feedback['feedback'] ?? '',
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.medium),
              color: Colors.black87,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: Responsive.space(context, size: Space.small)),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
              SizedBox(width: Responsive.space(context, size: Space.tiny)),
              Text(
                _formatTimestamp(feedback['timestamp']),
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.small),
                  color: Colors.grey[500],
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _showFeedbackDetails(feedback, docId),
                child: Text('عرض التفاصيل'),
              ),
            ],
          ),
          if (feedback['status'] == 'pending') ...[
            SizedBox(height: Responsive.space(context, size: Space.small)),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateFeedbackStatus(docId, 'resolved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('حل'),
                  ),
                ),
                SizedBox(width: Responsive.space(context, size: Space.small)),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateFeedbackStatus(docId, 'rejected'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('رفض'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;

    switch (status) {
      case 'resolved':
        color = Colors.green;
        text = 'محلول';
        break;
      case 'rejected':
        color = Colors.red;
        text = 'مرفوض';
        break;
      default:
        color = Colors.orange;
        text = 'في الانتظار';
    }

    return Container(
      padding: Responsive.padding(context, size: Space.tiny),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: Responsive.text(context, size: TextSize.small),
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'غير محدد';

    try {
      DateTime dateTime;
      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else if (timestamp is DateTime) {
        dateTime = timestamp;
      } else {
        return 'غير محدد';
      }

      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (e) {
      return 'غير محدد';
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'resolved':
        return 'محلول';
      case 'rejected':
        return 'مرفوض';
      default:
        return 'في الانتظار';
    }
  }
}
