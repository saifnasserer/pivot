import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/widgets/unified_dialog.dart';
import 'package:pivot/services/data_deletion_service.dart';

class DataDeletionDialog extends StatefulWidget {
  const DataDeletionDialog({super.key});

  @override
  State<DataDeletionDialog> createState() => _DataDeletionDialogState();
}

class _DataDeletionDialogState extends State<DataDeletionDialog> {
  bool _isLoading = false;
  bool _isDeleting = false;
  bool _confirmDeletion = false;
  Map<String, int> _dataSummary = {};
  final TextEditingController _confirmationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDataSummary();
  }

  @override
  void dispose() {
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _loadDataSummary() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final summary = await DataDeletionService.getDataSummary(user.uid);
        setState(() {
          _dataSummary = summary;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل بيانات المستخدم: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteUserData() async {
    setState(() => _isDeleting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }

      // Delete all user data
      final dataDeleted = await DataDeletionService.deleteAllUserData(user.uid);

      if (!dataDeleted) {
        throw Exception('فشل في حذف بعض البيانات');
      }

      // Delete Firebase Auth account
      final authDeleted = await DataDeletionService.deleteAuthAccount();

      if (!authDeleted) {
        throw Exception('فشل في حذف حساب المستخدم');
      }

      if (mounted) {
        Navigator.of(context).pop();
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف جميع بياناتك بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حذف البيانات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return UnifiedDialog(
      title: 'حذف جميع البيانات',
      subtitle: 'هذا الإجراء لا يمكن التراجع عنه',
      content: _buildContent(),
      onCancel: () => Navigator.of(context).pop(),
      onConfirm: _confirmDeletion ? _deleteUserData : null,
      confirmText: 'حذف نهائي',
      confirmIcon: Icons.delete_forever,
      isLoading: _isDeleting,
      cancelText: 'إلغاء',
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Warning section
          Container(
            padding: EdgeInsets.all(
              Responsive.space(context, size: Space.medium),
            ),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(
                Responsive.space(context, size: Space.medium),
              ),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red[700],
                  size: Responsive.text(context, size: TextSize.heading),
                ),
                SizedBox(width: Responsive.space(context, size: Space.small)),
                Expanded(
                  child: Text(
                    'تحذير: هذا الإجراء سيمسح جميع بياناتك نهائياً ولن يمكن استردادها',
                    style: TextStyle(
                      fontSize: Responsive.text(context, size: TextSize.medium),
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: Responsive.space(context, size: Space.large)),

          // Data summary
          Text(
            'البيانات التي سيتم حذفها:',
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.medium),
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          SizedBox(height: Responsive.space(context, size: Space.medium)),

          _buildDataItem(
            'المنشورات',
            _dataSummary['posts'] ?? 0,
            Icons.article,
          ),
          _buildDataItem(
            'التعليقات',
            _dataSummary['comments'] ?? 0,
            Icons.comment,
          ),
          _buildDataItem(
            'الإشعارات',
            _dataSummary['notifications'] ?? 0,
            Icons.notifications,
          ),
          _buildDataItem(
            'الجدول الدراسي',
            _dataSummary['schedule'] ?? 0,
            Icons.schedule,
          ),
          _buildDataItem(
            'المهام',
            _dataSummary['tasks'] ?? 0,
            Icons.assignment,
          ),
          _buildDataItem(
            'الإعلانات',
            _dataSummary['announcements'] ?? 0,
            Icons.campaign,
          ),
          _buildDataItem(
            'التقارير',
            _dataSummary['reports'] ?? 0,
            Icons.report,
          ),

          SizedBox(height: Responsive.space(context, size: Space.large)),

          // Confirmation section
          Text(
            'للتأكيد، اكتب "حذف" في المربع أدناه:',
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.medium),
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          SizedBox(height: Responsive.space(context, size: Space.small)),

          TextField(
            controller: _confirmationController,
            decoration: InputDecoration(
              hintText: 'اكتب "حذف" هنا',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  Responsive.space(context, size: Space.medium),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  Responsive.space(context, size: Space.medium),
                ),
                borderSide: BorderSide(color: Colors.red, width: 2),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _confirmDeletion = value.toLowerCase() == 'حذف';
              });
            },
          ),

          SizedBox(height: Responsive.space(context, size: Space.large)),

          // Additional info
          Container(
            padding: EdgeInsets.all(
              Responsive.space(context, size: Space.medium),
            ),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(
                Responsive.space(context, size: Space.medium),
              ),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue[700],
                      size: Responsive.text(context, size: TextSize.medium),
                    ),
                    SizedBox(
                      width: Responsive.space(context, size: Space.small),
                    ),
                    Text(
                      'معلومات إضافية:',
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.medium,
                        ),
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Responsive.space(context, size: Space.small)),
                Text(
                  '• سيتم حذف حسابك نهائياً من النظام\n'
                  '• لن تتمكن من الوصول للتطبيق بعد الحذف\n'
                  '• يمكنك إنشاء حساب جديد في أي وقت\n'
                  '• البيانات المحذوفة لا يمكن استردادها',
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.small),
                    color: Colors.blue[600],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataItem(String label, int count, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: Responsive.space(context, size: Space.small),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: Responsive.text(context, size: TextSize.medium),
            color: Colors.grey[600],
          ),
          SizedBox(width: Responsive.space(context, size: Space.small)),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.medium),
                color: Colors.black87,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.space(context, size: Space.small),
              vertical: Responsive.space(context, size: Space.tiny),
            ),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(
                Responsive.space(context, size: Space.small),
              ),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.small),
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
