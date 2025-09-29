import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/responsive.dart';
import 'package:pivot/screens/section1/introduction_wrapper.dart';
import 'package:pivot/screens/section2/landing.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/onboarding/providers/onboarding_provider.dart';
import 'package:pivot/services/cache_service.dart';

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
  }

  Future<void> _initCache() async {
    // Only initialize cache if not already initialized
    try {
      await CacheService.instance.init();
    } catch (e) {
      // Cache might already be initialized, ignore error
    }
    if (mounted) {
      setState(() {
        _cacheReady = true;
      });
    }
  }

  Future<void> _loadProfileAndNavigate(User user) async {
    setState(() => _loadingProfile = true);
    final provider = legacy_provider.Provider.of<UserProfileProvider>(
      context,
      listen: false,
    );

    // Check if profile is already loaded for this user
    if (provider.loggedInUserProfile?.id == user.uid) {
      setState(() => _loadingProfile = false);
      return;
    }

    final loaded = await provider.loadLoggedInUserProfile();
    setState(() => _loadingProfile = false);
    if (!mounted) return;
    if (!loaded) {
      // If profile fails to load, sign out and go to FirstLandingScreen
      await FirebaseAuth.instance.signOut();
      provider.clearProfile();
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
        final userProfileProvider = legacy_provider
            .Provider.of<UserProfileProvider>(context);

        //debugprint(
        //   '[AuthWrapper] Build called - User: ${user?.uid}, Profile: ${userProfileProvider.loggedInUserProfile?.id}, Loading: $_loadingProfile',
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
          //debugprint('[AuthWrapper] No user, showing IntroductionWrapper');
          // Not authenticated
          return const IntroductionWrapper();
        } else {
          //debugprint('[AuthWrapper] User authenticated: ${user.uid}');
          // Authenticated, check if profile is loaded
          if (userProfileProvider.loggedInUserProfile == null ||
              userProfileProvider.loggedInUserProfile?.id != user.uid) {
            //debugprint(
            //   '[AuthWrapper] Profile not loaded or mismatch, loading profile...',
            // );

            // Only show loading if we're not already loading
            if (!_loadingProfile) {
              // Schedule the profile load after the current frame
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && !_loadingProfile) {
                  _loadProfileAndNavigate(user);
                }
              });
            }

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
                      '... لحظة',
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
          } else {
            // Profile loaded, go to main app immediately
            //debugprint(
            //   '[AuthWrapper] Profile already loaded, navigating to Landing',
            // );
            return const Landing();
          }
        }
      },
    );
  }
}
