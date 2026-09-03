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
    // Not pumpAndSettle: the post-sign-in product tour (ShowCaseWidget) runs
    // a continuous highlight animation once triggered, which never settles.
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Face Off'), findsOneWidget);
    expect(find.text('Quick Match'), findsOneWidget);
  });
}
