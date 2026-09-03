import 'package:flutter/foundation.dart';

/// One sample of raw face-blendshape values, target ~30fps (Blueprint Section
/// 6 performance floor). Values are normalized 0.0–1.0 per MediaPipe Face
/// Landmarker convention.
@immutable
class BlendshapeFrame {
  const BlendshapeFrame({
    required this.timestamp,
    required this.browInnerUp,
    required this.jawOpen,
    required this.mouthCurvature,
  });

  final DateTime timestamp;

  /// Eyebrow-raise signal — drives dodge detection.
  final double browInnerUp;

  /// Mouth-open signal — drives fire detection.
  final double jawOpen;

  /// Smile-curvature signal — drives crack detection.
  final double mouthCurvature;
}
