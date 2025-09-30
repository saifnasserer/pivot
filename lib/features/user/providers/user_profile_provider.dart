import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/user/repositories/user_profile_repository.dart';
import 'package:pivot/features/user/services/user_profile_service.dart';
import 'package:pivot/models/user_profile.dart';

final userProfileServiceProvider = Provider<UserProfileService>(
  (ref) => UserProfileService(),
);

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  final service = ref.watch(userProfileServiceProvider);
  return UserProfileRepository(service);
});

class UserProfileState {
  final UserProfile? userProfile; // The profile being viewed
  final UserProfile? loggedInUserProfile; // Currently authenticated user
  final List<UserProfile> allUsers;
  final bool isLoading;
  final bool isAuthenticating;
  final String? error;
  final Map<String, UserProfile> userProfilesCache;

  const UserProfileState({
    this.userProfile,
    this.loggedInUserProfile,
    this.allUsers = const [],
    this.isLoading = false,
    this.isAuthenticating = false,
    this.error,
    this.userProfilesCache = const {},
  });

  UserProfileState copyWith({
    UserProfile? userProfile,
    UserProfile? loggedInUserProfile,
    List<UserProfile>? allUsers,
    bool? isLoading,
    bool? isAuthenticating,
    String? error,
    Map<String, UserProfile>? userProfilesCache,
  }) => UserProfileState(
    userProfile: userProfile ?? this.userProfile,
    loggedInUserProfile: loggedInUserProfile ?? this.loggedInUserProfile,
    allUsers: allUsers ?? this.allUsers,
    isLoading: isLoading ?? this.isLoading,
    isAuthenticating: isAuthenticating ?? this.isAuthenticating,
    error: error ?? this.error,
    userProfilesCache: userProfilesCache ?? this.userProfilesCache,
  );
}

final userProfileProvider =
    StateNotifierProvider.autoDispose<UserProfileNotifier, UserProfileState>(
      (ref) => UserProfileNotifier(ref),
    );

class UserProfileNotifier extends StateNotifier<UserProfileState> {
  UserProfileNotifier(this._ref) : super(const UserProfileState());

  final Ref _ref;
  late final UserProfileRepository _repo = _ref.read(
    userProfileRepositoryProvider,
  );

  Future<void> loadLoggedInUserProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final profile = await _repo.getLoggedInUserProfile();
      state = state.copyWith(isLoading: false, loggedInUserProfile: profile);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadUserProfile(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final profile = await _repo.getUserProfile(userId);
      state = state.copyWith(isLoading: false, userProfile: profile);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchAllUsers() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final users = await _repo.getAllUsers();
      state = state.copyWith(isLoading: false, allUsers: users);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      await _repo.updateUserProfile(profile);
      // Update local state
      if (state.loggedInUserProfile?.id == profile.id) {
        state = state.copyWith(loggedInUserProfile: profile);
      }
      if (state.userProfile?.id == profile.id) {
        state = state.copyWith(userProfile: profile);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateEnrolledSubjects(List<String> subjectIds) async {
    try {
      await _repo.updateEnrolledSubjects(subjectIds);
      // Reload profile to get updated data
      await loadLoggedInUserProfile();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateTeachingSubjects(List<String> subjectIds) async {
    try {
      await _repo.updateTeachingSubjects(subjectIds);
      // Reload profile to get updated data
      await loadLoggedInUserProfile();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateUserEnrolledSubjects(
    String userId,
    List<String> subjectIds,
  ) async {
    try {
      await _repo.updateUserEnrolledSubjects(userId, subjectIds);
      // Reload all users to get updated data
      await fetchAllUsers();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateUserTeachingSubjects(
    String userId,
    List<String> subjectIds,
  ) async {
    try {
      await _repo.updateUserTeachingSubjects(userId, subjectIds);
      // Reload all users to get updated data
      await fetchAllUsers();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await _repo.updateUserRole(userId, newRole);
      // Reload all users to get updated data
      await fetchAllUsers();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _repo.deleteUser(userId);
      // Remove from local state
      final updatedUsers =
          state.allUsers.where((user) => user.id != userId).toList();
      state = state.copyWith(allUsers: updatedUsers);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> uploadProfileImage(String imagePath) async {
    try {
      final imageUrl = await _repo.uploadProfileImage(imagePath);
      // Update logged in user profile with new image URL
      if (state.loggedInUserProfile != null) {
        final updatedProfile = state.loggedInUserProfile!.copyWith(
          profileImageUrl: imageUrl,
        );
        state = state.copyWith(loggedInUserProfile: updatedProfile);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> setLoggedInUserProfile(UserProfile profile) async {
    state = state.copyWith(loggedInUserProfile: profile);
  }

  Future<void> setUserProfile(UserProfile profile) async {
    state = state.copyWith(userProfile: profile);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearUserProfile() {
    state = state.copyWith(userProfile: null);
  }

  UserProfile? getUserById(String userId) {
    return state.allUsers.firstWhere(
      (user) => user.id == userId,
      orElse:
          () =>
              state.userProfilesCache[userId] ??
              state.allUsers.firstWhere(
                (user) => user.id == userId,
                orElse:
                    () => UserProfile(
                      id: userId,
                      name: 'Unknown User',
                      email: '',
                      role: 'Student',
                      department: '',
                      level: '1',
                      section: 'A',
                      profileImageUrl: '',
                      enrolledSubjects: [],
                      teachingSubjects: [],
                    ),
              ),
    );
  }
}
