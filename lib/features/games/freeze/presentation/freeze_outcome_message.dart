import '../../../../core/game_engine/match_controller.dart';
import '../../../../core/game_engine/match_round_outcome.dart';

/// Recap announcement text for a resolved Freeze round, phrased from the
/// local player's perspective — same pattern as `faceOffOutcomeMessage`.
String freezeOutcomeMessage(MatchRoundOutcome outcome, String opponentLabel) {
  final iWon = outcome.winnerId == MatchController.meId;
  return switch (outcome.reasonCode) {
    'moved' => iWon ? '$opponentLabel moved first!' : 'You moved — busted!',
    'simultaneous_move' => 'You both moved — round draw!',
    'timeout' => 'Nobody budged — round draw!',
    _ => 'Round over.',
  };
}
