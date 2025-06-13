import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pivot/models/user_profile.dart';
import 'package:pivot/providers/user_profile_provider.dart';
import 'package:pivot/screens/section1/login/login.dart';
import 'package:pivot/screens/section1/signup/signup_page1.dart';
import 'package:pivot/screens/section2/landing.dart';
import 'package:pivot/services/auth_service.dart';
import 'package:provider/provider.dart';
import '../../responsive.dart';

class FirstLanding extends StatefulWidget {
  const FirstLanding({super.key});
  static String id = 'landing1';

  @override
  State<FirstLanding> createState() => _FirstLandingState();
}

class _FirstLandingState extends State<FirstLanding> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        UserProfile? userProfile = await _authService.getUserProfile(user.uid);
        if (mounted && userProfile != null) {
          Provider.of<UserProfileProvider>(context, listen: false)
              .setUserProfile(userProfile);
          Navigator.pushReplacementNamed(context, Landing.id);
          return; // Exit after navigation
        }
      } catch (e) {
        // Handle error fetching profile, sign out to be safe
        await _authService.signOut();
      }
    }
    // If user is null or profile fetch failed, show the login/signup page
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xff161616),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: Container(
          height: double.infinity,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xff161616),
            image: DecorationImage(
              image: AssetImage('assets/images/Group 113.png'),
              opacity: 0.15,
              scale: 1.2,
            ),
          ),
          child: Padding(
            padding: Responsive.paddingHorizontal(context, size: Space.medium),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          textAlign: TextAlign.right,
                          '! ... واخيراً',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: Responsive.text(
                                  context,
                                  size: TextSize.heading,
                                ) *
                                1.5,
                          ),
                        ),
                        Text(
                          textAlign: TextAlign.right,
                          'حياة جامعية منظمة',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: Responsive.text(
                                  context,
                                  size: TextSize.heading,
                                ) *
                                2.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(
                      width: Responsive.space(context, size: Space.small),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, Signup_1.id);
                      },
                      child: Row(
                        children: [
                          Icon(
                            Icons.arrow_back,
                            color: Colors.black,
                            size: Responsive.text(
                              context,
                              size: TextSize.medium,
                            ),
                          ),
                          Text(
                            ' حساب جديد',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: Responsive.text(
                                context,
                                size: TextSize.medium,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: Responsive.space(context, size: Space.medium),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, Login.id);
                      },
                      child: Row(
                        children: [
                          Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: Responsive.text(
                              context,
                              size: TextSize.medium,
                            ),
                          ),
                          Text(
                            ' تسجيل الدخول',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: Responsive.text(
                                context,
                                size: TextSize.medium,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Responsive.space(context, size: Space.xlarge)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
