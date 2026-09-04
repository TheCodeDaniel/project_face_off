/// Tunable constants for Freeze's own round timing (multi-game plan Section
/// 2.3), named rather than buried as magic numbers.
abstract final class FreezeRules {
  /// Random build-up delay range before the freeze cue fires — same role as
  /// Face Off's cue-arm delay.
  static const Duration buildUpMin = Duration(milliseconds: 1500);
  static const Duration buildUpMax = Duration(milliseconds: 4500);

  /// How long the freeze window stays open once the cue fires.
  static const Duration freezeWindow = Duration(seconds: 3);

  /// Motion-delta magnitude past which a tracked-landmark sample counts as
  /// "moved" — a placeholder unit until the real gesture engine defines
  /// what a landmark-delta magnitude actually looks like; the dev harness
  /// (`DevFreezeControls`) sends a fixed value comfortably above this.
  static const double motionThreshold = 0.08;

  /// Window during which a second move counts as "simultaneous" -> draw —
  /// same value and rationale as Face Off's `simultaneousCrackWindow`.
  static const Duration simultaneousMoveWindow = Duration(milliseconds: 150);
}
