import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_face_off/core/connectivity/connectivity_gate.dart';
import 'package:project_face_off/core/connectivity/connectivity_providers.dart';
import 'package:project_face_off/core/connectivity/fake_connectivity_service.dart';
import 'package:project_face_off/core/theme/app_theme.dart';

void main() {
  testWidgets('shows the offline sheet when connectivity is lost, dismisses it on reconnect', (tester) async {
    final connectivity = FakeConnectivityService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [connectivityServiceProvider.overrideWithValue(connectivity)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ConnectivityGate(child: Scaffold(body: Text('App content'))),
        ),
      ),
    );
    await tester.pump();

    expect(find.text("You're offline"), findsNothing);

    connectivity.setOnline(false);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text("You're offline"), findsOneWidget);

    connectivity.setOnline(true);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text("You're offline"), findsNothing);
    expect(find.text('App content'), findsOneWidget);
  });
}
