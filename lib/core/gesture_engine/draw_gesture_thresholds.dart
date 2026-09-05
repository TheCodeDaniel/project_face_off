/// Configurable thresholds for turning raw hand-landmark frames into
/// semantic draw-gesture events (game/UI/backend guideline Section 2). Same
/// reasoning as [GestureThresholds]: named constants here, never magic
/// numbers in detection logic, need real on-device tuning once a real Hand
/// Landmarker feed exists.
abstract final class DrawGestureThresholds {
  /// Consecutive low-movement frames required before the hand's current
  /// position is locked in as the "at rest" anchor point that draw distance
  /// is measured from.
  static const int anchorRestFrameCount = 5;

  /// Frame-to-frame pinch-point movement (normalized units) below which the
  /// hand counts as "at rest" for anchor establishment.
  static const double anchorRestMovementTolerance = 0.02;

  /// Distance from the anchor (normalized units) that counts as a full
  /// (power = 1.0) draw. A rough stand-in for calibrating against a real
  /// arm's reach in camera space — needs on-device validation.
  static const double calibratedMaxDrawDistance = 0.35;

  /// Frame-to-frame drop in draw distance that counts as "rapid" — one half
  /// of release detection. Distance dropping this fast on its own could
  /// still just be the hand relaxing, which is why this is combined with
  /// [releaseOpennessIncrease] rather than used alone.
  static const double releaseDistanceDropRate = 0.08;

  /// Frame-to-frame increase in [HandLandmarkFrame.handOpenness] that counts
  /// as the hand snapping open — the other half of release detection.
  static const double releaseOpennessIncrease = 0.25;

  /// Consecutive hand-not-detected frames before a mid-draw hand loss is
  /// treated as a real occlusion ([DrawCancelled]) rather than a single
  /// dropped camera frame.
  static const int occlusionGraceFrameCount = 6;
}
