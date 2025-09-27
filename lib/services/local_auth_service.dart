import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart' as local_auth;
import 'package:flutter/foundation.dart';

enum BiometricType { fingerprint, face, iris, unknown }

enum BiometricError {
  notAvailable,
  notEnrolled,
  lockedOut,
  permanentlyLockedOut,
  userCancel,
  systemCancel,
  passcodeNotSet,
  other,
}

class BiometricResult {
  final bool success;
  final BiometricError? error;
  final String? errorMessage;

  BiometricResult({required this.success, this.error, this.errorMessage});

  factory BiometricResult.success() => BiometricResult(success: true);

  factory BiometricResult.failure(BiometricError error, String message) =>
      BiometricResult(success: false, error: error, errorMessage: message);
}

class LocalAuthService {
  final local_auth.LocalAuthentication _auth = local_auth.LocalAuthentication();

  /// Check if biometric authentication is supported on the device
  Future<bool> isBiometricSupported() async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  /// Get available biometric types on the device
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final availableBiometrics = await _auth.getAvailableBiometrics();
      final biometricTypes = <BiometricType>[];

      for (final biometric in availableBiometrics) {
        switch (biometric) {
          case local_auth.BiometricType.fingerprint:
            biometricTypes.add(BiometricType.fingerprint);
            break;
          case local_auth.BiometricType.face:
            biometricTypes.add(BiometricType.face);
            break;
          case local_auth.BiometricType.iris:
            biometricTypes.add(BiometricType.iris);
            break;
          default:
            biometricTypes.add(BiometricType.unknown);
        }
      }

      return biometricTypes;
    } on PlatformException {
      return [];
    }
  }

  /// Get the primary biometric type (most common/preferred)
  Future<BiometricType> getPrimaryBiometricType() async {
    final availableTypes = await getAvailableBiometrics();
    if (availableTypes.isEmpty) return BiometricType.unknown;

    // Priority: Face > Fingerprint > Iris > Unknown
    if (availableTypes.contains(BiometricType.face)) return BiometricType.face;
    if (availableTypes.contains(BiometricType.fingerprint))
      return BiometricType.fingerprint;
    if (availableTypes.contains(BiometricType.iris)) return BiometricType.iris;
    return BiometricType.unknown;
  }

  /// Get user-friendly name for biometric type
  String getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.fingerprint:
        return 'البصمة';
      case BiometricType.face:
        return 'الوجه';
      case BiometricType.iris:
        return 'القزحية';
      case BiometricType.unknown:
        return 'المصادقة الحيوية';
    }
  }

  /// Check if biometric authentication is enrolled and ready to use
  Future<bool> isBiometricEnrolled() async {
    try {
      final availableBiometrics = await _auth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } on PlatformException {
      return false;
    }
  }

  /// Authenticate with enhanced error handling
  Future<BiometricResult> authenticate(String localizedReason) async {
    try {
      // Check if biometrics are available
      if (!await isBiometricSupported()) {
        return BiometricResult.failure(
          BiometricError.notAvailable,
          'المصادقة الحيوية غير متاحة على هذا الجهاز',
        );
      }

      // Check if biometrics are enrolled
      if (!await isBiometricEnrolled()) {
        return BiometricResult.failure(
          BiometricError.notEnrolled,
          'لم يتم إعداد المصادقة الحيوية على هذا الجهاز',
        );
      }

      final result = await _auth.authenticate(
        localizedReason: localizedReason,
        options: const local_auth.AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      return result
          ? BiometricResult.success()
          : BiometricResult.failure(
            BiometricError.userCancel,
            'تم إلغاء المصادقة',
          );
    } on PlatformException catch (e) {
      return _handlePlatformException(e);
    } catch (e) {
      if (kDebugMode) {
        print('Biometric authentication error: $e');
      }
      return BiometricResult.failure(
        BiometricError.other,
        'حدث خطأ غير متوقع أثناء المصادقة',
      );
    }
  }

  /// Handle platform-specific exceptions
  BiometricResult _handlePlatformException(PlatformException e) {
    switch (e.code) {
      case 'NotAvailable':
        return BiometricResult.failure(
          BiometricError.notAvailable,
          'المصادقة الحيوية غير متاحة',
        );
      case 'NotEnrolled':
        return BiometricResult.failure(
          BiometricError.notEnrolled,
          'لم يتم إعداد المصادقة الحيوية',
        );
      case 'LockedOut':
        return BiometricResult.failure(
          BiometricError.lockedOut,
          'تم قفل المصادقة الحيوية مؤقتاً. حاول مرة أخرى لاحقاً',
        );
      case 'PermanentlyLockedOut':
        return BiometricResult.failure(
          BiometricError.permanentlyLockedOut,
          'تم قفل المصادقة الحيوية نهائياً. يرجى إعادة إعدادها',
        );
      case 'UserCancel':
        return BiometricResult.failure(
          BiometricError.userCancel,
          'تم إلغاء المصادقة',
        );
      case 'SystemCancel':
        return BiometricResult.failure(
          BiometricError.systemCancel,
          'تم إلغاء المصادقة من قبل النظام',
        );
      case 'PasscodeNotSet':
        return BiometricResult.failure(
          BiometricError.passcodeNotSet,
          'يرجى إعداد رمز المرور أولاً',
        );
      default:
        return BiometricResult.failure(
          BiometricError.other,
          'حدث خطأ أثناء المصادقة: ${e.message ?? 'خطأ غير معروف'}',
        );
    }
  }

  /// Get biometric authentication statistics
  Future<Map<String, dynamic>> getBiometricStats() async {
    try {
      final isSupported = await isBiometricSupported();
      final isEnrolled = await isBiometricEnrolled();
      final availableTypes = await getAvailableBiometrics();
      final primaryType = await getPrimaryBiometricType();

      return {
        'isSupported': isSupported,
        'isEnrolled': isEnrolled,
        'availableTypes': availableTypes.map((e) => e.toString()).toList(),
        'primaryType': primaryType.toString(),
        'primaryTypeName': getBiometricTypeName(primaryType),
        'canAuthenticate': isSupported && isEnrolled,
      };
    } catch (e) {
      return {
        'isSupported': false,
        'isEnrolled': false,
        'availableTypes': [],
        'primaryType': BiometricType.unknown.toString(),
        'primaryTypeName': getBiometricTypeName(BiometricType.unknown),
        'canAuthenticate': false,
        'error': e.toString(),
      };
    }
  }
}
