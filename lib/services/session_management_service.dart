import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pivot/features/onboarding/screens/login/login.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/widgets/unified_dialog.dart';

class SessionManagementService {
  static final SessionManagementService _instance =
      SessionManagementService._internal();
  factory SessionManagementService() => _instance;
  SessionManagementService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Check if the current user session is recent enough for sensitive operations
  /// Firebase requires recent authentication for operations like password changes
  Future<bool> isSessionRecent() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    // Check if user was recently authenticated (within last 5 minutes)
    final lastSignInTime = user.metadata.lastSignInTime;
    if (lastSignInTime == null) return false;

    final now = DateTime.now();
    final timeDifference = now.difference(lastSignInTime);

    // Consider session recent if last sign in was within 5 minutes
    return timeDifference.inMinutes < 5;
  }

  /// Get the time since last authentication
  Duration? getTimeSinceLastAuth() {
    final user = _auth.currentUser;
    if (user?.metadata.lastSignInTime == null) return null;

    return DateTime.now().difference(user!.metadata.lastSignInTime!);
  }

  /// Re-authenticate user with current password
  Future<bool> reauthenticateUser(String currentPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) return false;

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      return true;
    } catch (e) {
      //debugprint('Re-authentication failed: $e');
      return false;
    }
  }

  /// Handle session expiration by showing appropriate dialog
  Future<bool> handleSessionExpiration(BuildContext context) async {
    final timeSinceAuth = getTimeSinceLastAuth();

    if (timeSinceAuth == null) {
      // No authentication history, require re-login
      return await _showSessionExpiredDialog(context, 'يجب إعادة تسجيل الدخول');
    }

    if (timeSinceAuth.inMinutes >= 5) {
      // Session is old, show warning
      return await _showSessionExpiredDialog(
        context,
        'انتهت صلاحية الجلسة. يجب إعادة تسجيل الدخول للمتابعة.',
      );
    }

    return true; // Session is still valid
  }

  /// Show session expired dialog with options
  Future<bool> _showSessionExpiredDialog(
    BuildContext context,
    String message,
  ) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return UnifiedDialog(
              title: 'انتهت صلاحية الجلسة',
              subtitle: 'يجب إعادة تسجيل الدخول للمتابعة',
              content: Container(
                padding: EdgeInsets.all(
                  Responsive.space(context, size: Space.medium),
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    Responsive.space(context, size: Space.large),
                  ),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: Responsive.space(context, size: Space.large),
                    ),
                    SizedBox(
                      width: Responsive.space(context, size: Space.medium),
                    ),
                    Expanded(
                      child: Text(
                        message,
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
                  ],
                ),
              ),
              confirmText: 'تسجيل الدخول',
              confirmIcon: Icons.login,
              onConfirm: () async {
                Navigator.of(context).pop(true);
                await _navigateToLogin(context);
              },
              onCancel: () => Navigator.of(context).pop(false),
            );
          },
        ) ??
        false;
  }

  /// Navigate to login screen and clear current session
  Future<void> _navigateToLogin(BuildContext context) async {
    try {
      // Sign out current user
      await _auth.signOut();

      // Navigate to login screen
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      //debugprint('Error navigating to login: $e');
    }
  }

  /// Validate session before sensitive operations
  Future<SessionValidationResult> validateSessionForSensitiveOperation(
    BuildContext context,
    String currentPassword,
  ) async {
    // First check if session is recent
    if (await isSessionRecent()) {
      // Session is recent, try to re-authenticate with provided password
      final reauthSuccess = await reauthenticateUser(currentPassword);
      if (reauthSuccess) {
        return SessionValidationResult.success();
      } else {
        return SessionValidationResult.wrongPassword();
      }
    } else {
      // Session is not recent, handle expiration
      final shouldProceed = await handleSessionExpiration(context);
      if (shouldProceed) {
        return SessionValidationResult.sessionExpired();
      } else {
        return SessionValidationResult.cancelled();
      }
    }
  }

  /// Get user-friendly message for session status
  String getSessionStatusMessage() {
    final timeSinceAuth = getTimeSinceLastAuth();
    if (timeSinceAuth == null) {
      return 'لم يتم تسجيل الدخول';
    }

    if (timeSinceAuth.inMinutes < 5) {
      return 'الجلسة صالحة';
    } else if (timeSinceAuth.inMinutes < 60) {
      return 'الجلسة منتهية الصلاحية (${timeSinceAuth.inMinutes} دقيقة)';
    } else {
      return 'الجلسة منتهية الصلاحية (${timeSinceAuth.inHours} ساعة)';
    }
  }

  /// Test method to simulate session expiration (for debugging)
  Future<void> simulateSessionExpiration() async {
    // This method is for testing purposes only
    // In a real scenario, you would wait for the actual session to expire
    //debugprint('Session expiration simulation requested');
  }

  /// Get detailed session information for debugging
  Map<String, dynamic> getSessionInfo() {
    final user = _auth.currentUser;
    final timeSinceAuth = getTimeSinceLastAuth();

    return {
      'user_id': user?.uid,
      'user_email': user?.email,
      'is_authenticated': user != null,
      'last_sign_in': user?.metadata.lastSignInTime?.toIso8601String(),
      'time_since_auth': timeSinceAuth?.inMinutes,
      'session_recent':
          timeSinceAuth != null ? timeSinceAuth.inMinutes < 5 : false,
      'status_message': getSessionStatusMessage(),
    };
  }
}

/// Result of session validation
class SessionValidationResult {
  final bool isValid;
  final String? errorMessage;
  final SessionValidationError? error;

  SessionValidationResult._({
    required this.isValid,
    this.errorMessage,
    this.error,
  });

  factory SessionValidationResult.success() {
    return SessionValidationResult._(isValid: true);
  }

  factory SessionValidationResult.wrongPassword() {
    return SessionValidationResult._(
      isValid: false,
      errorMessage: 'كلمة المرور الحالية غير صحيحة',
      error: SessionValidationError.wrongPassword,
    );
  }

  factory SessionValidationResult.sessionExpired() {
    return SessionValidationResult._(
      isValid: false,
      errorMessage: 'انتهت صلاحية الجلسة',
      error: SessionValidationError.sessionExpired,
    );
  }

  factory SessionValidationResult.cancelled() {
    return SessionValidationResult._(
      isValid: false,
      errorMessage: 'تم إلغاء العملية',
      error: SessionValidationError.cancelled,
    );
  }
}

/// Types of session validation errors
enum SessionValidationError { wrongPassword, sessionExpired, cancelled }
