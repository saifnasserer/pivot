import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/widgets/unified_dialog.dart';
import 'package:pivot/widgets/no_internet_message.dart';

class FeedbackManagementScreen extends StatefulWidget {
  // = 'feedback_management_screen';

  const FeedbackManagementScreen({super.key});

  @override
  State<FeedbackManagementScreen> createState() =>
      _FeedbackManagementScreenState();
}

class _FeedbackManagementScreenState extends State<FeedbackManagementScreen> {
  Future<void> _updateFeedbackStatus(String docId, String status) async {
    try {
      await FirebaseFirestore.instance.collection('feedback').doc(docId).update(
        {'status': status},
      );
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تحديث الحالة: $e'),
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
            title: feedback['category']?.toString().toUpperCase() ?? 'ملاحظة',
            subtitle: 'تفاصيل الملاحظة',
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // User information section
                  UnifiedSectionHeader(
                    title: 'معلومات المستخدم',
                    icon: Icons.person,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildInfoRow(
                          'الاسم',
                          feedback['userName'] ?? 'غير معروف',
                        ),
                        SizedBox(
                          height: Responsive.space(context, size: Space.small),
                        ),
                        _buildInfoRow(
                          'البريد الإلكتروني',
                          feedback['userEmail'] ?? 'غير متوفر',
                        ),
                        SizedBox(
                          height: Responsive.space(context, size: Space.small),
                        ),
                        _buildInfoRow(
                          'الدور',
                          feedback['userRole'] ?? 'غير محدد',
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: Responsive.space(context, size: Space.medium),
                  ),

                  // Feedback content section
                  if (feedback['feedback'] != null &&
                      feedback['feedback'].toString().isNotEmpty) ...[
                    UnifiedSectionHeader(
                      title: 'التعليق',
                      icon: Icons.feedback,
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
                      child: Text(
                        feedback['feedback'] ?? 'لا يوجد تعليق',
                        style: TextStyle(
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.medium,
                          ),
                          color: Colors.black87,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    SizedBox(
                      height: Responsive.space(context, size: Space.medium),
                    ),
                  ],

                  // Status section
                  UnifiedSectionHeader(
                    title: 'حالة الملاحظة',
                    icon: Icons.info,
                  ),
                  Container(
                    padding: EdgeInsets.all(
                      Responsive.space(context, size: Space.medium),
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        feedback['status'] ?? 'pending',
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        Responsive.space(context, size: Space.large),
                      ),
                      border: Border.all(
                        color: _getStatusColor(
                          feedback['status'] ?? 'pending',
                        ).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(
                          _getStatusIcon(feedback['status'] ?? 'pending'),
                          color: _getStatusColor(
                            feedback['status'] ?? 'pending',
                          ),
                          size: Responsive.space(context, size: Space.medium),
                        ),
                        SizedBox(
                          width: Responsive.space(context, size: Space.medium),
                        ),
                        Text(
                          _getStatusText(feedback['status'] ?? 'pending'),
                          style: TextStyle(
                            fontSize: Responsive.text(
                              context,
                              size: TextSize.medium,
                            ),
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(
                              feedback['status'] ?? 'pending',
                            ),
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.archive_outlined, size: 20),
                    label: Text('أرشفة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          Responsive.space(context, size: Space.large),
                        ),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.space(
                          context,
                          size: Space.medium,
                        ),
                        vertical: Responsive.space(context, size: Space.small),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _updateFeedbackStatus(docId, 'archived');
                    },
                  ),
                  ElevatedButton.icon(
                    icon: Icon(Icons.check_circle_outline_rounded, size: 20),
                    label: Text('تم القراءة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          Responsive.space(context, size: Space.large),
                        ),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.space(
                          context,
                          size: Space.medium,
                        ),
                        vertical: Responsive.space(context, size: Space.small),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _updateFeedbackStatus(docId, 'read');
                    },
                  ),
                ],
              ),
            ],
          ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: Responsive.text(context, size: TextSize.small),
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.right,
        ),
        SizedBox(width: Responsive.space(context, size: Space.small)),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: Responsive.text(context, size: TextSize.small),
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'read':
        return Colors.green;
      case 'archived':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'read':
        return Icons.check_circle;
      case 'archived':
        return Icons.archive;
      case 'pending':
      default:
        return Icons.schedule;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'read':
        return 'تم القراءة';
      case 'archived':
        return 'مؤرشف';
      case 'pending':
      default:
        return 'في الانتظار';
    }
  }

  @override
  Widget build(BuildContext context) {
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
        body: StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('feedback')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Colors.black),
                    SizedBox(
                      height: Responsive.space(context, size: Space.medium),
                    ),
                    Text(
                      'جاري تحميل الملاحظات...',
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.medium,
                        ),
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    SizedBox(
                      height: Responsive.space(context, size: Space.medium),
                    ),
                    Text(
                      'حدث خطأ: ${snapshot.error}',
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.medium,
                        ),
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.feedback_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    SizedBox(
                      height: Responsive.space(context, size: Space.medium),
                    ),
                    Text(
                      'لا توجد ملاحظات حتى الآن',
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.medium,
                        ),
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            final feedbackDocs = snapshot.data!.docs;

            return ListView.builder(
              padding: Responsive.padding(context, size: Space.large),
              itemCount: feedbackDocs.length,
              itemBuilder: (context, index) {
                final feedback =
                    feedbackDocs[index].data() as Map<String, dynamic>;
                final timestamp = feedback['timestamp'] as Timestamp?;
                final formattedDate =
                    timestamp != null
                        ? DateFormat(
                          'MMM d, yyyy – hh:mm a',
                        ).format(timestamp.toDate())
                        : 'التاريخ غير متوفر';

                return Container(
                  margin: EdgeInsets.only(
                    bottom: Responsive.space(context, size: Space.medium),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
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
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap:
                        () => _showFeedbackDetails(
                          feedback,
                          feedbackDocs[index].id,
                        ),
                    child: Padding(
                      padding: Responsive.padding(context, size: Space.large),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.grey[400],
                                size: 16,
                              ),
                              Spacer(),
                              Column(
                                children: [
                                  Text(
                                    feedback['category']
                                            ?.toString()
                                            .toUpperCase() ??
                                        'ملاحظة',
                                    style: TextStyle(
                                      fontSize: Responsive.text(
                                        context,
                                        size: TextSize.medium,
                                      ),
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    'من: ${feedback['userName'] ?? 'غير معروف'}',
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
                          SizedBox(
                            height: Responsive.space(
                              context,
                              size: Space.medium,
                            ),
                          ),
                          Text(
                            feedback['feedback'] ?? 'لا يوجد محتوى',
                            style: TextStyle(
                              fontSize: Responsive.text(
                                context,
                                size: TextSize.small,
                              ),
                              color: Colors.grey[700],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(
                            height: Responsive.space(
                              context,
                              size: Space.medium,
                            ),
                          ),
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
                                formattedDate,
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
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
