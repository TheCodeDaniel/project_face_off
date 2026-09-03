import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_face_off/core/theme/app_theme.dart';
import 'package:project_face_off/features/app_shell/presentation/app_shell_screen.dart';

void main() {
  testWidgets('AppShellScreen renders all three tabs without throwing', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: AppShellScreen(
            tabs: [
              (_) => const Text('Play tab content'),
              (_) => const Text('Friends tab content'),
              (_) => const Text('Profile tab content'),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Play tab content'), findsOneWidget);
  });
}
