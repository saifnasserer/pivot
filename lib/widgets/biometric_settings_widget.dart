import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:pivot/services/biometric_settings_service.dart';
import 'package:pivot/services/local_auth_service.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/widgets/unified_dialog.dart';

class BiometricSettingsWidget extends StatefulWidget {
  const BiometricSettingsWidget({super.key});

  @override
  State<BiometricSettingsWidget> createState() =>
      _BiometricSettingsWidgetState();
}

class _BiometricSettingsWidgetState extends State<BiometricSettingsWidget> {
  final BiometricSettingsService _biometricService = BiometricSettingsService();
  final LocalAuthService _localAuthService = LocalAuthService();

  bool _isLoading = false;
  Map<String, dynamic> _biometricInfo = {};
  bool _isEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricInfo();
  }

  Future<void> _loadBiometricInfo() async {
    setState(() => _isLoading = true);

    try {
      final info = await _biometricService.getBiometricSetupInfo();
      setState(() {
        _biometricInfo = info;
        _isEnabled = info['isEnabled'] ?? false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading biometric info: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleBiometric() async {
    if (_isEnabled) {
      await _disableBiometric();
    } else {
      await _enableBiometric();
    }
  }

  Future<void> _enableBiometric() async {
    try {
      // Check if biometrics are available
      final stats = await _localAuthService.getBiometricStats();
      if (!stats['canAuthenticate']) {
        if (mounted) {
          _showBiometricNotAvailableDialog();
        }
        return;
      }

      // Show setup dialog
      final result = await _showBiometricSetupDialog();
      if (result == true && mounted) {
        await _loadBiometricInfo();
        _showSuccessMessage('تم تفعيل المصادقة الحيوية بنجاح');
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('فشل في تفعيل المصادقة الحيوية: $e');
      }
    }
  }

  Future<void> _disableBiometric() async {
    try {
      final result = await _showDisableConfirmationDialog();
      if (result == true) {
        await _biometricService.disableBiometric();
        await _loadBiometricInfo();
        if (mounted) {
          _showSuccessMessage('تم إلغاء تفعيل المصادقة الحيوية');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('فشل في إلغاء تفعيل المصادقة الحيوية: $e');
      }
    }
  }

  Future<bool?> _showBiometricSetupDialog() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => UnifiedDialog(
            title: 'إعداد المصادقة الحيوية',
            subtitle: 'سيتم حفظ بيانات تسجيل الدخول بشكل آمن',
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.fingerprint,
                  size: Responsive.space(context, size: Space.large) * 3,
                  color: Colors.blue[600],
                ),
                SizedBox(height: Responsive.space(context, size: Space.medium)),
                Text(
                  'سيتم استخدام ${_biometricInfo['primaryType'] ?? 'المصادقة الحيوية'} لتسجيل الدخول السريع',
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.medium),
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: Responsive.space(context, size: Space.medium)),
                Container(
                  padding: EdgeInsets.all(
                    Responsive.space(context, size: Space.medium),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.security,
                            color: Colors.blue[600],
                            size: 20,
                          ),
                          SizedBox(
                            width: Responsive.space(context, size: Space.small),
                          ),
                          Expanded(
                            child: Text(
                              'معلومات الأمان',
                              style: TextStyle(
                                fontSize: Responsive.text(
                                  context,
                                  size: TextSize.medium,
                                ),
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: Responsive.space(context, size: Space.small),
                      ),
                      Text(
                        '• البيانات محفوظة بشكل آمن على الجهاز\n'
                        '• يمكن إلغاء التفعيل في أي وقت\n'
                        '• لا يتم مشاركة البيانات مع أي جهة خارجية',
                        style: TextStyle(
                          fontSize: Responsive.text(
                            context,
                            size: TextSize.small,
                          ),
                          color: Colors.blue[600],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            onConfirm: () async {
              Navigator.of(context).pop(true);
              // The actual setup will be handled by the login flow
              // This dialog just confirms the user wants to proceed
            },
            onCancel: () => Navigator.of(context).pop(false),
            confirmText: 'متابعة',
            cancelText: 'إلغاء',
            confirmIcon: Icons.check,
          ),
    );
  }

  Future<bool?> _showDisableConfirmationDialog() async {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => UnifiedDialog(
            title: 'إلغاء تفعيل المصادقة الحيوية',
            subtitle: 'هل أنت متأكد من إلغاء التفعيل؟',
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: Responsive.space(context, size: Space.large) * 2,
                  color: Colors.orange,
                ),
                SizedBox(height: Responsive.space(context, size: Space.medium)),
                Text(
                  'سيتم حذف بيانات تسجيل الدخول المحفوظة ولن تتمكن من استخدام المصادقة الحيوية',
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.medium),
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            onConfirm: () => Navigator.of(context).pop(true),
            onCancel: () => Navigator.of(context).pop(false),
            confirmText: 'تأكيد الإلغاء',
            cancelText: 'إلغاء',
            confirmIcon: Icons.delete_forever,
          ),
    );
  }

  void _showBiometricNotAvailableDialog() {
    showDialog(
      context: context,
      builder:
          (context) => UnifiedDialog(
            title: 'المصادقة الحيوية غير متاحة',
            subtitle: 'لا يمكن تفعيل المصادقة الحيوية',
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: Responsive.space(context, size: Space.large) * 2,
                  color: Colors.red,
                ),
                SizedBox(height: Responsive.space(context, size: Space.medium)),
                Text(
                  'تأكد من:\n'
                  '• إعداد المصادقة الحيوية في إعدادات الجهاز\n'
                  '• تفعيل قفل الشاشة\n'
                  '• أن الجهاز يدعم المصادقة الحيوية',
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.medium),
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            onConfirm: () => Navigator.of(context).pop(),
            confirmText: 'حسناً',
            confirmIcon: Icons.check,
          ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(Responsive.space(context, size: Space.medium)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.space(context, size: Space.medium)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isEnabled ? Icons.fingerprint : Icons.fingerprint_outlined,
                color: _isEnabled ? Colors.green[600] : Colors.grey[600],
                size: 24,
              ),
              SizedBox(width: Responsive.space(context, size: Space.small)),
              Expanded(
                child: Text(
                  'المصادقة الحيوية',
                  style: TextStyle(
                    fontSize: Responsive.text(context, size: TextSize.heading),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              Switch(
                value: _isEnabled,
                onChanged: (value) => _toggleBiometric(),
                activeColor: Colors.green[600],
              ),
            ],
          ),

          if (_isEnabled) ...[
            SizedBox(height: Responsive.space(context, size: Space.medium)),
            _buildBiometricInfo(),
          ] else ...[
            SizedBox(height: Responsive.space(context, size: Space.small)),
            Text(
              'استخدم البصمة أو الوجه لتسجيل الدخول السريع',
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.small),
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBiometricInfo() {
    final primaryType = _biometricInfo['primaryType'] ?? 'غير معروف';
    final successRate = _biometricInfo['successRate'] ?? 0.0;
    final totalAttempts = _biometricInfo['totalAttempts'] ?? 0;
    final lastUsed = _biometricInfo['lastUsed'];

    return Container(
      padding: EdgeInsets.all(Responsive.space(context, size: Space.medium)),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.green[600], size: 20),
              SizedBox(width: Responsive.space(context, size: Space.small)),
              Text(
                'معلومات المصادقة الحيوية',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.medium),
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.space(context, size: Space.small)),
          _buildInfoRow('النوع', primaryType),
          if (totalAttempts > 0) ...[
            _buildInfoRow('معدل النجاح', '${successRate.toStringAsFixed(1)}%'),
            _buildInfoRow('إجمالي المحاولات', totalAttempts.toString()),
          ],
          if (lastUsed != null) ...[
            _buildInfoRow('آخر استخدام', _formatDate(lastUsed)),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: Responsive.space(context, size: Space.tiny),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.small),
              color: Colors.green[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.small),
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return 'منذ ${difference.inDays} يوم';
      } else if (difference.inHours > 0) {
        return 'منذ ${difference.inHours} ساعة';
      } else if (difference.inMinutes > 0) {
        return 'منذ ${difference.inMinutes} دقيقة';
      } else {
        return 'الآن';
      }
    } catch (e) {
      return 'غير معروف';
    }
  }
}
