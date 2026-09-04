import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/widgets/animated_splash_screen.dart';
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
///
/// [AnimatedSplashScreen] holds for at least [_minSplashDuration] regardless
/// of how fast the underlying providers resolve — against the real
/// Firebase-backed auth this is a no-op (auth genuinely takes a moment), but
/// against `FakeAuthRepository`'s near-instant resolution it stops the
/// splash's spiral/title animation from being cut off mid-play on every
/// single launch. `AnimatedSwitcher` crossfades into whichever screen comes
/// next instead of a hard cut.
class AppRoot extends ConsumerStatefulWidget {
  const AppRoot({super.key});

  @override
  ConsumerState<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends ConsumerState<AppRoot> {
  static const _minSplashDuration = Duration(milliseconds: 2400);

  bool _minSplashElapsed = false;

  @override
  void initState() {
    super.initState();
    Timer(_minSplashDuration, () {
      if (mounted) setState(() => _minSplashElapsed = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    Widget child = const AnimatedSplashScreen(key: ValueKey('splash'));
    if (_minSplashElapsed) {
      child = authState.when(
        loading: () => const AnimatedSplashScreen(key: ValueKey('splash')),
        error: (_, _) => const AnimatedSplashScreen(key: ValueKey('splash')),
        data: (user) {
          if (user != null) {
            return const AppShellScreen(key: ValueKey('shell'), tabs: [_playTab, _friendsTab, _profileTab]);
          }
          final hasSeenOnboarding = ref.watch(hasSeenOnboardingProvider);
          return hasSeenOnboarding.when(
            loading: () => const AnimatedSplashScreen(key: ValueKey('splash')),
            error: (_, _) => const OnboardingScreen(key: ValueKey('onboarding')),
            data: (seen) => seen
                ? const SignInScreen(key: ValueKey('signIn'))
                : const OnboardingScreen(key: ValueKey('onboarding')),
          );
        },
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      // Default layoutBuilder wraps children as plain (non-Positioned)
      // Stack children, which get *loose* constraints — every screen swapped
      // through here would size itself to its own content instead of
      // filling the device (most visible on the splash: its content shrunk
      // to a fraction of the screen width, black everywhere else). Wrapping
      // each child in Positioned.fill gives it the Stack's actual size
      // instead.
      //
      // Each Positioned.fill MUST carry the wrapped child's own key. Without
      // one, Stack's children list is reconciled *positionally*: mid-fade
      // the list is [previous, current] (2 items), and once the fade
      // finishes and `previous` drops out it becomes just [current] (1
      // item) — at index 0 that's a widget swap (was `previous`, now
      // `current`) with no key to prove they're unrelated, so Flutter
      // updates the old element in place, finds the *inner* child's key
      // doesn't match, and tears the whole subtree down and rebuilds it
      // fresh instead of reusing the element already mounted at index 1.
      // For AppShellScreen that meant initState() (and everything it
      // kicks off, like the product tour) ran a second time within a
      // frame or two of the first — the real cause of the tour visibly
      // starting and then immediately vanishing on every single launch,
      // confirmed by instrumenting AppShellScreen and seeing its tour
      // -trigger method run twice on one launch.
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.center,
          children: [
            for (final previous in previousChildren) Positioned.fill(key: previous.key, child: previous),
            if (currentChild != null) Positioned.fill(key: currentChild.key, child: currentChild),
          ],
        );
      },
      child: child,
    );
  }
}

Widget _playTab(BuildContext context) => const PlayScreen();
Widget _friendsTab(BuildContext context) => const FriendsScreen();
Widget _profileTab(BuildContext context) => const ProfileScreen();
