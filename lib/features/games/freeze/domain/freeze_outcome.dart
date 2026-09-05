import 'package:flutter/foundation.dart';

/// Multi-game plan Section 2.3: "on an unpredictable stop cue, any player
/// whose tracked landmarks shift more than a configurable threshold during
/// the freeze window loses the round."
enum FreezeEndReason {
  /// One player moved past the threshold and the other didn't (in time).
  moved,

  /// Both players moved within the same jitter window — same rationale as
  /// Face Off's simultaneous-crack draw: don't let network/detection jitter
  /// produce an arbitrary single "loser."
  simultaneousMove,

  /// Neither player moved past the threshold before the window elapsed —
  /// nobody to penalize, replay the round.
  timeout,
}

/// Result of a resolved Freeze round: [winnerId] is null for a draw.
@immutable
class FreezeOutcome {
  const FreezeOutcome({required this.winnerId, required this.reason});

  final String? winnerId;
  final FreezeEndReason reason;

  bool get isDraw => winnerId == null;
}
