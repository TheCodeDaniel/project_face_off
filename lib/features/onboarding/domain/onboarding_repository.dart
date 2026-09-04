/// Local-only onboarding state, persisted (not just Firestore) per master
/// prompt Section 6 so neither the welcome sequence nor the post-sign-in
/// product tour replays after the first session, even offline.
abstract class OnboardingRepository {
  Future<bool> hasSeenOnboarding();

  Future<void> markOnboardingSeen();

  /// The post-sign-in `showcaseview` tour (Section 6) — tracked separately
  /// from [hasSeenOnboarding] because it can only run once a user is signed
  /// in and the shell is on screen, one step after the welcome sequence.
  Future<bool> hasSeenTour();

  Future<void> markTourSeen();
}
