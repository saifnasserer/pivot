import 'package:flutter/material.dart';
import 'package:pivot/models/lecture_model.dart';

class MaterialLinksRoute extends PageRouteBuilder {
  final Widget child;
  final Lecture lecture;

  MaterialLinksRoute({required this.child, required this.lecture})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => child,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Smooth slide-up animation with scale and fade
          const begin = Offset(0.0, 0.3);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          // Scale animation
          var scaleTween = Tween<double>(begin: 0.95, end: 1.0);
          var scaleAnimation = animation.drive(scaleTween);

          // Fade animation
          var fadeTween = Tween<double>(begin: 0.0, end: 1.0);
          var fadeAnimation = animation.drive(fadeTween);

          return SlideTransition(
            position: offsetAnimation,
            child: ScaleTransition(
              scale: scaleAnimation,
              child: FadeTransition(opacity: fadeAnimation, child: child),
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        barrierColor: Colors.black54,
        barrierDismissible: false,
      );
}
