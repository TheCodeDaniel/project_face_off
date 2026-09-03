import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_face_off/core/theme/app_theme.dart';
import 'package:project_face_off/features/friends/presentation/friends_screen.dart';

void main() {
  testWidgets('FriendsScreen renders seeded requests and friends without throwing', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.light, home: const FriendsScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Friends'), findsWidgets);
    expect(find.text('Add Friend'), findsOneWidget);
    expect(find.text('Requests'), findsOneWidget);
    expect(find.textContaining('wants to be friends'), findsOneWidget);
  });
}
