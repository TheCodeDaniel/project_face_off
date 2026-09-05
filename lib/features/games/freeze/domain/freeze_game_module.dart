import 'dart:async';
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/game_engine/game_module.dart';
import '../../../../core/game_engine/landmarker_type.dart';
import '../../../../core/game_engine/match_round_outcome.dart';
import 'freeze_outcome.dart';
import 'freeze_round_engine.dart';
import 'freeze_rules.dart';
import 'freeze_state.dart';

/// Freeze's [GameModule] — same shape as `FaceOffGameModule`: wraps
/// [FreezeRoundEngine], owns the build-up/freeze-window/move-jitter
/// `Timer`s, and is a [ChangeNotifier] so the screen can listen to
/// [freezeState] directly while `MatchController` only ever sees the
/// coarser [roundOutcomes] stream.
///
/// **No camera exists yet** — motion samples are driven manually via
/// [triggerMove] from a dev gesture-controls panel, standing in for the
/// real per-frame landmark-delta stream ("reuses whichever landmarker(s)
/// are already active" per the plan — no new model this game needs).
class FreezeGameModule extends ChangeNotifier implements GameModule {
  FreezeGameModule({required this.playerAId, required this.playerBId})
    : _engine = FreezeRoundEngine(playerAId: playerAId, playerBId: playerBId);

  final String playerAId;
  final String playerBId;
  final _random = Random();
  final _outcomeController = StreamController<MatchRoundOutcome>.broadcast();

  final FreezeRoundEngine _engine;
  Timer? _buildUpTimer;
  Timer? _freezeWindowTimer;
  Timer? _moveJitterTimer;

  /// Guards against re-emitting an outcome for a round that already
  /// resolved — see `BowDrawGameModule._emittedThisRound`'s doc comment for
  /// the full failure mode this prevents.
  bool _emittedThisRound = false;

  @override
  String get id => 'freeze';

  @override
  String get displayName => 'Freeze';

  // Reuses whichever landmarker(s) the match already has active for its
  // other detection needs (multi-game plan Section 2.3) rather than
  // declaring its own.
  @override
  Set<LandmarkerType> get requiredLandmarkers => const {};

  @override
  Stream<MatchRoundOutcome> get roundOutcomes => _outcomeController.stream;

  FreezeState get freezeState => _engine.state;

  @override
  void startRound() {
    _cancelTimers();
    _engine.reset();
    _emittedThisRound = false;
    final range = FreezeRules.buildUpMax.inMilliseconds - FreezeRules.buildUpMin.inMilliseconds;
    final delay = Duration(milliseconds: FreezeRules.buildUpMin.inMilliseconds + _random.nextInt(range));
    notifyListeners();

    _buildUpTimer = Timer(delay, () {
      final windowEndsAt = clock.now().add(FreezeRules.freezeWindow);
      _engine.callFreeze(windowEndsAt);
      notifyListeners();
      _freezeWindowTimer = Timer(FreezeRules.freezeWindow, () {
        _engine.checkWindowElapsed(clock.now());
        _resolveIfNeeded();
      });
    });
  }

  @override
  void resetRound() => _cancelTimers();

  void triggerMove(String playerId) {
    _engine.onMotionSample(playerId, FreezeRules.motionThreshold + 0.1, clock.now());
    notifyListeners();
    if (_engine.state is ResolvingFreezeState) {
      _moveJitterTimer?.cancel();
      _moveJitterTimer = Timer(FreezeRules.simultaneousMoveWindow + const Duration(milliseconds: 30), () {
        _engine.checkMoveWindowElapsed(clock.now());
        _resolveIfNeeded();
      });
    }
    _resolveIfNeeded();
  }

  void _resolveIfNeeded() {
    notifyListeners();
    final s = _engine.state;
    if (s is! FreezeResultState || _emittedThisRound) return;
    _emittedThisRound = true;
    _cancelTimers();
    _outcomeController.add(MatchRoundOutcome(winnerId: s.outcome.winnerId, reasonCode: _reasonCode(s.outcome.reason)));
  }

  String _reasonCode(FreezeEndReason reason) => switch (reason) {
    FreezeEndReason.moved => 'moved',
    FreezeEndReason.simultaneousMove => 'simultaneous_move',
    FreezeEndReason.timeout => 'timeout',
  };

  void _cancelTimers() {
    _buildUpTimer?.cancel();
    _freezeWindowTimer?.cancel();
    _moveJitterTimer?.cancel();
  }

  @override
  void dispose() {
    _cancelTimers();
    _outcomeController.close();
    super.dispose();
  }
}
