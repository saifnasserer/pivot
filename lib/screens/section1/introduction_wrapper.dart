import 'package:flutter/material.dart';
import 'package:pivot/screens/section1/introduction_screen.dart';
import 'package:pivot/screens/section1/first_landing.dart';
import 'package:pivot/services/introduction_service.dart';

class IntroductionWrapper extends StatefulWidget {
  const IntroductionWrapper({super.key});
  // = 'introduction_wrapper';

  @override
  State<IntroductionWrapper> createState() => _IntroductionWrapperState();
}

class _IntroductionWrapperState extends State<IntroductionWrapper> {
  bool _isLoading = true;
  bool _hasSeenIntroduction = false;

  @override
  void initState() {
    super.initState();
    _checkIntroductionStatus();
  }

  Future<void> _checkIntroductionStatus() async {
    try {
      final hasSeen = await IntroductionService.hasSeenIntroduction();
      if (mounted) {
        setState(() {
          _hasSeenIntroduction = hasSeen;
          _isLoading = false;
        });
      }
    } catch (e) {
      // If there's an error, assume they haven't seen it
      if (mounted) {
        setState(() {
          _hasSeenIntroduction = false;
          _isLoading = false;
        });
      }
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

    // Show introduction if user hasn't seen it, otherwise show first landing
    return _hasSeenIntroduction
        ? const FirstLandingScreen()
        : const IntroductionScreen();
  }
}
