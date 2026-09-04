import 'package:flutter/foundation.dart';

/// Round win condition (multi-game plan Section 2.2): **first player to land
/// a clean hit wins outright** — chosen over "best shot placement within the
/// whole window" for the first playable pass, since it stays decisive and
/// mirrors Face Off's own "first successful action wins" shape rather than
/// needing to wait out the full window before ever declaring a winner. A
/// tunable, not a rule to agonize over, per the plan's own instruction.
enum DrawEndReason {
  hit,

  /// Both players took a shot and neither landed within tolerance.
  bothMissed,

  timeout,
}

/// Result of a resolved Bow & Draw round: [winnerId] is null for a draw.
@immutable
class DrawOutcome {
  const DrawOutcome({required this.winnerId, required this.reason});

  final String? winnerId;
  final DrawEndReason reason;

  bool get isDraw => winnerId == null;
}
