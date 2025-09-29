import 'package:pivot/models/user_profile.dart';
import 'package:pivot/services/auth_service.dart';

class AuthRepository {
  AuthRepository(this._authService);

  final AuthService _authService;

  Future<UserProfile?> signInWithEmailAndPassword(
    String email,
    String password,
  ) {
    return _authService.signInWithEmailAndPassword(email, password);
  }

  Future<UserProfile?> signUpWithEmailAndPassword(
    String email,
    String password,
    Map<String, dynamic> userData,
  ) {
    return _authService.signUpWithEmailAndPassword(email, password, userData);
  }

  Future<void> signOut() {
    return _authService.signOut();
  }
}
