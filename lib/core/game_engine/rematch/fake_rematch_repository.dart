import 'dart:async';
import 'dart:math';

import 'rematch_repository.dart';

/// In-memory [RematchRepository] used until a real Firebase Realtime DB
/// project exists (see CLAUDE.md). Simulates an opponent's response after a
/// short random delay, comfortably under `MatchRules.rematchRequestTimeout`
/// so the accept/decline paths get real screen time in dev builds, same
/// reasoning as [FakeMatchmakingRepository]'s own timeout-chance simulation.
/// With [_neverRespondsChance] probability, simulates the opponent having
/// already left the results screen (per the plan: "the request simply times
/// out on the requester's side") by never emitting at all — the stream just
/// stays open, exactly as a real Realtime DB listener would if nothing ever
/// writes a response node; [RematchController]'s own local timer is what
/// actually resolves that case, not this repository.
class FakeRematchRepository implements RematchRepository {
  static const _acceptChance = 0.7;
  static const _neverRespondsChance = 1 / 6;

  @override
  Stream<RematchAnswer> sendRequest({required String matchId, required String opponentId}) async* {
    final random = Random();
    if (random.nextDouble() < _neverRespondsChance) return;

    await Future<void>.delayed(Duration(milliseconds: 1500 + random.nextInt(8000)));
    yield random.nextDouble() < _acceptChance ? RematchAnswer.accepted : RematchAnswer.declined;
  }
}
