import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_face_off/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows onboarding for a first-time signed-out user, then the shell after sign-in', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: AppRoot())));
    await tester.pumpAndSettle();

    expect(find.text('Your face is the controller'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue with Google'));
    // Not pumpAndSettle: the post-sign-in product tour runs a continuous
    // highlight animation once triggered, which never settles. Pump well
    // past both AppRoot's ~400ms splash->shell crossfade *and* the tour's
    // up-to-1s isTargetRendered poll (see AppShellScreen), so this
    // genuinely exercises the window where a real regression showed up:
    // AnimatedSwitcher's layoutBuilder reconciling the Stack's children by
    // position once the crossfade's "previous" entry drops out, which used
    // to silently tear down and recreate AppShellScreen's whole State —
    // orphaning the ShowcaseView registration the tour had already started
    // on mid-fade, and killing the tour a frame or two after it appeared.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 400));
    }

    expect(find.text('Face Off'), findsOneWidget);
    // Exactly 2, not findsWidgets: the button's own label plus the tour's
    // first Showcase step (title "Quick Match" too). findsWidgets would
    // pass even with just the button's label alone — i.e. even if the tour
    // had already vanished — so it doesn't actually prove the tour is
    // still showing. Asserting the exact count does.
    expect(find.text('Quick Match'), findsNWidgets(2));
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });
}
