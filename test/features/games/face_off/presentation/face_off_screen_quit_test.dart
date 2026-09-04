import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_face_off/core/theme/app_theme.dart';
import 'package:project_face_off/features/games/face_off/presentation/face_off_screen.dart';

void main() {
  Future<void> pumpFaceOffScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: Navigator(
            onGenerateRoute: (settings) => MaterialPageRoute(
              builder: (_) => const FaceOffScreen(matchId: 'm1', opponentId: 'bot-1', opponentName: 'Bot'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('attempting to leave mid-round shows the quit confirmation, not an immediate exit', (tester) async {
    await pumpFaceOffScreen(tester);

    final navigatorState = tester.state<NavigatorState>(find.byType(Navigator).last);
    unawaited(navigatorState.maybePop());
    await tester.pumpAndSettle();

    expect(find.text('Quit the match?'), findsOneWidget);
    expect(find.byType(FaceOffScreen), findsOneWidget);
  });

  testWidgets('"Keep Playing" dismisses the dialog and stays on the match screen', (tester) async {
    await pumpFaceOffScreen(tester);

    final navigatorState = tester.state<NavigatorState>(find.byType(Navigator).last);
    unawaited(navigatorState.maybePop());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Keep Playing'));
    await tester.pumpAndSettle();

    expect(find.text('Quit the match?'), findsNothing);
    expect(find.byType(FaceOffScreen), findsOneWidget);
  });

  testWidgets('"Quit Match" actually leaves the screen', (tester) async {
    await pumpFaceOffScreen(tester);

    final navigatorState = tester.state<NavigatorState>(find.byType(Navigator).last);
    unawaited(navigatorState.maybePop());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Quit Match'));
    await tester.pumpAndSettle();

    expect(find.byType(FaceOffScreen), findsNothing);
  });

  testWidgets('the header exit button triggers the same quit confirmation as the system back gesture', (tester) async {
    // iOS has no system back button and the edge-swipe gesture isn't an
    // obvious affordance mid-match, so MatchHeader carries an explicit
    // exit control — this confirms it actually routes through the same
    // confirm-before-leaving flow rather than popping silently.
    await pumpFaceOffScreen(tester);

    await tester.tap(find.byKey(const Key('duelExitButton')));
    await tester.pumpAndSettle();

    expect(find.text('Quit the match?'), findsOneWidget);
    expect(find.byType(FaceOffScreen), findsOneWidget);

    await tester.tap(find.text('Quit Match'));
    await tester.pumpAndSettle();

    expect(find.byType(FaceOffScreen), findsNothing);
  });
}
