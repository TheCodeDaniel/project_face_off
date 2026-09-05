/// Tunable constants for Bow & Draw's own round timing (multi-game plan
/// Section 2.2), named rather than buried as magic numbers so they can be
/// retuned during playtesting without touching `BowDrawRoundEngine` logic.
abstract final class DrawRules {
  /// Random target draw-power range each round's target is generated within
  /// — represents target distance (further = higher required power).
  static const double targetPowerMin = 0.3;
  static const double targetPowerMax = 0.9;

  /// How close a shot's power must land to the target's to count as a hit.
  static const double hitTolerance = 0.15;

  /// Overall round window a shot must land within, guarding against a
  /// stuck/disconnected client — same role as Face Off's `roundTimeout`.
  static const Duration shotWindow = Duration(seconds: 6);
}
