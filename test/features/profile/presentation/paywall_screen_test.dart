import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_face_off/core/theme/app_theme.dart';
import 'package:project_face_off/features/profile/presentation/paywall_screen.dart';

void main() {
  Future<void> pumpPaywall(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.light, home: const PaywallScreen()),
      ),
    );
    await tester.pump(); // let fetchOfferings' delay resolve
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('shows the package picker once offerings load, with a default selection', (tester) async {
    await pumpPaywall(tester);

    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text('Annual'), findsOneWidget);
    // The badged (annual) package is selected by default.
    expect(find.textContaining('Subscribe — \$39.99/yr'), findsOneWidget);
  });

  testWidgets('selecting the monthly plan updates the subscribe button price', (tester) async {
    await pumpPaywall(tester);

    await tester.tap(find.text('Monthly'));
    await tester.pump();

    expect(find.textContaining('Subscribe — \$4.99/mo'), findsOneWidget);
  });

  testWidgets('tapping subscribe shows a success confirmation, then closes the paywall', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: Navigator(onGenerateRoute: (settings) => MaterialPageRoute(builder: (_) => const PaywallScreen())),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.textContaining('Subscribe —'));
    await tester.pump(); // purchasing state
    await tester.pump(const Duration(milliseconds: 900)); // purchase resolves
    await tester.pump(const Duration(milliseconds: 250)); // AnimatedSwitcher crossfade

    expect(find.text("You're on Face Off Plus!"), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1400)); // auto-close timer
    await tester.pumpAndSettle();

    expect(find.byType(PaywallScreen), findsNothing);
  });
}
