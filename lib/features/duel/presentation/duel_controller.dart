import 'dart:async';
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/duel_round_engine.dart';
import '../domain/round_rules.dart';
import '../domain/round_state.dart';

/// `autoDispose` so leaving [DuelScreen] (whether the match finished or the
/// player quit early via [QuitMatchDialog]) actually tears the controller
/// down — `ref.onDispose(_cancelTimers)` below only fires once nothing is
/// watching this anymore, otherwise an abandoned match's cue/round-timeout
/// `Timer`s would keep firing into a screen nobody's looking at.
final duelControllerProvider = NotifierProvider.autoDispose<DuelController, RoundState>(DuelController.new);

/// Drives one live duel end-to-end against the [DuelRoundEngine] built in
/// the first build phase. Uses `clock.now()` (package:clock), never raw
/// `DateTime.now()`, so tests can fast-forward through cue/dodge/round
/// timeouts deterministically with `package:fake_async` — see
/// `test/features/duel/presentation/duel_controller_test.dart`.
///
/// **No camera or opponent networking exists yet** (see CLAUDE.md) — both
/// sides' fire/dodge/crack gestures are driven manually via
/// [triggerFire]/[triggerDodge]/[triggerCrack] from the dev gesture-controls
/// panel in `DuelScreen`, in place of the real gesture engine and the
/// Firebase Realtime DB signaling channel (master prompt Section 8.5). Both
/// players auto-confirm "neutral" immediately for the same reason — there's
/// no face to actually check yet.
class DuelController extends AutoDisposeNotifier<RoundState> {
  static const meId = 'me';
  static const opponentId = 'opponent';

  late DuelRoundEngine _engine;
  String opponentLabel = 'Opponent';
  final _random = Random();

  Timer? _cueTimer;
  Timer? _dodgeTimeoutTimer;
  Timer? _crackTimeoutTimer;
  Timer? _roundTimeoutTimer;
  Timer? _recapTimer;

  @override
  RoundState build() {
    _engine = DuelRoundEngine(playerAId: meId, playerBId: opponentId);
    ref.onDispose(_cancelTimers);
    return _engine.state;
  }

  Map<String, int> get scores => _engine.scores;
  int get roundNumber => _engine.roundNumber;

  void startMatch(String opponentName) {
    opponentLabel = opponentName;
    _engine = DuelRoundEngine(playerAId: meId, playerBId: opponentId);
    _beginRound();
  }

  void _beginRound() {
    _cancelTimers();
    _engine.startNeutralPhase();
    _engine.playerReachedNeutral(meId);
    _engine.playerReachedNeutral(opponentId);

    final delayRange = RoundRules.cueDelayMax.inMilliseconds - RoundRules.cueDelayMin.inMilliseconds;
    final delay = Duration(milliseconds: RoundRules.cueDelayMin.inMilliseconds + _random.nextInt(delayRange));
    _engine.armCue(clock.now().add(delay));
    state = _engine.state;

    _cueTimer = Timer(delay, () {
      _engine.fireCue(clock.now());
      state = _engine.state;
      _roundTimeoutTimer = Timer(RoundRules.roundTimeout, () {
        _engine.checkRoundTimeout(clock.now());
        _resolveIfNeeded();
      });
    });
  }

  void triggerFire(String playerId) {
    _engine.onFireGesture(playerId, clock.now());
    state = _engine.state;
    final s = _engine.state;
    if (s is CueFiredRoundState && s.attackerId == playerId) {
      _dodgeTimeoutTimer?.cancel();
      _dodgeTimeoutTimer = Timer(RoundRules.dodgeWindow + const Duration(milliseconds: 60), () {
        _engine.checkDodgeWindowElapsed(clock.now());
        _resolveIfNeeded();
      });
    }
    _resolveIfNeeded();
  }

  void triggerDodge(String playerId) {
    _engine.onDodgeGesture(playerId, clock.now());
    _resolveIfNeeded();
  }

  void triggerCrack(String playerId) {
    _engine.onCrackGesture(playerId, clock.now());
    state = _engine.state;
    if (_engine.state is ResolvingRoundState) {
      _crackTimeoutTimer?.cancel();
      _crackTimeoutTimer = Timer(RoundRules.simultaneousCrackWindow + const Duration(milliseconds: 30), () {
        _engine.checkCrackWindowElapsed(clock.now());
        _resolveIfNeeded();
      });
    }
    _resolveIfNeeded();
  }

  void _resolveIfNeeded() {
    state = _engine.state;
    if (state is! RoundResultRoundState) return;
    _cueTimer?.cancel();
    _dodgeTimeoutTimer?.cancel();
    _crackTimeoutTimer?.cancel();
    _roundTimeoutTimer?.cancel();

    _recapTimer?.cancel();
    _recapTimer = Timer(const Duration(milliseconds: 2500), () {
      _engine.advanceAfterRecap();
      state = _engine.state;
      if (state is NeutralRoundState) _beginRound();
    });
  }

  void _cancelTimers() {
    _cueTimer?.cancel();
    _dodgeTimeoutTimer?.cancel();
    _crackTimeoutTimer?.cancel();
    _roundTimeoutTimer?.cancel();
    _recapTimer?.cancel();
  }
}
