import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/screens/section1/first_landing.dart';
import 'package:pivot/screens/section1/login/login.dart';
import 'package:pivot/screens/section1/no_internet_screen.dart';
import 'package:pivot/screens/section2/landing.dart';
import 'package:pivot/services/auth_service.dart';
import 'package:provider/provider.dart';

enum AuthStatus { checking, noInternet, authenticated, unauthenticated }

class AuthWrapper extends StatefulWidget {
  static const String id = 'auth_wrapper';
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  AuthStatus _status = AuthStatus.checking;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _performChecks();
  }

  Future<void> _performChecks() async {
    // Set to checking state and show loading spinner
    if (mounted) {
      setState(() {
        _status = AuthStatus.checking;
      });
    }

    // 1. Check internet connection
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      if (mounted) {
        setState(() {
          _status = AuthStatus.noInternet;
        });
      }
      return;
    }

    // 2. Check auth status
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _status = AuthStatus.unauthenticated;
        });
      }
      return;
    }

    // 3. Fetch user profile
    try {
      final UserProfile? profile = await _authService.getUserProfile(user.uid);
      if (profile != null && mounted) {
        Provider.of<UserProfileProvider>(
          context,
          listen: false,
        ).setUserProfile(profile);
        setState(() {
          _status = AuthStatus.authenticated;
        });
      } else {
        // Inconsistent state: auth user but no profile data
        await _authService.signOut();
        if (mounted) {
          setState(() {
            _status = AuthStatus.unauthenticated;
          });
        }
      }
    } catch (e) {
      // Error fetching profile, treat as unauthenticated
      await _authService.signOut();
      if (mounted) {
        setState(() {
          _status = AuthStatus.unauthenticated;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_status) {
      case AuthStatus.checking:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: Colors.black)),
        );
      case AuthStatus.noInternet:
        return NoInternetScreen(onRetry: _performChecks);
      case AuthStatus.authenticated:
        // Use a Consumer to ensure the Landing screen is only built after
        // the UserProfileProvider has been updated and has a valid profile.
        return Consumer<UserProfileProvider>(
          builder: (context, userProfileProvider, child) {
            if (userProfileProvider.userProfile == null) {
              // This state should be brief, show a loading indicator.
              return const Scaffold(
                body: Center(child: CircularProgressIndicator(color: Colors.black)),
              );
            }
            return const Landing();
          },
        );
      case AuthStatus.unauthenticated:
        return const FirstLanding();
    }
  }
}
