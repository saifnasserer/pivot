import 'package:flutter/material.dart';
import 'package:pivot/responsive.dart';


class AnimatedAddRoute extends PageRouteBuilder {
  final Widget child;
  final Offset startPosition;

  AnimatedAddRoute({required this.child, required this.startPosition})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => child,
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
            begin: 0.8,
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

// Custom animated button that expands to full screen
class AnimatedAddButton extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final double iconSizeMultiplier;
  final Offset? startPosition;

  const AnimatedAddButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.iconSizeMultiplier = 1.0,
    this.startPosition,
  });

  @override
  State<AnimatedAddButton> createState() => _AnimatedAddButtonState();
}

class _AnimatedAddButtonState extends State<AnimatedAddButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.125, // 45 degrees
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: Container(
                width: Responsive.space(context, size: Space.xlarge) * 4,
                height: Responsive.space(context, size: Space.xlarge) * 4,
                decoration: BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  widget.icon,
                  color: Colors.white,
                  size:
                      Responsive.space(context, size: Space.large) *
                      widget.iconSizeMultiplier,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Hero animation for smooth transition
class HeroAddButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final double iconSizeMultiplier;

  const HeroAddButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.iconSizeMultiplier = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'add_button',
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: Responsive.space(context, size: Space.xlarge) * 3,
          height: Responsive.space(context, size: Space.xlarge) * 3,
          decoration: BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(
              icon,
              color: Colors.white,
              size:
                  Responsive.space(context, size: Space.large) *
                  iconSizeMultiplier *
                  1.5,
            ),
          ),
        ),
      ),
    );
  }
}
