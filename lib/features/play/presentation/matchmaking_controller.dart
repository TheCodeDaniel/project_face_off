import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/fake_matchmaking_repository.dart';
import '../domain/matchmaking_repository.dart';
import '../domain/matchmaking_state.dart';

/// Overridden with a real Firebase-backed implementation once a queue
/// document/collection exists — see CLAUDE.md.
final matchmakingRepositoryProvider = Provider<MatchmakingRepository>((ref) => FakeMatchmakingRepository());

final matchmakingControllerProvider = NotifierProvider<MatchmakingController, MatchmakingState>(
  MatchmakingController.new,
);

/// Drives the Quick Match queue flow (master prompt Section 7): tap Quick
/// Match -> [MatchmakingSearching] (cancel always available) -> exactly one
/// of [MatchmakingFound] or [MatchmakingTimedOut]. A `Notifier`, per the
/// project's state-management rule, since this is small local mutable state
/// with no async-value wrapping needed.
class MatchmakingController extends Notifier<MatchmakingState> {
  StreamSubscription<MatchmakingState>? _subscription;

  @override
  MatchmakingState build() {
    ref.onDispose(() => _subscription?.cancel());
    return const MatchmakingIdle();
  }

  void startQueue() {
    _subscription?.cancel();
    state = const MatchmakingSearching();
    _subscription = ref.read(matchmakingRepositoryProvider).joinQueue().listen((s) => state = s);
  }

  void cancelQueue() {
    _subscription?.cancel();
    _subscription = null;
    state = const MatchmakingIdle();
  }
}
