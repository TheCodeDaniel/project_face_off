import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/gradient_scaffold.dart';
import '../../../core/widgets/primary_pill_button.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../auth/presentation/sign_in_buttons.dart';
import 'onboarding_providers.dart';
import 'widgets/onboarding_illustration.dart';
import 'widgets/onboarding_page_indicator.dart';

/// First-launch welcome sequence (master prompt Section 6): 2-4 screens
/// introducing the core promise with no technical detail, ending on sign-in.
/// [authStateProvider] transitioning to a non-null user is what actually
/// navigates away from this screen — see `main.dart`'s `AppRoot`.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _pages = [
    (
      icon: HugeIcons.strokeRoundedFaceId,
      title: 'Your face is the controller',
      subtitle: 'No buttons, no joysticks — just your expressions.',
    ),
    (
      icon: HugeIcons.strokeRoundedBoxingGlove01,
      title: 'Face off, head to head',
      subtitle: 'Duel a friend live. First to crack, blink, or fumble loses the round.',
    ),
  ];

  final _controller = PageController();
  int _index = 0;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _signIn(Future<Object> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      await ref.read(onboardingRepositoryProvider).markOnboardingSeen();
    } catch (_) {
      if (mounted) setState(() => _error = "Couldn't sign in — please try again.");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = _pages.length + 1;
    final onLastPage = _index == _pages.length;

    return GradientScaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _index = i),
                children: [
                  for (final page in _pages) _IntroPage(icon: page.icon, title: page.title, subtitle: page.subtitle),
                  _SignInPage(busy: _busy, error: _error, onSignIn: _signIn),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  OnboardingPageIndicator(count: totalPages, index: _index),
                  const SizedBox(height: 20),
                  if (!onLastPage)
                    PrimaryPillButton(
                      label: 'Continue',
                      icon: HugeIcons.strokeRoundedArrowRight01,
                      onPressed: () =>
                          _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  const _IntroPage({required this.icon, required this.title, required this.subtitle});

  final List<List<dynamic>> icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OnboardingIllustration(icon: icon),
          const SizedBox(height: 40),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.display.copyWith(color: Colors.white, fontSize: 28),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _SignInPage extends ConsumerWidget {
  const _SignInPage({required this.busy, required this.error, required this.onSignIn});

  final bool busy;
  final String? error;
  final Future<void> Function(Future<Object> Function()) onSignIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(authRepositoryProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const OnboardingIllustration(icon: HugeIcons.strokeRoundedFlash),
          const SizedBox(height: 40),
          Text(
            'Ready to face off?',
            textAlign: TextAlign.center,
            style: AppTextStyles.display.copyWith(color: Colors.white, fontSize: 28),
          ),
          const SizedBox(height: 24),
          SignInButtons(
            busy: busy,
            onGoogleTap: () => onSignIn(repo.signInWithGoogle),
            onAppleTap: () => onSignIn(repo.signInWithApple),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(error!, style: AppTextStyles.label.copyWith(color: Colors.white)),
          ],
        ],
      ),
    );
  }
}
