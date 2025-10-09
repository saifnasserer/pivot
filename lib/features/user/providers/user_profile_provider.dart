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
  /// The profile currently being viewed (changes dynamically when navigating between profiles)
  /// When viewing own profile: userProfile.id == loggedInUserProfile.id (but separate instances)
  /// When viewing another user: userProfile.id != loggedInUserProfile.id
  final UserProfile? userProfile;

  /// The authenticated user who is currently logged in (constant during the session)
  /// This should NEVER change when viewing other profiles, only when user logs in/out or updates their own data
  final UserProfile? loggedInUserProfile;

  final List<UserProfile> allUsers;
  final bool isLoading;
  final bool isAuthenticating;
  final bool isOffline; // Indicates if using cached data in offline mode
  final String? error;
  final Map<String, UserProfile> userProfilesCache;

  const UserProfileState({
    this.userProfile,
    this.loggedInUserProfile,
    this.allUsers = const [],
    this.isLoading = false,
    this.isAuthenticating = false,
    this.isOffline = false, // NEW
    this.error,
    this.userProfilesCache = const {},
  });

  UserProfileState copyWith({
    UserProfile? userProfile,
    UserProfile? loggedInUserProfile,
    List<UserProfile>? allUsers,
    bool? isLoading,
    bool? isAuthenticating,
    bool? isOffline, // NEW
    String? error,
    Map<String, UserProfile>? userProfilesCache,
  }) => UserProfileState(
    userProfile: userProfile ?? this.userProfile,
    loggedInUserProfile: loggedInUserProfile ?? this.loggedInUserProfile,
    allUsers: allUsers ?? this.allUsers,
    isLoading: isLoading ?? this.isLoading,
    isAuthenticating: isAuthenticating ?? this.isAuthenticating,
    isOffline: isOffline ?? this.isOffline, // NEW
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
    state = state.copyWith(isLoading: true, error: null, isOffline: false);
    try {
      final profile = await _repo.getLoggedInUserProfile();
      state = state.copyWith(
        isLoading: false,
        loggedInUserProfile: profile,
        isOffline: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        isOffline: false,
      );
    }
  }

  /// Load a user profile for viewing
  /// This method should be called when navigating to any profile (including own profile)
  /// It keeps loggedInUserProfile constant and only updates userProfile
  Future<void> loadUserProfile(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final profile = await _repo.getUserProfile(userId);
      // Always set userProfile as a separate instance, never share reference with loggedInUserProfile
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
      print('👤 [UserProfile] Updating enrolled subjects: $subjectIds');
      await _repo.updateEnrolledSubjects(subjectIds);
      print('👤 [UserProfile] Successfully updated in Firestore');

      // Reload logged-in user profile to get updated data
      if (mounted) {
        print('👤 [UserProfile] Reloading logged-in user profile...');
        await loadLoggedInUserProfile();
        print('👤 [UserProfile] Logged-in user profile reloaded');

        // If viewing own profile, also reload the viewed profile
        if (isViewingOwnProfile && state.loggedInUserProfile != null) {
          print('👤 [UserProfile] Reloading viewed profile (own profile)...');
          await loadUserProfile(state.loggedInUserProfile!.id);
          print('👤 [UserProfile] Viewed profile reloaded');
        }
      } else {
        print('⚠️ [UserProfile] Not mounted after update');
      }
    } catch (e) {
      print('❌ [UserProfile] Error updating enrolled subjects: $e');
      if (mounted) {
        state = state.copyWith(error: e.toString());
      }
    }
  }

  Future<void> updateTeachingSubjects(List<String> subjectIds) async {
    try {
      await _repo.updateTeachingSubjects(subjectIds);

      // Reload logged-in user profile to get updated data
      if (mounted) {
        await loadLoggedInUserProfile();

        // If viewing own profile, also reload the viewed profile
        if (isViewingOwnProfile && state.loggedInUserProfile != null) {
          await loadUserProfile(state.loggedInUserProfile!.id);
        }
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(error: e.toString());
      }
    }
  }

  Future<void> updateUserEnrolledSubjects(
    String userId,
    List<String> subjectIds,
  ) async {
    try {
      await _repo.updateUserEnrolledSubjects(userId, subjectIds);
      // Reload all users to get updated data
      if (mounted) {
        await fetchAllUsers();
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(error: e.toString());
      }
    }
  }

  Future<void> updateUserTeachingSubjects(
    String userId,
    List<String> subjectIds,
  ) async {
    try {
      await _repo.updateUserTeachingSubjects(userId, subjectIds);
      // Reload all users to get updated data
      if (mounted) {
        await fetchAllUsers();
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(error: e.toString());
      }
    }
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await _repo.updateUserRole(userId, newRole);
      // Reload all users to get updated data
      if (mounted) {
        await fetchAllUsers();
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(error: e.toString());
      }
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

        // Also update userProfile if viewing own profile
        if (state.userProfile?.id == state.loggedInUserProfile!.id) {
          state = state.copyWith(
            userProfile: updatedProfile.copyWith(profileImageUrl: imageUrl),
          );
        }
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Set logged in user profile (supports offline mode)
  Future<void> setLoggedInUserProfile(
    UserProfile profile, {
    bool isOffline = false,
  }) async {
    state = state.copyWith(
      loggedInUserProfile: profile,
      isOffline: isOffline,
      isLoading: false,
      error: null,
    );

    if (isOffline) {
      print('🔌 Profile set in offline mode: ${profile.name}');
    }
  }

  Future<void> setUserProfile(UserProfile profile) async {
    state = state.copyWith(userProfile: profile);
  }

  /// Update social media links for a user
  Future<void> updateSocialMediaLinks(
    String userId,
    List<SocialMediaLink> socialMediaLinks,
  ) async {
    try {
      await _repo.updateSocialMediaLinks(userId, socialMediaLinks);

      // Update local state if this is the logged-in user or currently viewed profile
      if (state.loggedInUserProfile?.id == userId) {
        final updatedProfile = state.loggedInUserProfile!.copyWith(
          socialMediaLinks: socialMediaLinks,
        );
        state = state.copyWith(loggedInUserProfile: updatedProfile);
      }
      if (state.userProfile?.id == userId) {
        final updatedProfile = state.userProfile!.copyWith(
          socialMediaLinks: socialMediaLinks,
        );
        state = state.copyWith(userProfile: updatedProfile);
      }

      // Update cache if present
      if (state.userProfilesCache.containsKey(userId)) {
        final updatedCache = Map<String, UserProfile>.from(
          state.userProfilesCache,
        );
        updatedCache[userId] = updatedCache[userId]!.copyWith(
          socialMediaLinks: socialMediaLinks,
        );
        state = state.copyWith(userProfilesCache: updatedCache);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Update about me text for a user
  Future<void> updateAboutMe(String userId, String aboutMe) async {
    try {
      await _repo.updateAboutMe(userId, aboutMe);

      // Update local state if this is the logged-in user or currently viewed profile
      if (state.loggedInUserProfile?.id == userId) {
        final updatedProfile = state.loggedInUserProfile!.copyWith(
          aboutMe: aboutMe,
        );
        state = state.copyWith(loggedInUserProfile: updatedProfile);
      }
      if (state.userProfile?.id == userId) {
        final updatedProfile = state.userProfile!.copyWith(aboutMe: aboutMe);
        state = state.copyWith(userProfile: updatedProfile);
      }

      // Update cache if present
      if (state.userProfilesCache.containsKey(userId)) {
        final updatedCache = Map<String, UserProfile>.from(
          state.userProfilesCache,
        );
        updatedCache[userId] = updatedCache[userId]!.copyWith(aboutMe: aboutMe);
        state = state.copyWith(userProfilesCache: updatedCache);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearUserProfile() {
    state = state.copyWith(userProfile: null);
  }

  void clearLoggedInUserProfile() {
    state = state.copyWith(
      loggedInUserProfile: null,
      userProfile: null,
      error: null,
    );
  }

  void clearAllProfiles() {
    state = const UserProfileState();
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

  Future<void> updateAssistantPreferences(
    Map<String, String> preferences,
  ) async {
    try {
      await _repo.updateAssistantPreferences(preferences);

      // Reload logged-in user profile to get updated preferences
      await loadLoggedInUserProfile();

      // If viewing own profile, also reload the viewed profile
      if (isViewingOwnProfile && state.loggedInUserProfile != null) {
        await loadUserProfile(state.loggedInUserProfile!.id);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Get a user profile by ID (used for viewing other users' profiles)
  Future<UserProfile?> getUserProfileById(String userId) async {
    try {
      final profile = await _repo.getUserProfile(userId);
      // Cache the profile for future use if not null
      if (profile != null) {
        final updatedCache = Map<String, UserProfile>.from(
          state.userProfilesCache,
        );
        updatedCache[userId] = profile;
        state = state.copyWith(userProfilesCache: updatedCache);
      }
      return profile;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Load logged-in user's profile for viewing (e.g., when opening own profile)
  /// This creates a separate copy to avoid shared references between loggedInUserProfile and userProfile
  Future<void> viewOwnProfile() async {
    if (state.loggedInUserProfile != null) {
      // Load the logged-in user's profile fresh from the repository
      // This ensures userProfile is a separate instance from loggedInUserProfile
      await loadUserProfile(state.loggedInUserProfile!.id);
    }
  }

  /// Helper method to check if currently viewing own profile
  bool get isViewingOwnProfile {
    return state.loggedInUserProfile != null &&
        state.userProfile != null &&
        state.loggedInUserProfile!.id == state.userProfile!.id;
  }
}
