import '../../../../core/game_engine/match_controller.dart';
import '../../../../core/game_engine/match_round_outcome.dart';

/// Recap announcement text for a resolved Bow & Draw round, phrased from the
/// local player's perspective — same pattern as `faceOffOutcomeMessage`.
String bowDrawOutcomeMessage(MatchRoundOutcome outcome, String opponentLabel) {
  final iWon = outcome.winnerId == MatchController.meId;
  return switch (outcome.reasonCode) {
    'hit' => iWon ? 'Bullseye! You hit the target!' : '$opponentLabel hit the target!',
    'both_missed' => 'You both missed — round draw!',
    'timeout' => 'Nobody took a shot in time — round draw!',
    _ => 'Round over.',
  };
}
