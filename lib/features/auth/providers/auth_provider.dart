import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/auth/repositories/auth_repository.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/services/auth_service.dart';
import 'package:pivot/features/tasks/providers/tasks_provider.dart';
import 'package:pivot/services/biometric_settings_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final svc = ref.watch(authServiceProvider);
  return AuthRepository(svc);
});

class AuthState {
  final bool isLoading;
  final UserProfile? user;
  final String? error;
  const AuthState({this.isLoading = false, this.user, this.error});
  AuthState copyWith({bool? isLoading, UserProfile? user, String? error}) =>
      AuthState(
        isLoading: isLoading ?? this.isLoading,
        user: user ?? this.user,
        error: error ?? this.error,
      );
}

final authProvider = StateNotifierProvider.autoDispose<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref),
);

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._ref) : super(const AuthState());

  final Ref _ref;
  late final AuthRepository _repo = _ref.read(authRepositoryProvider);
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _checkDisposed() {
    if (_disposed) {
      throw StateError('AuthNotifier has been disposed');
    }
  }

  Future<UserProfile?> login(String email, String password) async {
    _checkDisposed();
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repo.signInWithEmailAndPassword(email, password);
      if (!_disposed) {
        state = state.copyWith(isLoading: false, user: user);
      }

      // Auto-enable biometric on successful login if device supports it
      if (user != null) {
        try {
          final biometricService = BiometricSettingsService();
          final hasCredentials =
              (await biometricService.getBiometricCredentials())['email'] !=
              null;

          // Only enable if not already set up, to avoid overwriting on every login
          if (!hasCredentials) {
            print('🔐 [Auth] Auto-enabling biometric for first-time login...');
            final enabled = await biometricService.enableBiometric(
              email,
              password,
            );
            if (enabled) {
              print('✅ [Auth] Biometric auto-enabled successfully');
            } else {
              print('📱 [Auth] Biometric not available on this device');
            }
          }
        } catch (e) {
          print('⚠️ [Auth] Could not auto-enable biometric: $e');
          // Don't rethrow - biometric is optional
        }
      }

      return user;
    } catch (e) {
      if (!_disposed) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
      rethrow;
    }
  }

  Future<UserProfile?> signup({
    required String email,
    required String password,
    required Map<String, dynamic> userData,
  }) async {
    _checkDisposed();
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repo.signUpWithEmailAndPassword(
        email,
        password,
        userData,
      );
      if (!_disposed) {
        state = state.copyWith(isLoading: false, user: user);
      }
      return user;
    } catch (e) {
      if (!_disposed) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    _checkDisposed();

    // Clear all provider states before logout
    print('🗑️ AuthProvider: Clearing all provider states...');
    try {
      // Reset tasks provider
      _ref.read(tasksProvider.notifier).resetState();

      print('✅ AuthProvider: All provider states cleared');
    } catch (e) {
      print('⚠️ AuthProvider: Error clearing providers: $e');
      // Continue with logout even if clearing fails
    }

    // Perform logout
    await _repo.signOut();
    if (!_disposed) {
      state = const AuthState();
    }
  }
}
