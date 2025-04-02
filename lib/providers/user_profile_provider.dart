import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';

class UserProfileProvider with ChangeNotifier {
  UserProfile? _userProfile;

  UserProfile? get userProfile => _userProfile;

  void setUserProfile(UserProfile profile) {
    _userProfile = profile;
    notifyListeners();
  }

  void updateUserProfile({
    String? name,
    String? email,
    String? universityId,
    String? department,
    String? level,
    String? profileImageUrl,
  }) {
    if (_userProfile != null) {
      _userProfile = _userProfile!.copyWith(
        name: name,
        email: email,
        department: department,
        level: level,
        profileImageUrl: profileImageUrl,
      );
      notifyListeners();
    }
  }

  void clearProfile() {
    _userProfile = null;
    notifyListeners();
  }
}
