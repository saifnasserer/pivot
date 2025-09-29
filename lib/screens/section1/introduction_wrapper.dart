import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pivot/screens/section1/introduction_screen.dart';
import 'package:pivot/screens/section1/first_landing.dart';
import 'package:pivot/features/onboarding/providers/onboarding_provider.dart';

class IntroductionWrapper extends ConsumerStatefulWidget {
  const IntroductionWrapper({super.key});
  // = 'introduction_wrapper';

  @override
  ConsumerState<IntroductionWrapper> createState() =>
      _IntroductionWrapperState();
}

class _IntroductionWrapperState extends ConsumerState<IntroductionWrapper> {
  @override
  void initState() {
    super.initState();
    // Initialize onboarding state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(onboardingProvider.notifier).initialize();
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

    // Show introduction if user hasn't seen it, otherwise show first landing
    return onboardingState.isIntroShown
        ? const FirstLandingScreen()
        : const IntroductionScreen();
  }
}
