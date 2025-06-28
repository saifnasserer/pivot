import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/screens/section1/first_landing.dart';
import 'package:pivot/screens/section2/landing.dart';
import 'package:provider/provider.dart';
import 'package:pivot/responsive.dart';

class AuthWrapper extends StatefulWidget {
  static const String id = 'auth_wrapper';
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late final Stream<User?> _authStateChanges;
  bool _loadingProfile = false;

  @override
  void initState() {
    super.initState();
    _authStateChanges = FirebaseAuth.instance.authStateChanges();
  }

  Future<void> _loadProfileAndNavigate(User user) async {
    setState(() => _loadingProfile = true);
    final provider = Provider.of<UserProfileProvider>(context, listen: false);
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
    return StreamBuilder<User?>(
      stream: _authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data;
        final userProfileProvider = Provider.of<UserProfileProvider>(context);

        if (snapshot.connectionState == ConnectionState.waiting ||
            _loadingProfile) {
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
                    'جاري تحميل التطبيق...',
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
          // Not authenticated
          return const FirstLandingScreen();
        } else {
          // Authenticated, check if profile is loaded
          if (userProfileProvider.loggedInUserProfile == null ||
              userProfileProvider.loggedInUserProfile?.id != user.uid) {
            // Schedule the profile load after the current frame
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_loadingProfile) {
                _loadProfileAndNavigate(user);
              }
            });
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
                      'جاري تحميل الملف الشخصي...',
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
            // Profile loaded, go to main app
            return const Landing();
          }
        }
      },
    );
  }
}
