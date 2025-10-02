import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/services/schedule_sharing_service.dart';
import 'package:pivot/screens/models/schedule_item.dart';

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
    return Dialog(
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
    );
  }

  Widget _buildCreateForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.share,
              color: Colors.green.shade600,
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
              icon: Icon(Icons.close),
              iconSize: Responsive.text(context, size: TextSize.medium),
            ),
          ],
        ),
        SizedBox(height: Responsive.space(context, size: Space.large)),

        // Title field
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: 'عنوان الجدول',
            hintText: 'مثال: جدول الفصل الأول 2024',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                Responsive.space(context, size: Space.small),
              ),
            ),
            prefixIcon: Icon(Icons.title),
          ),
          maxLines: 1,
        ),
        SizedBox(height: Responsive.space(context, size: Space.medium)),

        // Description field
        TextField(
          controller: _descriptionController,
          decoration: InputDecoration(
            labelText: 'وصف الجدول (اختياري)',
            hintText: 'وصف مختصر عن الجدول...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                Responsive.space(context, size: Space.small),
              ),
            ),
            prefixIcon: Icon(Icons.description),
          ),
          maxLines: 3,
        ),
        SizedBox(height: Responsive.space(context, size: Space.medium)),

        // Expiry options
        Text(
          'مدة صلاحية الرابط:',
          style: TextStyle(
            fontSize: Responsive.text(context, size: TextSize.medium),
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: Responsive.space(context, size: Space.small)),

        Row(
          children: [
            Radio<bool>(
              value: true,
              groupValue: _neverExpires,
              onChanged: (value) {
                setState(() {
                  _neverExpires = value!;
                });
              },
            ),
            Text('لا ينتهي'),
            SizedBox(width: Responsive.space(context, size: Space.large)),
            Radio<bool>(
              value: false,
              groupValue: _neverExpires,
              onChanged: (value) {
                setState(() {
                  _neverExpires = value!;
                  _expiryDate = DateTime.now().add(const Duration(days: 7));
                });
              },
            ),
            Text('ينتهي خلال أسبوع'),
          ],
        ),

        SizedBox(height: Responsive.space(context, size: Space.large)),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('إلغاء'),
              ),
            ),
            SizedBox(width: Responsive.space(context, size: Space.small)),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createShareLink,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
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
                        : Text('إنشاء رابط'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShareResult() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.check_circle,
          color: Colors.green.shade600,
          size: Responsive.text(context, size: TextSize.heading),
        ),
        SizedBox(height: Responsive.space(context, size: Space.medium)),
        Text(
          'تم إنشاء رابط المشاركة بنجاح!',
          style: TextStyle(
            fontSize: Responsive.text(context, size: TextSize.heading),
            fontWeight: FontWeight.bold,
            color: Colors.green.shade600,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: Responsive.space(context, size: Space.medium)),

        // Share link display
        Container(
          padding: EdgeInsets.all(
            Responsive.space(context, size: Space.medium),
          ),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(
              Responsive.space(context, size: Space.small),
            ),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'https://your-app-domain.com/schedule/$_generatedShareId',
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.small),
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: _copyToClipboard,
                icon: Icon(Icons.copy),
                tooltip: 'نسخ الرابط',
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
                child: Text('إغلاق'),
              ),
            ),
            SizedBox(width: Responsive.space(context, size: Space.small)),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _shareLink,
                icon: Icon(Icons.share),
                label: Text('مشاركة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _copyToClipboard() {
    // TODO: Implement clipboard functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نسخ الرابط إلى الحافظة'),
        backgroundColor: Colors.green.shade600,
      ),
    );
  }
}
