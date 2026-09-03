import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_face_off/core/theme/app_theme.dart';
import 'package:project_face_off/features/duel/presentation/duel_screen.dart';

void main() {
  Future<void> pumpDuelScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: Navigator(
            onGenerateRoute: (settings) => MaterialPageRoute(builder: (_) => const DuelScreen(opponentName: 'Bot')),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('attempting to leave mid-round shows the quit confirmation, not an immediate exit', (tester) async {
    await pumpDuelScreen(tester);

    final navigatorState = tester.state<NavigatorState>(find.byType(Navigator).last);
    unawaited(navigatorState.maybePop());
    await tester.pumpAndSettle();

    expect(find.text('Quit the match?'), findsOneWidget);
    expect(find.byType(DuelScreen), findsOneWidget);
  });

  testWidgets('"Keep Playing" dismisses the dialog and stays on the duel screen', (tester) async {
    await pumpDuelScreen(tester);

    final navigatorState = tester.state<NavigatorState>(find.byType(Navigator).last);
    unawaited(navigatorState.maybePop());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Keep Playing'));
    await tester.pumpAndSettle();

    expect(find.text('Quit the match?'), findsNothing);
    expect(find.byType(DuelScreen), findsOneWidget);
  });

  testWidgets('"Quit Match" actually leaves the screen', (tester) async {
    await pumpDuelScreen(tester);

    final navigatorState = tester.state<NavigatorState>(find.byType(Navigator).last);
    unawaited(navigatorState.maybePop());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Quit Match'));
    await tester.pumpAndSettle();

    expect(find.byType(DuelScreen), findsNothing);
  });
}
