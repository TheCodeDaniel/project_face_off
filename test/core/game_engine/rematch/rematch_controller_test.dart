import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_face_off/core/game_engine/rematch/rematch_controller.dart';
import 'package:project_face_off/core/game_engine/rematch/rematch_repository.dart';
import 'package:project_face_off/core/game_engine/rematch/rematch_state.dart';

/// A repository double whose response is driven explicitly by the test,
/// rather than the real fake's own randomized delay — deterministic control
/// over exactly when/whether the "opponent" answers.
class _ControlledRematchRepository implements RematchRepository {
  final _controller = StreamController<RematchAnswer>();

  @override
  Stream<RematchAnswer> sendRequest({required String matchId, required String opponentId}) => _controller.stream;

  void respond(RematchAnswer answer) => _controller.add(answer);
}

void main() {
  group('RematchController', () {
    test('sendRequest enters Requesting with the full countdown, which ticks down every second', () {
      fakeAsync((async) {
        final repo = _ControlledRematchRepository();
        final container = ProviderContainer(overrides: [rematchRepositoryProvider.overrideWithValue(repo)]);
        addTearDown(container.dispose);
        container.listen(rematchControllerProvider, (_, _) {});
        final controller = container.read(rematchControllerProvider.notifier);

        controller.sendRequest(matchId: 'm1', opponentId: 'opp1');
        final first = container.read(rematchControllerProvider) as RematchRequesting;
        expect(first.secondsRemaining, 18);

        async.elapse(const Duration(seconds: 5));
        final later = container.read(rematchControllerProvider) as RematchRequesting;
        expect(later.secondsRemaining, 13);
      });
    });

    test('opponent accepting resolves to RematchAccepted with a new match id', () {
      fakeAsync((async) {
        final repo = _ControlledRematchRepository();
        final container = ProviderContainer(overrides: [rematchRepositoryProvider.overrideWithValue(repo)]);
        addTearDown(container.dispose);
        container.listen(rematchControllerProvider, (_, _) {});
        final controller = container.read(rematchControllerProvider.notifier);

        controller.sendRequest(matchId: 'm1', opponentId: 'opp1');
        repo.respond(RematchAnswer.accepted);
        async.flushMicrotasks();

        final result = container.read(rematchControllerProvider);
        expect(result, isA<RematchAccepted>());
        expect((result as RematchAccepted).matchId, isNotEmpty);
      });
    });

    test('opponent declining resolves to RematchDeclined', () {
      fakeAsync((async) {
        final repo = _ControlledRematchRepository();
        final container = ProviderContainer(overrides: [rematchRepositoryProvider.overrideWithValue(repo)]);
        addTearDown(container.dispose);
        container.listen(rematchControllerProvider, (_, _) {});
        final controller = container.read(rematchControllerProvider.notifier);

        controller.sendRequest(matchId: 'm1', opponentId: 'opp1');
        repo.respond(RematchAnswer.declined);
        async.flushMicrotasks();

        expect(container.read(rematchControllerProvider), isA<RematchDeclined>());
      });
    });

    test('no response before the window elapses resolves to RematchTimedOut', () {
      fakeAsync((async) {
        final repo = _ControlledRematchRepository();
        final container = ProviderContainer(overrides: [rematchRepositoryProvider.overrideWithValue(repo)]);
        addTearDown(container.dispose);
        container.listen(rematchControllerProvider, (_, _) {});
        final controller = container.read(rematchControllerProvider.notifier);

        controller.sendRequest(matchId: 'm1', opponentId: 'opp1');
        async.elapse(const Duration(seconds: 18));

        expect(container.read(rematchControllerProvider), isA<RematchTimedOut>());
      });
    });

    test('a late response after timeout is ignored — state stays RematchTimedOut', () {
      fakeAsync((async) {
        final repo = _ControlledRematchRepository();
        final container = ProviderContainer(overrides: [rematchRepositoryProvider.overrideWithValue(repo)]);
        addTearDown(container.dispose);
        container.listen(rematchControllerProvider, (_, _) {});
        final controller = container.read(rematchControllerProvider.notifier);

        controller.sendRequest(matchId: 'm1', opponentId: 'opp1');
        async.elapse(const Duration(seconds: 18));
        expect(container.read(rematchControllerProvider), isA<RematchTimedOut>());

        repo.respond(RematchAnswer.accepted);
        async.flushMicrotasks();
        expect(container.read(rematchControllerProvider), isA<RematchTimedOut>());
      });
    });

    test('cancel reverts to Idle and stops the countdown — the requester tapping Next mid-request', () {
      fakeAsync((async) {
        final repo = _ControlledRematchRepository();
        final container = ProviderContainer(overrides: [rematchRepositoryProvider.overrideWithValue(repo)]);
        addTearDown(container.dispose);
        container.listen(rematchControllerProvider, (_, _) {});
        final controller = container.read(rematchControllerProvider.notifier);

        controller.sendRequest(matchId: 'm1', opponentId: 'opp1');
        controller.cancel();
        expect(container.read(rematchControllerProvider), isA<RematchIdle>());

        // A response arriving after cancel must not resurrect the request.
        repo.respond(RematchAnswer.accepted);
        async.elapse(const Duration(seconds: 20));
        expect(container.read(rematchControllerProvider), isA<RematchIdle>());
      });
    });

    test('acknowledge reverts a Declined/TimedOut message back to Idle', () {
      fakeAsync((async) {
        final repo = _ControlledRematchRepository();
        final container = ProviderContainer(overrides: [rematchRepositoryProvider.overrideWithValue(repo)]);
        addTearDown(container.dispose);
        container.listen(rematchControllerProvider, (_, _) {});
        final controller = container.read(rematchControllerProvider.notifier);

        controller.sendRequest(matchId: 'm1', opponentId: 'opp1');
        repo.respond(RematchAnswer.declined);
        async.flushMicrotasks();
        expect(container.read(rematchControllerProvider), isA<RematchDeclined>());

        controller.acknowledge();
        expect(container.read(rematchControllerProvider), isA<RematchIdle>());
      });
    });
  });
}
