import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../match_rules.dart';
import 'fake_rematch_repository.dart';
import 'rematch_repository.dart';
import 'rematch_state.dart';

/// Overridden with a real Firebase-backed implementation once a Realtime DB
/// project exists — see CLAUDE.md.
final rematchRepositoryProvider = Provider<RematchRepository>((ref) => FakeRematchRepository());

/// `autoDispose` so leaving the results screen (Next, backing out, or the
/// idle timeout firing) tears down any in-flight request's subscription and
/// countdown `Timer` — same reasoning as `matchControllerProvider`.
final rematchControllerProvider = NotifierProvider.autoDispose<RematchController, RematchState>(RematchController.new);

/// Drives one rematch request end-to-end from the requester's side (post-
/// match flow plan Section 3). Uses `clock.now()` (package:clock), never raw
/// `DateTime.now()`, so the countdown is deterministically testable with
/// `package:fake_async` — see engineering rule 10 / CLAUDE.md.
class RematchController extends AutoDisposeNotifier<RematchState> {
  StreamSubscription<RematchAnswer>? _responseSub;
  Timer? _countdownTimer;

  @override
  RematchState build() {
    ref.onDispose(_cancelInternal);
    return const RematchIdle();
  }

  void sendRequest({required String matchId, required String opponentId}) {
    _cancelInternal();
    final expiresAt = clock.now().add(MatchRules.rematchRequestTimeout);
    state = RematchRequesting(secondsRemaining: MatchRules.rematchRequestTimeout.inSeconds);

    _responseSub = ref.read(rematchRepositoryProvider).sendRequest(matchId: matchId, opponentId: opponentId).listen((
      answer,
    ) {
      _cancelInternal();
      state = switch (answer) {
        RematchAnswer.accepted => RematchAccepted(matchId: 'rematch-${clock.now().microsecondsSinceEpoch}'),
        RematchAnswer.declined => const RematchDeclined(),
      };
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = expiresAt.difference(clock.now());
      if (!remaining.isNegative && remaining > Duration.zero) {
        state = RematchRequesting(secondsRemaining: remaining.inSeconds);
        return;
      }
      _cancelInternal();
      state = const RematchTimedOut();
    });
  }

  /// The requester tapping Next (or otherwise leaving) cancels their own
  /// pending request — plan: "The requester is never blocked from doing
  /// something else while waiting... which cancels their own pending
  /// request."
  void cancel() {
    _cancelInternal();
    state = const RematchIdle();
  }

  /// Returns to the normal results-screen state after showing a declined/
  /// timed-out message — called by the UI once it's done displaying that
  /// transient state, not automatically, so the message doesn't vanish
  /// before the player reads it.
  void acknowledge() {
    state = const RematchIdle();
  }

  void _cancelInternal() {
    _responseSub?.cancel();
    _responseSub = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }
}
