import '../../../../core/game_engine/match_controller.dart';
import '../../../../core/game_engine/match_round_outcome.dart';

/// Recap announcement text for a resolved Face Off round (master prompt
/// Section 8.4 RoundResult phase — "Fire an ActivityToast-style
/// announcement of what happened"), phrased from the local player's
/// perspective. Switches on [MatchRoundOutcome.reasonCode] — the same
/// snake_case codes the master prompt itself names
/// (`fired_first`/`false_start`/`cracked`/`simultaneous_crack`/`timeout`),
/// which `FaceOffGameModule` produces from its own `RoundEndReason`.
String faceOffOutcomeMessage(MatchRoundOutcome outcome, String opponentLabel) {
  final iWon = outcome.winnerId == MatchController.meId;
  return switch (outcome.reasonCode) {
    'fired_first' => iWon ? 'You fired first!' : '$opponentLabel fired first!',
    'false_start' => iWon ? '$opponentLabel false started!' : 'False start — you fired too early!',
    'cracked' => iWon ? '$opponentLabel cracked!' : 'You cracked!',
    'dodged' => iWon ? 'You dodged in time!' : '$opponentLabel dodged in time!',
    'simultaneous_crack' => 'You both cracked — round draw!',
    'timeout' => 'Nobody fired in time — round draw!',
    _ => 'Round over.',
  };
}
