import 'dart:async';
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/game_engine/game_module.dart';
import '../../../../core/game_engine/landmarker_type.dart';
import '../../../../core/game_engine/match_round_outcome.dart';
import 'face_off_round_engine.dart';
import 'round_outcome.dart';
import 'round_rules.dart';
import 'round_state.dart';

/// Face Off's [GameModule] — the piece `MatchController` actually talks to.
/// Wraps [FaceOffRoundEngine] and owns the round-timing `Timer`s that used
/// to live directly on the old `DuelController` (cue arm/fire, dodge/round-
/// timeout/crack-window checks). Uses `clock.now()` (package:clock), never
/// raw `DateTime.now()`, so tests can fast-forward deterministically with
/// `package:fake_async`.
///
/// **No camera or opponent networking exists yet** (see CLAUDE.md) — both
/// sides' fire/dodge/crack gestures are driven manually via
/// [triggerFire]/[triggerDodge]/[triggerCrack] from the dev gesture-controls
/// panel in `FaceOffScreen`, in place of the real gesture engine and the
/// Firebase Realtime DB signaling channel. Both players auto-confirm
/// "neutral" immediately for the same reason.
///
/// A [ChangeNotifier] (not a Riverpod provider itself) so the active game's
/// screen can listen to [roundState] directly via `ListenableBuilder` —
/// `MatchController` only cares about [roundOutcomes], never this richer
/// per-round detail.
class FaceOffGameModule extends ChangeNotifier implements GameModule {
  FaceOffGameModule({required this.playerAId, required this.playerBId})
    : _engine = FaceOffRoundEngine(playerAId: playerAId, playerBId: playerBId);

  final String playerAId;
  final String playerBId;
  final _random = Random();
  final _outcomeController = StreamController<MatchRoundOutcome>.broadcast();

  final FaceOffRoundEngine _engine;

  Timer? _cueTimer;
  Timer? _dodgeTimeoutTimer;
  Timer? _crackTimeoutTimer;
  Timer? _roundTimeoutTimer;

  @override
  String get id => 'face_off';

  @override
  String get displayName => 'Face Off';

  @override
  Set<LandmarkerType> get requiredLandmarkers => const {LandmarkerType.face};

  @override
  Stream<MatchRoundOutcome> get roundOutcomes => _outcomeController.stream;

  RoundState get roundState => _engine.state;

  @override
  void startRound() {
    _cancelTimers();
    _engine.startNeutralPhase();
    _engine.playerReachedNeutral(playerAId);
    _engine.playerReachedNeutral(playerBId);

    final delayRange = RoundRules.cueDelayMax.inMilliseconds - RoundRules.cueDelayMin.inMilliseconds;
    final delay = Duration(milliseconds: RoundRules.cueDelayMin.inMilliseconds + _random.nextInt(delayRange));
    _engine.armCue(clock.now().add(delay));
    notifyListeners();

    _cueTimer = Timer(delay, () {
      _engine.fireCue(clock.now());
      notifyListeners();
      _roundTimeoutTimer = Timer(RoundRules.roundTimeout, () {
        _engine.checkRoundTimeout(clock.now());
        _resolveIfNeeded();
      });
    });
  }

  @override
  void resetRound() => _cancelTimers();

  void triggerFire(String playerId) {
    _engine.onFireGesture(playerId, clock.now());
    notifyListeners();
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
    notifyListeners();
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
    notifyListeners();
    final s = _engine.state;
    if (s is! RoundResultRoundState) return;
    _cueTimer?.cancel();
    _dodgeTimeoutTimer?.cancel();
    _crackTimeoutTimer?.cancel();
    _roundTimeoutTimer?.cancel();
    _outcomeController.add(MatchRoundOutcome(winnerId: s.outcome.winnerId, reasonCode: _reasonCode(s.outcome.reason)));
  }

  String _reasonCode(RoundEndReason reason) => switch (reason) {
    RoundEndReason.firedFirst => 'fired_first',
    RoundEndReason.falseStart => 'false_start',
    RoundEndReason.cracked => 'cracked',
    RoundEndReason.simultaneousCrack => 'simultaneous_crack',
    RoundEndReason.timeout => 'timeout',
    RoundEndReason.dodged => 'dodged',
  };

  void _cancelTimers() {
    _cueTimer?.cancel();
    _dodgeTimeoutTimer?.cancel();
    _crackTimeoutTimer?.cancel();
    _roundTimeoutTimer?.cancel();
  }

  @override
  void dispose() {
    _cancelTimers();
    _outcomeController.close();
    super.dispose();
  }
}
