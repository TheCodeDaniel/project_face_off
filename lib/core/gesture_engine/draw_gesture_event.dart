import 'package:flutter/foundation.dart';

/// Clean, debounced events emitted upward from the draw-gesture-thresholding
/// isolate to Bow & Draw's domain layer (game/UI/backend guideline Section
/// 2). Bow & Draw's round engine only ever consumes these — never raw hand
/// landmarks — mirroring the same separation [SemanticGestureEvent] gives
/// Face Off.
@immutable
sealed class DrawGestureEvent {
  const DrawGestureEvent({required this.timestamp});

  /// Local device timestamp. Bow & Draw's round engine re-stamps this
  /// against the server-authoritative clock before using it for any timing
  /// decision — same server-timestamp-authority principle as Face Off's
  /// fire/dodge timing, now extended to draw/release timing per the
  /// guideline's guardrails.
  final DateTime timestamp;
}

/// Continuous update while a draw is in progress — `power` is normalized
/// 0.0 (at the at-rest anchor) to 1.0 (at the calibrated max draw distance).
/// This is the single most important visual feedback loop per the guideline:
/// the bow rig's draw-back animation is driven directly by this value.
final class DrawUpdate extends DrawGestureEvent {
  const DrawUpdate({required super.timestamp, required this.power});

  final double power;
}

/// A real release: rapid distance drop *combined with* a hand-openness
/// spread increase, not distance alone (a hand simply relaxing slowly back
/// toward the anchor is not a release). `power` is the draw power at the
/// moment just before release, i.e. what the shot should resolve with.
final class DrawReleased extends DrawGestureEvent {
  const DrawReleased({required super.timestamp, required this.power});

  final double power;
}

/// The hand was lost/occluded past the grace window mid-draw — the shot is
/// abandoned rather than resolved, distinct from a real [DrawReleased].
final class DrawCancelled extends DrawGestureEvent {
  const DrawCancelled({required super.timestamp});
}
