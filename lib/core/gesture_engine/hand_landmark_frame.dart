import 'package:flutter/foundation.dart';

/// One sample of raw hand-tracking data, target ~30fps (same performance
/// floor as [BlendshapeFrame]). MediaPipe Hand Landmarker reports 21 3D
/// landmarks per hand; this app only needs a simplified pinch-point position
/// plus an overall openness measure — the same "reduce to what the game
/// actually needs" simplification [BlendshapeFrame] already applies to the
/// full 52-value face blendshape set.
@immutable
class HandLandmarkFrame {
  const HandLandmarkFrame({
    required this.timestamp,
    required this.handDetected,
    this.pinchX = 0,
    this.pinchY = 0,
    this.handOpenness = 0,
  });

  final DateTime timestamp;

  /// `false` when this frame's camera tick found no hand (occlusion, hand
  /// left frame, etc.) — the engine keeps emitting frames at the camera's
  /// rate either way rather than going silent, so occlusion can be debounced
  /// via a consecutive-frame streak the same way fire/dodge/crack are,
  /// instead of needing a wall-clock timer inside the detection isolate.
  final bool handDetected;

  /// Normalized (0.0-1.0) camera-space position of the tracked pinch point
  /// (midpoint of thumb tip and index tip) — the point whose distance from
  /// an at-rest anchor becomes draw distance. Meaningless when
  /// [handDetected] is `false`.
  final double pinchX;
  final double pinchY;

  /// Normalized (0.0-1.0) hand-openness/spread measure — low for a closed
  /// pinch/fist, high for a splayed-open hand. Drives release detection
  /// (a real release is a rapid distance drop *combined with* a spread
  /// increase, not distance alone — see `DrawGestureThresholds`).
  final double handOpenness;
}
