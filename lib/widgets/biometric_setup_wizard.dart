import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:pivot/services/biometric_settings_service.dart';
import 'package:pivot/services/local_auth_service.dart';
import 'package:pivot/responsive.dart';

class BiometricSetupWizard extends StatefulWidget {
  final String email;
  final String password;
  final VoidCallback? onComplete;
  final VoidCallback? onSkip;

  const BiometricSetupWizard({
    super.key,
    required this.email,
    required this.password,
    this.onComplete,
    this.onSkip,
  });

  @override
  State<BiometricSetupWizard> createState() => _BiometricSetupWizardState();
}

class _BiometricSetupWizardState extends State<BiometricSetupWizard> {
  final BiometricSettingsService _biometricService = BiometricSettingsService();
  final LocalAuthService _localAuthService = LocalAuthService();

  int _currentStep = 0;
  bool _isLoading = false;
  bool _isSupported = false;
  bool _isEnrolled = false;
  String _primaryTypeName = 'المصادقة الحيوية';

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    setState(() => _isLoading = true);

    try {
      final stats = await _localAuthService.getBiometricStats();
      setState(() {
        _isSupported = stats['isSupported'] ?? false;
        _isEnrolled = stats['isEnrolled'] ?? false;
        _primaryTypeName = stats['primaryTypeName'] ?? 'المصادقة الحيوية';
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error checking biometric availability: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _setupBiometric() async {
    if (!_isSupported || !_isEnrolled) return;

    setState(() => _isLoading = true);

    try {
      // Test biometric authentication first
      final authResult = await _localAuthService.authenticate(
        'تأكيد إعداد المصادقة الحيوية',
      );

      if (authResult.success) {
        // Enable biometric with credentials
        final success = await _biometricService.enableBiometric(
          widget.email,
          widget.password,
        );

        if (success) {
          setState(() => _currentStep = 2); // Success step
          widget.onComplete?.call();
        } else {
          _showErrorMessage('فشل في حفظ بيانات المصادقة الحيوية');
        }
      } else {
        _showErrorMessage(authResult.errorMessage ?? 'فشل في المصادقة');
      }
    } catch (e) {
      _showErrorMessage('حدث خطأ أثناء الإعداد: $e');
    } finally {
      setState(() => _isLoading = false);
    }
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: Responsive.space(context, size: Space.large) * 8,
          maxHeight: Responsive.space(context, size: Space.large) * 12,
        ),
        padding: EdgeInsets.all(Responsive.space(context, size: Space.large)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            SizedBox(height: Responsive.space(context, size: Space.large)),
            _buildContent(),
            SizedBox(height: Responsive.space(context, size: Space.large)),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Icon(
          Icons.fingerprint,
          size: Responsive.space(context, size: Space.large) * 3,
          color: Colors.blue[600],
        ),
        SizedBox(height: Responsive.space(context, size: Space.medium)),
        Text(
          'إعداد المصادقة الحيوية',
          style: TextStyle(
            fontSize: Responsive.text(context, size: TextSize.heading),
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: Responsive.space(context, size: Space.small)),
        Text(
          'تسجيل الدخول السريع والآمن',
          style: TextStyle(
            fontSize: Responsive.text(context, size: TextSize.medium),
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (_currentStep) {
      case 0:
        return _buildIntroductionStep();
      case 1:
        return _buildSetupStep();
      case 2:
        return _buildSuccessStep();
      default:
        return _buildIntroductionStep();
    }
  }

  Widget _buildIntroductionStep() {
    return Column(
      children: [
        if (!_isSupported) ...[
          _buildUnsupportedWidget(),
        ] else if (!_isEnrolled) ...[
          _buildNotEnrolledWidget(),
        ] else ...[
          _buildSupportedWidget(),
        ],
        SizedBox(height: Responsive.space(context, size: Space.medium)),
        _buildSecurityInfo(),
      ],
    );
  }

  Widget _buildUnsupportedWidget() {
    return Container(
      padding: EdgeInsets.all(Responsive.space(context, size: Space.medium)),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red[600], size: 48),
          SizedBox(height: Responsive.space(context, size: Space.small)),
          Text(
            'المصادقة الحيوية غير متاحة',
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.medium),
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          SizedBox(height: Responsive.space(context, size: Space.small)),
          Text(
            'هذا الجهاز لا يدعم المصادقة الحيوية',
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.small),
              color: Colors.red[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotEnrolledWidget() {
    return Container(
      padding: EdgeInsets.all(Responsive.space(context, size: Space.medium)),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange[600],
            size: 48,
          ),
          SizedBox(height: Responsive.space(context, size: Space.small)),
          Text(
            'لم يتم إعداد المصادقة الحيوية',
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.medium),
              fontWeight: FontWeight.bold,
              color: Colors.orange[700],
            ),
          ),
          SizedBox(height: Responsive.space(context, size: Space.small)),
          Text(
            'يرجى إعداد المصادقة الحيوية في إعدادات الجهاز أولاً',
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.small),
              color: Colors.orange[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSupportedWidget() {
    return Container(
      padding: EdgeInsets.all(Responsive.space(context, size: Space.medium)),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline, color: Colors.green[600], size: 48),
          SizedBox(height: Responsive.space(context, size: Space.small)),
          Text(
            'المصادقة الحيوية متاحة',
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.medium),
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
          SizedBox(height: Responsive.space(context, size: Space.small)),
          Text(
            'يمكنك استخدام $_primaryTypeName لتسجيل الدخول السريع',
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.small),
              color: Colors.green[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityInfo() {
    return Container(
      padding: EdgeInsets.all(Responsive.space(context, size: Space.medium)),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: Colors.blue[600], size: 20),
              SizedBox(width: Responsive.space(context, size: Space.small)),
              Text(
                'معلومات الأمان',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.medium),
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.space(context, size: Space.small)),
          Text(
            '• البيانات محفوظة بشكل آمن على الجهاز\n'
            '• لا يتم مشاركة البيانات مع أي جهة خارجية\n'
            '• يمكن إلغاء التفعيل في أي وقت\n'
            '• تسجيل الدخول أسرع وأكثر أماناً',
            style: TextStyle(
              fontSize: Responsive.text(context, size: TextSize.small),
              color: Colors.blue[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupStep() {
    return Column(
      children: [
        Icon(
          Icons.fingerprint,
          size: Responsive.space(context, size: Space.large) * 2,
          color: Colors.blue[600],
        ),
        SizedBox(height: Responsive.space(context, size: Space.medium)),
        Text(
          'تأكيد المصادقة الحيوية',
          style: TextStyle(
            fontSize: Responsive.text(context, size: TextSize.medium),
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: Responsive.space(context, size: Space.small)),
        Text(
          'يرجى استخدام $_primaryTypeName لتأكيد الإعداد',
          style: TextStyle(
            fontSize: Responsive.text(context, size: TextSize.small),
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSuccessStep() {
    return Column(
      children: [
        Icon(
          Icons.check_circle,
          size: Responsive.space(context, size: Space.large) * 2,
          color: Colors.green[600],
        ),
        SizedBox(height: Responsive.space(context, size: Space.medium)),
        Text(
          'تم الإعداد بنجاح!',
          style: TextStyle(
            fontSize: Responsive.text(context, size: TextSize.medium),
            fontWeight: FontWeight.bold,
            color: Colors.green[700],
          ),
        ),
        SizedBox(height: Responsive.space(context, size: Space.small)),
        Text(
          'يمكنك الآن استخدام $_primaryTypeName لتسجيل الدخول السريع',
          style: TextStyle(
            fontSize: Responsive.text(context, size: TextSize.small),
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildActions() {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    switch (_currentStep) {
      case 0:
        return _buildIntroductionActions();
      case 1:
        return _buildSetupActions();
      case 2:
        return _buildSuccessActions();
      default:
        return _buildIntroductionActions();
    }
  }

  Widget _buildIntroductionActions() {
    return Row(
      children: [
        if (!_isSupported || !_isEnrolled) ...[
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onSkip?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(
                  vertical: Responsive.space(context, size: Space.medium),
                ),
              ),
              child: Text(
                'تخطي',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.medium),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ] else ...[
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                setState(() => _currentStep = 1);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(
                  vertical: Responsive.space(context, size: Space.medium),
                ),
              ),
              child: Text(
                'متابعة',
                style: TextStyle(
                  fontSize: Responsive.text(context, size: TextSize.medium),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSetupActions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              setState(() => _currentStep = 0);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[300],
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(
                vertical: Responsive.space(context, size: Space.medium),
              ),
            ),
            child: Text(
              'رجوع',
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.medium),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(width: Responsive.space(context, size: Space.small)),
        Expanded(
          child: ElevatedButton(
            onPressed: _setupBiometric,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(
                vertical: Responsive.space(context, size: Space.medium),
              ),
            ),
            child: Text(
              'تأكيد',
              style: TextStyle(
                fontSize: Responsive.text(context, size: TextSize.medium),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessActions() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[600],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(
            vertical: Responsive.space(context, size: Space.medium),
          ),
        ),
        child: Text(
          'تم',
          style: TextStyle(
            fontSize: Responsive.text(context, size: TextSize.medium),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
