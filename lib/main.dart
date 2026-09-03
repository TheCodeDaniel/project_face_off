import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/app_shell/presentation/app_shell_screen.dart';
import 'features/friends/presentation/friends_screen.dart';
import 'features/play/presentation/play_screen.dart';
import 'features/profile/presentation/profile_screen.dart';

/// Firebase.initializeApp() and RevenueCat SDK init are intentionally not
/// called here yet — they need `flutterfire configure` output and RevenueCat
/// API keys respectively. See CLAUDE.md "What's stubbed pending your
/// credentials". Auth/onboarding (master prompt Section 6) will gate this
/// shell behind sign-in once wired.
void main() {
  runApp(const ProviderScope(child: FaceOffApp()));
}

class FaceOffApp extends StatelessWidget {
  const FaceOffApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Face Off',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AppShellScreen(tabs: [_playTab, _friendsTab, _profileTab]),
    );
  }
}

Widget _playTab(BuildContext context) => const PlayScreen();
Widget _friendsTab(BuildContext context) => const FriendsScreen();
Widget _profileTab(BuildContext context) => const ProfileScreen();
