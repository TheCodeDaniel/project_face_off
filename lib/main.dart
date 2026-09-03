import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/widgets/gradient_scaffold.dart';
import 'features/app_shell/presentation/app_shell_screen.dart';
import 'features/auth/presentation/auth_providers.dart';
import 'features/auth/presentation/sign_in_screen.dart';
import 'features/friends/presentation/friends_screen.dart';
import 'features/onboarding/presentation/onboarding_providers.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';
import 'features/play/presentation/play_screen.dart';
import 'features/profile/presentation/profile_screen.dart';

/// Firebase.initializeApp() and RevenueCat SDK init are intentionally not
/// called here yet — they need `flutterfire configure` output and RevenueCat
/// API keys respectively. See CLAUDE.md "What's stubbed pending your
/// credentials". [authRepositoryProvider] currently resolves to
/// `FakeAuthRepository` — swap the provider override once Firebase exists.
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
      home: const AppRoot(),
    );
  }
}

/// Gates the app shell behind onboarding + auth (master prompt Section 6):
/// signed in -> shell; signed out + never onboarded -> the full welcome
/// sequence ending in sign-in; signed out + already onboarded -> a compact
/// sign-in screen (onboarding never replays after the first session).
class AppRoot extends ConsumerWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => const _SplashScreen(),
      error: (_, _) => const _SplashScreen(),
      data: (user) {
        if (user != null) {
          return const AppShellScreen(tabs: [_playTab, _friendsTab, _profileTab]);
        }
        final hasSeenOnboarding = ref.watch(hasSeenOnboardingProvider);
        return hasSeenOnboarding.when(
          loading: () => const _SplashScreen(),
          error: (_, _) => const OnboardingScreen(),
          data: (seen) => seen ? const SignInScreen() : const OnboardingScreen(),
        );
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const GradientScaffold(
      body: Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}

Widget _playTab(BuildContext context) => const PlayScreen();
Widget _friendsTab(BuildContext context) => const FriendsScreen();
Widget _profileTab(BuildContext context) => const ProfileScreen();
