import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/services/schedule_sharing_service.dart';
import 'package:pivot/screens/models/schedule_item.dart';
import 'package:pivot/widgets/unified_dialog.dart';
import 'dart:ui' as ui;

class ShareScheduleDialog extends ConsumerStatefulWidget {
  final Map<String, List<ScheduleItem>> schedule;

  const ShareScheduleDialog({super.key, required this.schedule});

  @override
  ConsumerState<ShareScheduleDialog> createState() =>
      _ShareScheduleDialogState();
}

class _ShareScheduleDialogState extends ConsumerState<ShareScheduleDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _sharingService = ScheduleSharingService();

  bool _isLoading = false;
  bool _neverExpires = true;
  DateTime? _expiryDate;
  String? _generatedShareId;

  @override
  void initState() {
    super.initState();
    _titleController.text = 'جدولي الدراسي';
    _descriptionController.text = 'جدول دراسي مشترك';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createShareLink() async {
    if (_titleController.text.trim().isEmpty) {
      _showError('يرجى إدخال عنوان للجدول');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Schedule is already in the correct format

      final shareId = await _sharingService.createShareableLink(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        schedule: widget.schedule,
        expiresAt: _neverExpires ? null : _expiryDate,
      );

      if (shareId != null) {
        setState(() {
          _generatedShareId = shareId;
        });
      } else {
        _showError('فشل في إنشاء رابط المشاركة');
      }
    } catch (e) {
      _showError('حدث خطأ: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _shareLink() async {
    if (_generatedShareId != null) {
      await _sharingService.shareScheduleLink(_generatedShareId!);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade600),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
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
          child:
              _generatedShareId == null
                  ? _buildCreateForm()
                  : _buildShareResult(),
        ),
      ),
    );
  }

  Widget _buildCreateForm() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.share,
                color: Colors.black,
                size: Responsive.text(context, size: TextSize.heading),
              ),
              SizedBox(width: Responsive.space(context, size: Space.small)),
              Text(
                'مشاركة الجدول',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.heading),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, color: Colors.black),
                iconSize: Responsive.text(context, size: TextSize.medium),
              ),
            ],
          ),
          SizedBox(height: Responsive.space(context, size: Space.large)),

          // Description
          Text(
            'ارفع الجدول علي الكلاود وشيرة مع صحابك',
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.small),
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: Responsive.space(context, size: Space.large)),

          // Title field
          UnifiedFormField(
            controller: _titleController,
            label: 'عنوان الجدول',
            hint: 'مثال: جدول الفصل الأول 2024',
            prefixIcon: Icon(Icons.title),
            maxLines: 1,
          ),
          SizedBox(height: Responsive.space(context, size: Space.medium)),

          // Description field
          UnifiedFormField(
            controller: _descriptionController,
            label: 'وصف الجدول (اختياري)',
            hint: 'وصف مختصر عن الجدول...',
            prefixIcon: Icon(Icons.description),
            maxLines: 3,
          ),
          SizedBox(height: Responsive.space(context, size: Space.medium)),

          // Expiry options
          UnifiedSectionHeader(
            title: 'مدة صلاحية الرابط',
            icon: Icons.timer_outlined,
          ),

          Row(
            children: [
              Radio<bool>(
                value: true,
                groupValue: _neverExpires,
                activeColor: Colors.black,
                onChanged: (value) {
                  setState(() {
                    _neverExpires = value!;
                  });
                },
              ),
              Text(
                'لا ينتهي',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.small),
                ),
              ),
              SizedBox(width: Responsive.space(context, size: Space.large)),
              Radio<bool>(
                value: false,
                groupValue: _neverExpires,
                activeColor: Colors.black,
                onChanged: (value) {
                  setState(() {
                    _neverExpires = value!;
                    _expiryDate = DateTime.now().add(const Duration(days: 7));
                  });
                },
              ),
              Text(
                'ينتهي خلال أسبوع',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.small),
                ),
              ),
            ],
          ),

          SizedBox(height: Responsive.space(context, size: Space.large)),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('إلغاء'),
                ),
              ),
              SizedBox(width: Responsive.space(context, size: Space.small)),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createShareLink,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child:
                      _isLoading
                          ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : Text('إنشاء معرف'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShareResult() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Success icon
          Container(
            padding: EdgeInsets.all(
              Responsive.space(context, size: Space.large),
            ),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              color: Colors.green.shade600,
              size: 48,
            ),
          ),
          SizedBox(height: Responsive.space(context, size: Space.large)),

          Text(
            'تم حفظ الجدول بنجاح!',
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.heading),
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: Responsive.space(context, size: Space.small)),
          Text(
            'يمكن للآخرين استيراد هذا الجدول باستخدام المعرف التالي',
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.small),
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: Responsive.space(context, size: Space.large)),

          // Share ID display
          Container(
            padding: EdgeInsets.all(
              Responsive.space(context, size: Space.medium),
            ),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(
                Responsive.space(context, size: Space.medium),
              ),
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.key, size: 16, color: Colors.grey.shade700),
                    SizedBox(
                      width: Responsive.space(context, size: Space.small),
                    ),
                    Text(
                      'معرف الجدول',
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.small,
                        ),
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Responsive.space(context, size: Space.medium)),
                SelectableText(
                  _generatedShareId ?? '',
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.small),
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: Responsive.space(context, size: Space.medium)),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _copyToClipboard,
                    icon: Icon(Icons.copy, size: 18),
                    label: Text('نسخ المعرف'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: Responsive.space(context, size: Space.large)),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('إغلاق'),
                ),
              ),
              SizedBox(width: Responsive.space(context, size: Space.small)),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _shareLink,
                  icon: Icon(Icons.share, size: 18),
                  label: Text('مشاركة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _copyToClipboard() async {
    if (_generatedShareId != null) {
      await Clipboard.setData(ClipboardData(text: _generatedShareId!));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم نسخ المعرف إلى الحافظة'),
            backgroundColor: Colors.black,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
