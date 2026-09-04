import 'package:flutter/foundation.dart';

/// Game-agnostic result of one resolved round, reported by any [GameModule]
/// to [MatchController] via its `roundOutcomes` stream. [reasonCode] uses the
/// same snake_case vocabulary the original master prompt specified for Face
/// Off's own reason codes (`fired_first`, `false_start`, `cracked`,
/// `simultaneous_crack`, `timeout`) — each game defines its own set of codes
/// (Bow & Draw's, Freeze's) using the same convention, and each game's own
/// presentation layer maps its codes to human-readable recap text (see
/// `faceOffOutcomeMessage`). [MatchController] itself never needs to
/// understand what a code means, only that one arrived.
@immutable
class MatchRoundOutcome {
  const MatchRoundOutcome({required this.winnerId, required this.reasonCode});

  final String? winnerId;
  final String reasonCode;

  bool get isDraw => winnerId == null;
}
