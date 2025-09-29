import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/features/onboarding/screens/introduction_screen.dart';
import 'package:pivot/features/onboarding/screens/first_landing.dart';
import 'package:pivot/features/onboarding/providers/onboarding_provider.dart';

class IntroductionWrapper extends ConsumerStatefulWidget {
  const IntroductionWrapper({super.key});
  // = 'introduction_wrapper';

  @override
  ConsumerState<IntroductionWrapper> createState() =>
      _IntroductionWrapperState();
}

class _IntroductionWrapperState extends ConsumerState<IntroductionWrapper> {
  bool _isLogoutScenario = false;

  @override
  void initState() {
    super.initState();
    // Check if this is a logout scenario by checking if user was previously authenticated
    _checkIfLogoutScenario();
    // Initialize onboarding state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(onboardingProvider.notifier).initialize();
    });
  }

  void _checkIfLogoutScenario() {
    // If we're in IntroductionWrapper after logout, we should skip introduction
    // This is determined by checking if the user has seen the intro before
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final onboardingNotifier = ref.read(onboardingProvider.notifier);
        final isIntroShown = await onboardingNotifier.checkIfIntroShown();
        if (isIntroShown) {
          setState(() {
            _isLogoutScenario = true;
          });
        }
      } catch (e) {
        // If we can't determine, assume it's a logout scenario
        setState(() {
          _isLogoutScenario = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingProvider);

    if (onboardingState.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xff161616),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    // If this is a logout scenario (user has seen intro before), skip introduction
    if (_isLogoutScenario || onboardingState.isIntroShown) {
      return const FirstLandingScreen();
    }

    // Show introduction for first-time users
    return const IntroductionScreen();
  }
}
