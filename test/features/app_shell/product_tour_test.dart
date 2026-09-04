import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_face_off/core/theme/app_theme.dart';
import 'package:project_face_off/features/app_shell/presentation/app_shell_screen.dart';
import 'package:project_face_off/features/friends/presentation/friends_screen.dart';
import 'package:project_face_off/features/play/presentation/play_screen.dart';
import 'package:project_face_off/features/profile/presentation/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('the post-sign-in tour plays through all three steps and marks itself seen', (tester) async {
    // Regression coverage for the showcaseview 3.0.0 -> 5.1.0 migration: the
    // old ShowCaseWidget-based trigger (re-registered on every rebuild) was
    // reported to flash the tour for a frame and then silently fail. This
    // steps through the whole sequence to prove it now starts and survives.
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: AppShellScreen(
            tabs: [(_) => const PlayScreen(), (_) => const FriendsScreen(), (_) => const ProfileScreen()],
          ),
        ),
      ),
    );
    // Not pumpAndSettle from here on: showcaseview runs a continuous
    // highlight animation once a step is showing, which never settles (same
    // reason app_root_test.dart avoids it for this same tour) — a handful of
    // fixed-duration pumps instead, covering the post-frame callback ->
    // await hasSeenTour() -> startShowCase() gap on first appearance, and
    // each step's scroll-into-view + slide/scale transition after that.
    Future<void> settleStep() async {
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(const Duration(milliseconds: 600));
    }

    await settleStep();

    expect(find.text('Jump into a random duel the moment you\'re ready.'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await settleStep();

    expect(find.text('Tap here to head to Friends.'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await settleStep();

    expect(find.text('Tap here to head to Profile.'), findsOneWidget);
    // Last step: "Skip" hides itself, "Next" becomes "Got it".
    expect(find.text('Skip'), findsNothing);
    expect(find.text('Got it'), findsOneWidget);

    await tester.tap(find.text('Got it'));
    await settleStep();

    expect(find.text('Tap here to head to Profile.'), findsNothing);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('onboarding_tour_seen'), isTrue);
  });
}
