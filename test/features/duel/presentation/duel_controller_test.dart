import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_face_off/features/duel/domain/round_state.dart';
import 'package:project_face_off/features/duel/presentation/duel_controller.dart';

void main() {
  group('DuelController', () {
    test('startMatch arms the cue, then fires it once the delay elapses', () {
      fakeAsync((async) {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        // duelControllerProvider is autoDispose (see its doc comment) so the
        // real DuelScreen's ref.watch tears down its Timers on exit; here we
        // need an explicit listener to keep it alive across the test the
        // same way that watch does, or the provider disposes itself between
        // reads and every read after the first sees a freshly-rebuilt state.
        container.listen(duelControllerProvider, (_, _) {});
        final controller = container.read(duelControllerProvider.notifier);

        controller.startMatch('Bot');
        expect(container.read(duelControllerProvider), isA<CueArmedRoundState>());

        async.elapse(const Duration(seconds: 5)); // past the max 4s cue delay
        expect(container.read(duelControllerProvider), isA<CueFiredRoundState>());
      });
    });

    test('my fire with no dodge resolves the round in my favor after the dodge window', () {
      fakeAsync((async) {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        container.listen(duelControllerProvider, (_, _) {});
        final controller = container.read(duelControllerProvider.notifier);

        controller.startMatch('Bot');
        async.elapse(const Duration(seconds: 5));

        controller.triggerFire(DuelController.meId);
        async.elapse(const Duration(milliseconds: 500));

        final result = container.read(duelControllerProvider) as RoundResultRoundState;
        expect(result.outcome.winnerId, DuelController.meId);
        expect(controller.scores[DuelController.meId], 1);
      });
    });

    test('a same-instant dodge resets to an open exchange (spec default)', () {
      fakeAsync((async) {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        container.listen(duelControllerProvider, (_, _) {});
        final controller = container.read(duelControllerProvider.notifier);

        controller.startMatch('Bot');
        async.elapse(const Duration(seconds: 5));

        controller.triggerFire(DuelController.meId);
        controller.triggerDodge(DuelController.opponentId);

        expect(container.read(duelControllerProvider), isA<CueFiredRoundState>());
        expect((container.read(duelControllerProvider) as CueFiredRoundState).attackerId, isNull);
      });
    });

    test('no fire from either side times out the round as a draw', () {
      fakeAsync((async) {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final controller = container.read(duelControllerProvider.notifier);

        // The cue-arm delay is randomized (1-4s), so the round-timeout firing
        // point (delay + 8s) plus the fixed 2.5s recap can land anywhere in a
        // multi-second window — asserting on the state at one fixed elapsed
        // duration is flaky (it can catch the round either mid-recap or
        // already advanced to round 2). Observe the transition instead of
        // snapshotting a timing-dependent instant. This listener also keeps
        // the autoDispose provider alive for the test, same as the others.
        RoundResultRoundState? firstResult;
        container.listen(duelControllerProvider, (previous, next) {
          if (next is RoundResultRoundState) firstResult ??= next;
        }, fireImmediately: false);

        controller.startMatch('Bot');
        async.elapse(const Duration(seconds: 20)); // comfortably past cue + timeout + recap

        expect(firstResult, isNotNull);
        expect(firstResult!.outcome.isDraw, isTrue);
      });
    });

    test('auto-advances to the next round after the recap pause', () {
      fakeAsync((async) {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        container.listen(duelControllerProvider, (_, _) {});
        final controller = container.read(duelControllerProvider.notifier);

        controller.startMatch('Bot');
        async.elapse(const Duration(seconds: 5));
        controller.triggerFire(DuelController.meId);
        async.elapse(const Duration(milliseconds: 500));
        expect(container.read(duelControllerProvider), isA<RoundResultRoundState>());

        async.elapse(const Duration(seconds: 3));
        expect(container.read(duelControllerProvider), isA<CueArmedRoundState>());
        expect(controller.scores[DuelController.meId], 1);
      });
    });
  });
}
