import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/gradient_scaffold.dart';
import 'auth_providers.dart';
import 'sign_in_buttons.dart';

/// Shown to a returning user who has already seen the full onboarding
/// sequence but is currently signed out — a compact sign-in prompt rather
/// than replaying [OnboardingScreen] (master prompt Section 6: onboarding
/// never replays after the first session).
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _signIn(Future<Object> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (_) {
      if (mounted) setState(() => _error = "Couldn't sign in — please try again.");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(authRepositoryProvider);
    return GradientScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppIcon(HugeIcons.strokeRoundedBoxingGlove01, color: Colors.white, size: 64),
              const SizedBox(height: 16),
              Text('Face Off', style: AppTextStyles.display.copyWith(color: Colors.white)),
              const SizedBox(height: 32),
              SignInButtons(
                busy: _busy,
                onGoogleTap: () => _signIn(repo.signInWithGoogle),
                onAppleTap: () => _signIn(repo.signInWithApple),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: AppTextStyles.label.copyWith(color: Colors.white)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
