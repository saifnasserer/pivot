import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/auth/repositories/auth_repository.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/services/auth_service.dart';

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

  Future<UserProfile?> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repo.signInWithEmailAndPassword(email, password);
      state = state.copyWith(isLoading: false, user: user);
      return user;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<UserProfile?> signup({
    required String email,
    required String password,
    required Map<String, dynamic> userData,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repo.signUpWithEmailAndPassword(
        email,
        password,
        userData,
      );
      state = state.copyWith(isLoading: false, user: user);
      return user;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> logout() async {
    await _repo.signOut();
    state = const AuthState();
  }
}
