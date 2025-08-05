import 'package:flutter/material.dart';

/// A wrapper widget that properly handles system UI insets and prevents overflow issues
/// when the notification bar is pulled down and dismissed.
class ResponsiveScreenWrapper extends StatefulWidget {
  final Widget child;
  final bool enableSafeArea;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;

  const ResponsiveScreenWrapper({
    super.key,
    required this.child,
    this.enableSafeArea = true,
    this.padding,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  State<ResponsiveScreenWrapper> createState() =>
      _ResponsiveScreenWrapperState();
}

class _ResponsiveScreenWrapperState extends State<ResponsiveScreenWrapper>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    // Force rebuild when system UI metrics change (notification bar, keyboard, etc.)
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        // Ensure we're using the most up-to-date metrics
        viewInsets: MediaQuery.of(context).viewInsets,
        padding: MediaQuery.of(context).padding,
      ),
      child: Scaffold(
        backgroundColor: widget.backgroundColor ?? Colors.grey[50],
        resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
        body:
            widget.enableSafeArea
                ? SafeArea(
                  child: Padding(
                    padding: widget.padding ?? EdgeInsets.zero,
                    child: widget.child,
                  ),
                )
                : Padding(
                  padding: widget.padding ?? EdgeInsets.zero,
                  child: widget.child,
                ),
      ),
    );
  }
}

/// A dialog wrapper that properly handles system UI insets for dialogs and overlays
class ResponsiveDialogWrapper extends StatelessWidget {
  final Widget child;
  final double maxHeightFactor;
  final double maxWidthFactor;
  final EdgeInsets? padding;

  const ResponsiveDialogWrapper({
    super.key,
    required this.child,
    this.maxHeightFactor = 0.8,
    this.maxWidthFactor = 0.9,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaQuery = MediaQuery.of(context);
        final availableHeight =
            mediaQuery.size.height -
            mediaQuery.padding.top -
            mediaQuery.padding.bottom;

        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: availableHeight * maxHeightFactor,
            maxWidth: mediaQuery.size.width * maxWidthFactor,
          ),
          child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
        );
      },
    );
  }
}

/// A scrollable wrapper that adapts to system UI changes
class ResponsiveScrollWrapper extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final ScrollPhysics? physics;
  final bool primary;

  const ResponsiveScrollWrapper({
    super.key,
    required this.child,
    this.padding,
    this.physics,
    this.primary = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: physics,
          primary: primary,
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(child: child),
          ),
        );
      },
    );
  }
}
