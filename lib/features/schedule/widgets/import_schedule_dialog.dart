import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/services/schedule_sharing_service.dart';
import 'package:pivot/features/schedule/providers/schedule_provider.dart';
import 'package:pivot/models/shared_schedule.dart';
import 'package:pivot/widgets/unified_dialog.dart';
import 'dart:ui' as ui;

class ImportScheduleDialog extends ConsumerStatefulWidget {
  const ImportScheduleDialog({super.key});

  @override
  ConsumerState<ImportScheduleDialog> createState() =>
      _ImportScheduleDialogState();
}

class _ImportScheduleDialogState extends ConsumerState<ImportScheduleDialog> {
  final _linkController = TextEditingController();
  final _sharingService = ScheduleSharingService();

  bool _isLoading = false;
  SharedSchedule? _previewSchedule;

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _loadPreview() async {
    final input = _linkController.text.trim();
    if (input.isEmpty) {
      _showError('يرجى إدخال معرف الجدول');
      return;
    }

    // Extract share ID from URL if it's a URL, otherwise use input as-is
    final shareId =
        ScheduleSharingService.extractShareIdFromUrl(input) ?? input;

    if (!ScheduleSharingService.isValidShareId(shareId)) {
      _showError('معرف الجدول غير صحيح. تأكد من نسخ المعرف بالكامل.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final sharedSchedule = await _sharingService.getSharedSchedule(shareId);

      if (sharedSchedule != null) {
        setState(() {
          _previewSchedule = sharedSchedule;
        });
      } else {
        _showError('الرابط غير صحيح أو منتهي الصلاحية');
      }
    } catch (e) {
      _showError('حدث خطأ: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _importSchedule() async {
    if (_previewSchedule == null) return;

    final shareId = _previewSchedule!.shareId;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _sharingService.importSharedSchedule(shareId);

      if (success) {
        if (mounted) {
          // Close dialog first
          Navigator.pop(context);

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم استيراد الجدول بنجاح'),
              backgroundColor: Colors.green.shade600,
              duration: Duration(seconds: 2),
            ),
          );

          // Force refresh the schedule provider after a short delay
          // This ensures the provider is not disposed
          Future.delayed(Duration(milliseconds: 300), () {
            if (mounted) {
              ref.read(scheduleProvider.notifier).fetchSchedule();
            }
          });
        }
      } else {
        _showError('فشل في استيراد الجدول');
      }
    } catch (e) {
      _showError('حدث خطأ: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
              _previewSchedule == null ? _buildImportForm() : _buildPreview(),
        ),
      ),
    );
  }

  Widget _buildImportForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(
              Icons.download,
              color: Colors.black,
              size: Responsive.text(context, size: TextSize.heading),
            ),
            SizedBox(width: Responsive.space(context, size: Space.small)),
            Text(
              'استيراد جدول',
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
        UnifiedSectionHeader(
          title: 'أدخل معرف الجدول المشترك',
          icon: Icons.key,
        ),
        Text(
          'يمكنك لصق المعرف الذي حصلت عليه من صديقك',
          style: TextStyle(
            fontSize: Responsive.text(context, size: TextSize.small),
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(height: Responsive.space(context, size: Space.medium)),

        // ID input field
        UnifiedFormField(
          controller: _linkController,
          label: 'معرف الجدول',
          hint: 'مثال: 4b98fa66-518b-4d10-96ef-f690691e3227',
          prefixIcon: Icon(Icons.key),
          maxLines: 2,
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
                onPressed: _isLoading ? null : _loadPreview,
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
                        : Text('معاينة'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPreview() {
    final schedule = _previewSchedule!;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.preview,
                color: Colors.black,
                size: Responsive.text(context, size: TextSize.heading),
              ),
              SizedBox(width: Responsive.space(context, size: Space.small)),
              Text(
                'معاينة الجدول',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.heading),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  setState(() {
                    _previewSchedule = null;
                  });
                },
                icon: Icon(Icons.arrow_back, color: Colors.black),
                iconSize: Responsive.text(context, size: TextSize.medium),
              ),
            ],
          ),
          SizedBox(height: Responsive.space(context, size: Space.large)),

          // Schedule info
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(
              Responsive.space(context, size: Space.medium),
            ),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(
                Responsive.space(context, size: Space.medium),
              ),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.title,
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.medium),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (schedule.description.isNotEmpty) ...[
                  SizedBox(
                    height: Responsive.space(context, size: Space.small),
                  ),
                  Text(
                    schedule.description,
                    style: TextStyle(
                      fontSize: Responsive.text(context, size: TextSize.small),
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
                SizedBox(height: Responsive.space(context, size: Space.medium)),
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                    SizedBox(
                      width: Responsive.space(context, size: Space.small),
                    ),
                    Text(
                      'بواسطة: ${schedule.ownerName}',
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.small,
                        ),
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Responsive.space(context, size: Space.small)),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                    SizedBox(
                      width: Responsive.space(context, size: Space.small),
                    ),
                    Text(
                      '${schedule.items.length} عنصر',
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.small,
                        ),
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: Responsive.space(context, size: Space.medium)),

          // Items preview
          Container(
            constraints: BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(
                Responsive.space(context, size: Space.medium),
              ),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: schedule.items.length > 5 ? 5 : schedule.items.length,
              itemBuilder: (context, index) {
                final item = schedule.items[index];
                return ListTile(
                  leading: Icon(
                    item.type.toString().contains('lecture')
                        ? Icons.school
                        : Icons.group,
                    color: Colors.black,
                    size: 20,
                  ),
                  title: Text(
                    item.title,
                    style: TextStyle(
                      fontSize: Responsive.text(context, size: TextSize.small),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    '${item.time} - ${item.day}',
                    style: TextStyle(
                      fontSize:
                          Responsive.text(context, size: TextSize.small) * 0.9,
                      color: Colors.grey.shade600,
                    ),
                  ),
                );
              },
            ),
          ),

          if (schedule.items.length > 5)
            Padding(
              padding: EdgeInsets.all(
                Responsive.space(context, size: Space.small),
              ),
              child: Text(
                'و ${schedule.items.length - 5} عناصر أخرى...',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.small),
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          SizedBox(height: Responsive.space(context, size: Space.large)),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _previewSchedule = null;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('رجوع'),
                ),
              ),
              SizedBox(width: Responsive.space(context, size: Space.small)),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _importSchedule,
                  icon:
                      _isLoading
                          ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : Icon(Icons.download, size: 18),
                  label: Text(_isLoading ? 'جاري...' : 'استيراد'),
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
}
