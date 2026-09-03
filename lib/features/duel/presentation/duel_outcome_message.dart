import '../domain/round_outcome.dart';
import 'duel_controller.dart';

/// Recap announcement text for a resolved round (master prompt Section 8.4
/// RoundResult phase — "Fire an ActivityToast-style announcement of what
/// happened"), phrased from the local player's perspective.
String duelOutcomeMessage(RoundOutcome outcome, String opponentLabel) {
  final iWon = outcome.winnerId == DuelController.meId;
  return switch (outcome.reason) {
    RoundEndReason.firedFirst => iWon ? 'You fired first!' : '$opponentLabel fired first!',
    RoundEndReason.falseStart => iWon ? '$opponentLabel false started!' : 'False start — you fired too early!',
    RoundEndReason.cracked => iWon ? '$opponentLabel cracked!' : 'You cracked!',
    RoundEndReason.dodged => iWon ? 'You dodged in time!' : '$opponentLabel dodged in time!',
    RoundEndReason.simultaneousCrack => 'You both cracked — round draw!',
    RoundEndReason.timeout => 'Nobody fired in time — round draw!',
  };
}
