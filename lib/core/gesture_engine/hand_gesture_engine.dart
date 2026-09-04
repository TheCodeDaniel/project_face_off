import 'hand_landmark_frame.dart';

/// Source of raw hand-tracking frames. The real implementation wraps
/// MediaPipe Tasks Vision's Hand Landmarker (`hand_landmarker.task`,
/// `numHands: 1`, `runningMode: LIVE_STREAM`, GPU delegate with CPU
/// fallback) via a platform channel — NOT implemented yet, same documented
/// boundary as [GestureEngine]/Face Landmarker (see CLAUDE.md "What's
/// stubbed pending your credentials"): needs on-device validation before
/// committing to confidence thresholds and a package vs. hand-rolled
/// channel.
///
/// Consumers (Bow & Draw's domain layer) depend only on this abstraction,
/// never a concrete engine, so [DrawGestureDetector] is testable via
/// [FakeHandGestureEngine] with no camera or platform channel involved.
abstract class HandGestureEngine {
  Stream<HandLandmarkFrame> get frames;

  Future<void> start();
  Future<void> stop();
}
