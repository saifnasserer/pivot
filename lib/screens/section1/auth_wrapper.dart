import 'dart:async';

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/screens/section1/first_landing.dart';
import 'package:pivot/screens/section1/no_internet_screen.dart';
import 'package:pivot/screens/section2/landing.dart';
import 'package:pivot/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pivot/screens/section1/maintenance_screen.dart';
import 'package:provider/provider.dart';

enum AuthStatus {
  checking,
  noInternet,
  authenticated,
  unauthenticated,
  maintenanceMode,
}

class AuthWrapper extends StatefulWidget {
  static const String id = 'auth_wrapper';
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  AuthStatus _status = AuthStatus.checking;
  final AuthService _authService = AuthService();
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = _authService.authStateChanges.listen(_handleAuthState);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<AuthStatus> _checkMaintenanceAndNavigate(
    UserProfileProvider provider,
  ) async {
    try {
      debugPrint('[AuthWrapper] Checking maintenance status from server...');
      final maintenanceDoc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('app')
          .get(const GetOptions(source: Source.server));

      final isMaintenanceMode =
          maintenanceDoc.exists &&
          (maintenanceDoc.data()?['isMaintenanceMode'] ?? false);
      debugPrint(
        '[AuthWrapper] Maintenance status from server: $isMaintenanceMode',
      );

      final userRole = provider.loggedInUserProfile?.role;
      debugPrint('[AuthWrapper] User role from provider: $userRole');

      if (isMaintenanceMode && userRole != 'Super Admin') {
        debugPrint(
          '[AuthWrapper] Condition MET: Maintenance is ON and user is NOT a Super Admin. Redirecting.',
        );
        return AuthStatus.maintenanceMode;
      } else {
        debugPrint(
          '[AuthWrapper] Condition NOT MET: Maintenance is OFF or user IS a Super Admin. Proceeding.',
        );
        return AuthStatus.authenticated;
      }
    } catch (e) {
      debugPrint(
        '[AuthWrapper] Error checking maintenance mode: $e. Defaulting to normal authentication flow.',
      );
      return AuthStatus.authenticated;
    }
  }

  Future<void> _handleAuthState(User? user) async {
    debugPrint('[AuthWrapper] Auth state changed. User: ${user?.uid}');
    // 1. Check internet connection
    final connectivityResult = await Connectivity().checkConnectivity();
    if (!mounted) return;
    if (connectivityResult.contains(ConnectivityResult.none)) {
      debugPrint('[AuthWrapper] No internet. Setting state to noInternet.');
      setState(() => _status = AuthStatus.noInternet);
      return;
    }

    // 2. Check auth status from stream
    if (user == null) {
      debugPrint(
        '[AuthWrapper] User is null. Setting state to unauthenticated.',
      );
      Provider.of<UserProfileProvider>(context, listen: false).clearProfile();
      setState(() => _status = AuthStatus.unauthenticated);
      return;
    }

    // 3. Check if profile is already loaded (from main.dart)
    final provider = Provider.of<UserProfileProvider>(context, listen: false);
    if (provider.loggedInUserProfile != null &&
        provider.loggedInUserProfile!.id == user.uid) {
      debugPrint(
        '[AuthWrapper] Profile already loaded. Checking maintenance mode...',
      );
      final newStatus = await _checkMaintenanceAndNavigate(provider);
      if (mounted) {
        setState(() => _status = newStatus);
      }
      return;
    }

    // 4. If not loaded, fetch it (for fresh logins)
    try {
      debugPrint('[AuthWrapper] Profile not loaded. Loading profile...');
      final bool profileLoaded = await provider.loadLoggedInUserProfile();

      if (!mounted) return;

      if (profileLoaded) {
        debugPrint(
          '[AuthWrapper] Profile loaded successfully. Checking maintenance mode...',
        );
        final newStatus = await _checkMaintenanceAndNavigate(provider);
        if (mounted) {
          setState(() => _status = newStatus);
        }
      } else {
        debugPrint('[AuthWrapper] Profile loading failed. Signing out.');
        await _authService.signOut(); // This will re-trigger the stream
      }
    } catch (e) {
      debugPrint(
        '[AuthWrapper] Error during profile loading: $e. Signing out.',
      );
      await _authService.signOut(); // This will re-trigger the stream
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
        return NoInternetScreen(
          onRetry: () => _handleAuthState(FirebaseAuth.instance.currentUser),
        );
      case AuthStatus.authenticated:
        // Use a Consumer to ensure the Landing screen is only built after
        // the UserProfileProvider has been updated and has a valid profile.
        return Consumer<UserProfileProvider>(
          builder: (context, userProfileProvider, child) {
            if (userProfileProvider.loggedInUserProfile == null) {
              // This state should be brief, show a loading indicator.
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: Colors.black),
                ),
              );
            }
            return const Landing();
          },
        );
      case AuthStatus.unauthenticated:
        return const FirstLandingScreen();
      case AuthStatus.maintenanceMode:
        return const MaintenanceScreen();
    }
  }
}
