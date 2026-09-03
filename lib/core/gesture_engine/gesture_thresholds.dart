/// Configurable thresholds for turning raw blendshape values into semantic
/// gesture events. These need real on-device tuning (Blueprint/PRD Day 1-2
/// validation) — kept as named constants here, never buried as magic numbers
/// in detection logic, so they can be retuned without touching the state
/// machine (master prompt Section 8.4).
abstract final class GestureThresholds {
  /// Mouth-curvature value above which a smile/laugh counts as "cracked".
  /// Must sit meaningfully above normal resting facial variation.
  static const double crackCurvature = 0.55;

  /// Jaw-open value above which counts as a "fire" gesture.
  static const double fireJawOpen = 0.45;

  /// Brow-inner-up value above which counts as a "dodge" gesture.
  static const double dodgeBrowRaise = 0.5;

  /// Consecutive frames a signal must hold above threshold before it's
  /// treated as a real gesture rather than a single noisy sample.
  static const int debounceFrameCount = 2;
}
