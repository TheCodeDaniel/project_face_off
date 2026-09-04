import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_icon.dart';

/// The exactly-two sign-in options (master prompt Section 6) — no email/
/// password, no guest mode for v1. iOS shows Apple first per platform
/// convention; Android shows Google first.
class SignInButtons extends StatelessWidget {
  const SignInButtons({super.key, required this.onGoogleTap, required this.onAppleTap, this.busy = false});

  final VoidCallback onGoogleTap;
  final VoidCallback onAppleTap;
  final bool busy;

  bool get _appleFirst => !kIsWeb && Platform.isIOS;

  @override
  Widget build(BuildContext context) {
    final google = _SignInButton(
      label: 'Continue with Google',
      icon: HugeIcons.strokeRoundedGoogle,
      onTap: busy ? null : onGoogleTap,
    );
    final apple = _SignInButton(
      label: 'Continue with Apple',
      icon: HugeIcons.strokeRoundedApple,
      onTap: busy ? null : onAppleTap,
    );

    final ordered = _appleFirst ? [apple, google] : [google, apple];
    return Column(
      children: [
        for (var i = 0; i < ordered.length; i++) ...[if (i != 0) const SizedBox(height: 12), ordered[i]],
      ],
    );
  }
}

class _SignInButton extends StatelessWidget {
  const _SignInButton({required this.label, required this.icon, required this.onTap});

  final String label;
  final List<List<dynamic>> icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          shape: const StadiumBorder(),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon(icon, color: Colors.black87, size: 20),
            const SizedBox(width: 10),
            Text(label, style: AppTextStyles.label.copyWith(color: Colors.black87, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
