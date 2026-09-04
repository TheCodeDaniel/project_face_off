import 'package:flutter/foundation.dart';

enum RoundEndReason {
  firedFirst,
  falseStart,
  cracked,
  simultaneousCrack,
  timeout,

  /// Only reachable when [RoundRules.dodgeEndsRoundOnSuccess] is flipped on —
  /// see CLAUDE.md / master prompt Section 8.4 tunable-rule note.
  dodged,
}

/// Result of a resolved round: [winnerId] is null for a draw.
@immutable
class RoundOutcome {
  const RoundOutcome({required this.winnerId, required this.reason});

  final String? winnerId;
  final RoundEndReason reason;

  bool get isDraw => winnerId == null;
}
