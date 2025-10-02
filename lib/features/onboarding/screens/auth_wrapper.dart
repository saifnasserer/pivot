import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pivot/features/user/providers/user_profile_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/features/onboarding/screens/introduction_wrapper.dart';
import 'package:pivot/features/home/screens/landing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthWrapper extends ConsumerStatefulWidget {
  // = 'auth_wrapper';
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  late final Stream<User?> _authStateChanges;
  bool _loadingProfile = false;
  bool _cacheReady = false;

  @override
  void initState() {
    super.initState();
    _authStateChanges = FirebaseAuth.instance.authStateChanges();
    _initCache();
    _checkActiveSession();
  }

  Future<void> _checkActiveSession() async {
    // Check if there's already an active session
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      // Validate the session token to ensure it's still valid
      try {
        await currentUser.reload();
        // Token is valid, load profile immediately
        await _loadProfileAndNavigate(currentUser);
      } catch (e) {
        // Token is invalid, sign out and show login
        await FirebaseAuth.instance.signOut();
        // TODO: Clear profile using Riverpod
        // ref.read(userProfileProvider.notifier).clearProfile();
      }
    }
  }

  Future<void> _initCache() async {
    // CacheService is already initialized in main.dart
    // Just mark as ready to avoid duplicate initialization
    if (mounted) {
      setState(() {
        _cacheReady = true;
      });
    }
  }

  Future<void> _loadProfileAndNavigate(User user) async {
    if (_loadingProfile) return; // Prevent multiple simultaneous loads

    setState(() => _loadingProfile = true);
    // Use Riverpod to load user profile
    await ref.read(userProfileProvider.notifier).loadLoggedInUserProfile();

    try {
      // Check if profile is already loaded for this user
      final userProfileState = ref.read(userProfileProvider);
      if (userProfileState.loggedInUserProfile?.id == user.uid) {
        setState(() => _loadingProfile = false);
        return;
      }

      // Profile loading is handled by the Riverpod provider
      if (!mounted) return;

      setState(() => _loadingProfile = false);

      // Check if profile was loaded successfully
      final currentProfileState = ref.read(userProfileProvider);
      if (currentProfileState.loggedInUserProfile == null) {
        // If profile fails to load, sign out and go to FirstLandingScreen
        await FirebaseAuth.instance.signOut();
        // TODO: Clear profile using Riverpod
        // ref.read(userProfileProvider.notifier).clearProfile();
      }
    } catch (e) {
      // Handle any errors during profile loading
      if (mounted) {
        setState(() => _loadingProfile = false);
        // Sign out on error and let user re-authenticate
        await FirebaseAuth.instance.signOut();
        // TODO: Clear profile using Riverpod
        // ref.read(userProfileProvider.notifier).clearProfile();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_cacheReady) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.black),
              SizedBox(height: 24),
              Text(
                ' ...لحظة',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black87,
                  fontFamily: 'NotoSansArabic',
                ),
              ),
            ],
          ),
        ),
      );
    }
    return StreamBuilder<User?>(
      stream: _authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data;
        final userProfileState = ref.watch(userProfileProvider);

        //debugprint(
        //   '[AuthWrapper] Build called - User: ${user?.uid}, Profile: ${userProfileState.loggedInUserProfile?.id}, Loading: $_loadingProfile',
        // );

        if (snapshot.connectionState == ConnectionState.waiting) {
          //debugprint('[AuthWrapper] Waiting for auth state...');
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.black),
                  SizedBox(
                    height: Responsive.space(context, size: Space.medium),
                  ),
                  Text(
                    ' ...لحظة',
                    style: TextStyle(
                      fontSize: Responsive.text(context, size: TextSize.medium),
                      color: Colors.black87,
                      fontFamily: 'NotoSansArabic',
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (user == null) {
          // Not authenticated - show introduction/onboarding
          return const IntroductionWrapper();
        } else {
          // User is authenticated - check profile status
          final profile = userProfileState.loggedInUserProfile;
          final isProfileLoaded = profile != null && profile.id == user.uid;

          if (isProfileLoaded) {
            // Profile is loaded and matches current user - navigate to landing
            return const Landing();
          } else {
            // Profile not loaded or doesn't match - load profile
            if (!_loadingProfile) {
              // Schedule profile loading after current frame
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && !_loadingProfile) {
                  _loadProfileAndNavigate(user);
                }
              });
            }

            // Show loading screen while profile is being loaded
            return Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.black),
                    SizedBox(
                      height: Responsive.space(context, size: Space.medium),
                    ),
                    Text(
                      'جاري تحميل البيانات...',
                      style: TextStyle(
                        fontSize: Responsive.text(
                          context,
                          size: TextSize.medium,
                        ),
                        color: Colors.black87,
                        fontFamily: 'NotoSansArabic',
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        }
      },
    );
  }
}
