import 'package:flutter/material.dart';
import 'package:pivot/features/administration/screens/doctor/edit_about_screen.dart';
import 'package:pivot/models/user_profile.dart';

class AnimatedEditAboutRoute extends PageRouteBuilder {
  final UserProfile userProfile;
  final String initialAboutText;

  AnimatedEditAboutRoute({
    required this.userProfile,
    required this.initialAboutText,
  }) : super(
         pageBuilder:
             (context, animation, secondaryAnimation) => EditAboutScreen(
               userProfile: userProfile,
               initialAboutText: initialAboutText,
             ),
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           const begin = Offset(0.0, 1.0);
           const end = Offset.zero;
           const curve = Curves.easeInOutCubic;

           var tween = Tween(
             begin: begin,
             end: end,
           ).chain(CurveTween(curve: curve));

           var offsetAnimation = animation.drive(tween);

           // Scale animation
           var scaleTween = Tween<double>(
             begin: 0.9,
             end: 1.0,
           ).chain(CurveTween(curve: curve));

           var scaleAnimation = animation.drive(scaleTween);

           // Fade animation
           var fadeTween = Tween<double>(
             begin: 0.0,
             end: 1.0,
           ).chain(CurveTween(curve: curve));

           var fadeAnimation = animation.drive(fadeTween);

           return SlideTransition(
             position: offsetAnimation,
             child: ScaleTransition(
               scale: scaleAnimation,
               child: FadeTransition(opacity: fadeAnimation, child: child),
             ),
           );
         },
         transitionDuration: const Duration(milliseconds: 400),
         reverseTransitionDuration: const Duration(milliseconds: 300),
       );
}
