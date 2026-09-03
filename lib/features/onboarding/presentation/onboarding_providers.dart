import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_onboarding_repository.dart';
import '../domain/onboarding_repository.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) => LocalOnboardingRepository());

final hasSeenOnboardingProvider = FutureProvider<bool>((ref) {
  return ref.watch(onboardingRepositoryProvider).hasSeenOnboarding();
});

final hasSeenTourProvider = FutureProvider<bool>((ref) {
  return ref.watch(onboardingRepositoryProvider).hasSeenTour();
});
