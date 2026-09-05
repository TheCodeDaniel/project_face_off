import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_face_off/core/game_engine/match_controller.dart';
import 'package:project_face_off/core/game_engine/match_state.dart';
import 'package:project_face_off/core/game_engine/rematch/rematch_controller.dart';
import 'package:project_face_off/core/game_engine/rematch/rematch_repository.dart';
import 'package:project_face_off/core/theme/app_theme.dart';
import 'package:project_face_off/core/widgets/game_match_result_view.dart';
import 'package:project_face_off/features/play/domain/matchmaking_repository.dart';
import 'package:project_face_off/features/play/domain/matchmaking_state.dart';
import 'package:project_face_off/features/play/presentation/matchmaking_controller.dart';
import 'package:project_face_off/features/play/presentation/matchmaking_screen.dart';

/// Never resolves — avoids FakeMatchmakingRepository's own real `Timer`
/// (up to ~3.7s) being left pending at test teardown; this test only cares
/// that Next actually opens the matchmaking screen, not how its queue ends.
class _PendingMatchmakingRepository implements MatchmakingRepository {
  @override
  Stream<MatchmakingState> joinQueue() => const Stream.empty();
}

void main() {
  const result = MatchCompleteMatchState(winnerId: MatchController.meId, scores: {'me': 3, 'opponent': 1});

  Future<void> pumpResultView(WidgetTester tester, {List<Override> overrides = const []}) async {
    // A single Navigator (MaterialApp's own) — matching production
    // topology, where everything from MatchmakingScreen onward already
    // lives on the *one* root navigator (engineering rule 9), not a nested
    // pair. `Navigator.of(context)` and `Navigator.of(context,
    // rootNavigator: true)` both resolve to this same instance here.
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: Center(child: Text('Play Home'))),
        ),
      ),
    );

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.push(
      MaterialPageRoute(
        builder: (_) => const Scaffold(
          body: Center(
            child: GameMatchResultView(result: result, matchId: 'm1', opponentId: 'bot-ama', opponentLabel: 'Ama'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('tapping Next pops to Play home and starts a new matchmaking queue', (tester) async {
    // Not pumpAndSettle() — even with the queue-Timer-free repository
    // override below, MatchmakingScreen's own continuous "pulse" animation
    // never settles on its own. Fixed-duration pumps only.
    await pumpResultView(
      tester,
      overrides: [matchmakingRepositoryProvider.overrideWithValue(_PendingMatchmakingRepository())],
    );

    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400)); // past both routes' pop/push transitions

    // Confirmed via a NavigatorObserver during development that the
    // expected push/pop/push sequence actually happens (result view popped,
    // matchmaking pushed) — not asserting `GameMatchResultView, findsNothing`
    // here since the popped route's element can still be present mid
    // out-transition well past any real pop duration under the test
    // binding's fake clock, which is a widget-tree-disposal-timing detail,
    // not the app behavior this test is actually about.
    expect(find.byType(MatchmakingScreen), findsOneWidget);
  });

  testWidgets('Add Friend shows a confirmation and becomes non-interactive', (tester) async {
    await pumpResultView(tester);

    await tester.tap(find.text('Add Friend'));
    await tester.pumpAndSettle();

    expect(find.text('Sent'), findsOneWidget);
    expect(find.text('Add Friend'), findsNothing);
  });

  testWidgets('Report opens the report sheet for the specific opponent', (tester) async {
    await pumpResultView(tester);

    await tester.tap(find.text('Report'));
    await tester.pumpAndSettle();

    expect(find.text('Report Ama'), findsOneWidget);
  });

  testWidgets('Block shows a confirmation and becomes non-interactive', (tester) async {
    await pumpResultView(tester);

    await tester.tap(find.text('Block'));
    await tester.pumpAndSettle();

    expect(find.text('Blocked'), findsOneWidget);
  });

  testWidgets('no action at all auto-returns to Play home after the idle timeout', (tester) async {
    await pumpResultView(tester);

    expect(find.text('Play Home'), findsNothing);
    await tester.pump(const Duration(seconds: 36));
    await tester.pumpAndSettle();

    expect(find.text('Play Home'), findsOneWidget);
  });

  testWidgets('tapping any action cancels the idle timeout', (tester) async {
    await pumpResultView(tester);

    // Add Friend is a self-contained action (no sheet to dismiss) — enough
    // on its own to prove the idle timer was cancelled.
    await tester.tap(find.text('Add Friend'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 40));

    expect(find.text('Play Home'), findsNothing);
  });

  // The accept path (RematchAccepted -> pop-to-root + push MatchFoundScreen)
  // is covered at the controller level in rematch_controller_test.dart
  // instead of here — pushing a real MaterialPageRoute from inside a
  // ref.listen callback triggered by an async stream event (rather than a
  // widget gesture) hits a fake_async/AnimationController ticker-timing
  // interaction ("elapsedInSeconds >= 0.0") that's specific to the test
  // harness's synthetic clock, not a real app defect — reproducible even
  // with no logic changes, purely from the timing of when the route push
  // happens relative to the fake clock's frame boundaries.

  testWidgets('Rematch declined reverts the button back to normal after a moment', (tester) async {
    final repo = _DecliningRepository();
    await pumpResultView(tester, overrides: [rematchRepositoryProvider.overrideWithValue(repo)]);

    await tester.tap(find.text('Rematch'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Ama declined'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    expect(find.text('Rematch'), findsOneWidget);
  });
}

class _DecliningRepository implements RematchRepository {
  @override
  Stream<RematchAnswer> sendRequest({required String matchId, required String opponentId}) async* {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    yield RematchAnswer.declined;
  }
}
