import 'package:flutter/foundation.dart';

/// Clean, debounced events emitted upward from the gesture-thresholding
/// isolate to the duel state machine (master prompt Section 8.6). The state
/// machine only ever consumes these — never raw blendshape numbers — which
/// keeps it unit-testable without a camera.
@immutable
sealed class SemanticGestureEvent {
  const SemanticGestureEvent({required this.timestamp});

  /// Local device timestamp the gesture was detected at. The duel domain
  /// layer re-stamps this against the server-authoritative clock before
  /// using it for any timing decision (Section 8.5) — never trust this value
  /// directly for fairness-sensitive comparisons.
  final DateTime timestamp;
}

final class FireDetected extends SemanticGestureEvent {
  const FireDetected({required super.timestamp});
}

final class DodgeDetected extends SemanticGestureEvent {
  const DodgeDetected({required super.timestamp});
}

final class CrackDetected extends SemanticGestureEvent {
  const CrackDetected({required super.timestamp});
}
