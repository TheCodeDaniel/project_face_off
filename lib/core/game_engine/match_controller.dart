import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'game_module.dart';
import 'game_module_factory.dart';
import 'game_pool.dart';
import 'match_offline_pause_provider.dart';
import 'match_round_outcome.dart';
import 'match_rules.dart';
import 'match_state.dart';

/// `autoDispose` so leaving the active game's screen (whether the match
/// finished or the player quit early) actually tears the controller down —
/// same reasoning as the old `duelControllerProvider`: an abandoned match's
/// timers shouldn't keep firing into a screen nobody's watching.
final matchControllerProvider = NotifierProvider.autoDispose<MatchController, MatchState>(MatchController.new);

/// Game-agnostic best-of-5 orchestrator (multi-game plan Section 3.2) —
/// extracted from what used to be `DuelController`. Holds whichever
/// [GameModule] is active for the current match, tracks scores and round
/// number, and decides recap → next round vs. match complete. It never
/// touches a game's own round-phase rules (cue timing, dodge windows,
/// whatever Bow & Draw's draw-power logic ends up being) — that's entirely
/// the active [GameModule]'s job.
class MatchController extends AutoDisposeNotifier<MatchState> {
  static const meId = 'me';
  static const opponentId = 'opponent';

  GameModule? _module;
  GameId? _activeGameId;
  String opponentLabel = 'Opponent';
  Map<String, int> _scores = {meId: 0, opponentId: 0};
  int _roundNumber = 1;

  StreamSubscription<MatchRoundOutcome>? _outcomeSub;
  Timer? _recapTimer;
  Timer? _forfeitTimer;
  bool _offlinePaused = false;

  @override
  MatchState build() {
    ref.onDispose(_disposeMatch);
    return const NoActiveMatchState();
  }

  /// The currently active game's module — the active game's own presentation
  /// layer casts this down to its concrete type (e.g. `FaceOffGameModule`)
  /// to read that game's richer round-phase state.
  GameModule get activeModule {
    final module = _module;
    if (module == null) throw StateError('No match has been started yet.');
    return module;
  }

  Map<String, int> get scores => _scores;
  int get roundNumber => _roundNumber;

  void startMatch(GameId gameId, String opponentLabel) {
    this.opponentLabel = opponentLabel;
    _cancelRoundTimers();
    _outcomeSub?.cancel();
    _module?.dispose();

    _activeGameId = gameId;
    _module = createGameModule(gameId, playerAId: meId, playerBId: opponentId);
    _scores = {meId: 0, opponentId: 0};
    _roundNumber = 1;
    _outcomeSub = _module!.roundOutcomes.listen(_onRoundOutcome);
    _module!.startRound();
    state = PlayingRoundMatchState(gameId: gameId);
  }

  void _onRoundOutcome(MatchRoundOutcome outcome) {
    final winnerId = outcome.winnerId;
    if (winnerId != null) {
      _scores[winnerId] = (_scores[winnerId] ?? 0) + 1;
    }
    state = RoundRecapMatchState(outcome: outcome, scores: Map.unmodifiable(_scores), roundNumber: _roundNumber);

    _recapTimer?.cancel();
    _recapTimer = Timer(MatchRules.roundRecapDuration, _advanceAfterRecap);
  }

  void _advanceAfterRecap() {
    final winner = _scores.entries.where((e) => e.value >= MatchRules.roundsToWinMatch).firstOrNull;
    if (winner != null) {
      state = MatchCompleteMatchState(winnerId: winner.key, scores: Map.unmodifiable(_scores));
      return;
    }
    _roundNumber++;
    _module!.resetRound();
    _module!.startRound();
    state = PlayingRoundMatchState(gameId: _activeGameId!);
  }

  /// Master prompt Section 12 / Blueprint Section 5: "if offline during an
  /// active match, the match pauses locally ... with a reasonable timeout
  /// before the match is forfeited gracefully." Going offline cancels every
  /// in-flight match/round timer and starts the forfeit countdown; coming
  /// back online cancels that countdown and re-deals the current round from
  /// a fresh start — simpler than reconstructing exactly where a paused
  /// round left off, and no less fair given neither player could act during
  /// the pause anyway.
  void handleConnectivityChange(bool isOnline) {
    if (state is MatchCompleteMatchState || state is NoActiveMatchState) return;

    if (!isOnline && !_offlinePaused) {
      _offlinePaused = true;
      ref.read(matchOfflinePauseProvider.notifier).state = true;
      _cancelRoundTimers();
      _module?.resetRound();
      _forfeitTimer = Timer(MatchRules.offlineForfeitTimeout, () {
        // This device is the one that went offline, so it's the one
        // forfeiting — the opponent is credited with the win.
        _module?.resetRound();
        _offlinePaused = false;
        ref.read(matchOfflinePauseProvider.notifier).state = false;
        state = MatchCompleteMatchState(winnerId: opponentId, scores: Map.unmodifiable(_scores));
      });
    } else if (isOnline && _offlinePaused) {
      _offlinePaused = false;
      ref.read(matchOfflinePauseProvider.notifier).state = false;
      _forfeitTimer?.cancel();
      _forfeitTimer = null;
      _module?.startRound();
      state = PlayingRoundMatchState(gameId: _activeGameId!);
    }
  }

  void _cancelRoundTimers() {
    _recapTimer?.cancel();
    _forfeitTimer?.cancel();
  }

  void _disposeMatch() {
    _cancelRoundTimers();
    _outcomeSub?.cancel();
    _module?.dispose();
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
