import 'dart:ui' show lerpDouble;

import 'package:flutter/animation.dart';

/// Timeline for the launch splash's three-clash choreography: two probing
/// jabs that bounce off each other, then a final full-force clash that
/// cracks the screen open. Shared between `AnimatedSplashScreen` (gloves,
/// flash, shake, title) and `SplashCrackPainter` (the crack itself, which
/// starts exactly at [finalImpact]) so the beats stay in sync from one
/// source of truth instead of duplicated magic numbers.
abstract final class SplashTimeline {
  static const beat1WindUp = 0.05;
  static const beat1Lunge = 0.16;
  static const beat1Recoil = 0.26;
  static const beat2WindUp = 0.30;
  static const beat2Lunge = 0.42;
  static const beat2Recoil = 0.52;
  static const beat3WindUp = 0.58;

  /// The final clash — the moment everything else (crack, title punch-in,
  /// glove fade) is timed off.
  static const finalImpact = 0.70;

  static const titlePunchEnd = 0.88;
  static const gloveFadeEnd = 0.84;
  static const taglineStart = 0.92;

  /// (time, relative intensity) for each of the three clashes — the flash
  /// and screen-shake read both, escalating to the final one.
  static const impacts = [
    (t: beat1Lunge, intensity: 0.35),
    (t: beat2Lunge, intensity: 0.65),
    (t: finalImpact, intensity: 1.0),
  ];
}

/// One point in a piecewise animation curve: at time [t] the value is
/// [value]; [curve] eases the segment arriving at this keyframe.
class SplashKeyframe {
  const SplashKeyframe(this.t, this.value, [this.curve = Curves.easeInOut]);

  final double t;
  final double value;
  final Curve curve;
}

/// Interpolates [frames] (sorted by `t`) at time [t] — the generic engine
/// behind the gloves' punch/recoil distance across all three clash beats,
/// so their motion is one keyframe list instead of a pile of if/else phase
/// branches.
double keyframedValue(double t, List<SplashKeyframe> frames) {
  if (t <= frames.first.t) return frames.first.value;
  for (var i = 1; i < frames.length; i++) {
    if (t <= frames[i].t) {
      final prev = frames[i - 1];
      final cur = frames[i];
      final localT = ((t - prev.t) / (cur.t - prev.t)).clamp(0.0, 1.0);
      return lerpDouble(prev.value, cur.value, cur.curve.transform(localT))!;
    }
  }
  return frames.last.value;
}
