import 'landmarker_type.dart';
import 'match_round_outcome.dart';

/// The contract every game in the pool implements (multi-game plan Section
/// 3.1) so [MatchController] never needs game-specific knowledge — it only
/// ever calls [startRound]/[resetRound] and listens to [roundOutcomes].
///
/// Each game's own domain layer owns translating its raw gesture/motion
/// stream into its own semantic events and resolving them into a single
/// round's [MatchRoundOutcome] — [MatchController] only sees the outcome,
/// never the game's internal round-phase state machine. That richer
/// per-round state (Face Off's `RoundState`, say) is exposed by the concrete
/// module for that game's own presentation layer to render, outside this
/// shared contract.
abstract class GameModule {
  /// Stable id, e.g. `'face_off'` — also the [GamePool] entry's id and the
  /// value persisted as `matches/{matchId}.gameId` once a real backend
  /// exists (multi-game plan Section 4.4).
  String get id;

  String get displayName;

  /// Which gesture pipeline(s) this game needs active for the match.
  Set<LandmarkerType> get requiredLandmarkers;

  /// Emits exactly one [MatchRoundOutcome] each time a round this module is
  /// running resolves. [MatchController] updates match-level score/round
  /// count from this and decides recap → next round vs. match complete.
  Stream<MatchRoundOutcome> get roundOutcomes;

  /// Begin (or resume, after [resetRound]) a single round.
  void startRound();

  /// Cancel whatever timers/state the current round has in flight, without
  /// tearing the module down — used by [MatchController] between rounds and
  /// when a match pauses for a connectivity loss or forfeits.
  void resetRound();

  /// Release any resources (timers, stream controllers) permanently — called
  /// once when the match ends or the module is replaced (e.g. a rematch).
  void dispose();
}
