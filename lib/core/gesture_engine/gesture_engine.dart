import 'blendshape_frame.dart';

/// Source of raw blendshape frames. The real implementation wraps MediaPipe
/// Face Landmarker via a platform channel — NOT implemented yet, see
/// CLAUDE.md "What's stubbed pending your credentials": blendshape output
/// (`browInnerUp`, `jawOpen`, mouth-curvature) needs on-device verification
/// against a real camera before committing to a package vs. a hand-rolled
/// channel under this same interface.
///
/// Consumers (the duel domain layer) depend only on this abstraction, never
/// on a concrete engine, so the state machine is testable via
/// [FakeGestureEngine] with no camera or platform channel involved.
abstract class GestureEngine {
  Stream<BlendshapeFrame> get frames;

  Future<void> start();
  Future<void> stop();
}
