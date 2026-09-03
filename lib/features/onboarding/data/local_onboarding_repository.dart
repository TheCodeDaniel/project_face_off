import 'package:shared_preferences/shared_preferences.dart';

import '../domain/onboarding_repository.dart';

class LocalOnboardingRepository implements OnboardingRepository {
  static const _seenKey = 'onboarding_seen';
  static const _tourSeenKey = 'onboarding_tour_seen';

  @override
  Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_seenKey) ?? false;
  }

  @override
  Future<void> markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenKey, true);
  }

  @override
  Future<bool> hasSeenTour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tourSeenKey) ?? false;
  }

  @override
  Future<void> markTourSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tourSeenKey, true);
  }
}
