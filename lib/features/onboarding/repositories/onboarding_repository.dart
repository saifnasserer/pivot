import 'package:pivot/features/onboarding/services/onboarding_service.dart';

class OnboardingRepository {
  OnboardingRepository(this._service);

  final OnboardingService _service;

  Future<bool> isFirstRun() => _service.isFirstRun();
  Future<void> markFirstRunCompleted() => _service.markFirstRunCompleted();
  Future<bool> isIntroShown() => _service.isIntroShown();
  Future<void> markIntroShown() => _service.markIntroShown();
  Future<String?> getPendingDeepLink() => _service.getPendingDeepLink();
  Future<void> setPendingDeepLink(String? link) =>
      _service.setPendingDeepLink(link);
  Future<void> clearPendingDeepLink() => _service.clearPendingDeepLink();
}
