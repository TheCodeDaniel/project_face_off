import 'package:flutter/material.dart';

import '../../../../core/widgets/app_icon.dart';

/// Per-page onboarding illustration. Master prompt Section 6 calls for a
/// "high-polish Lottie-driven" sequence; no Lottie asset files exist yet (no
/// design assets were provided — see CLAUDE.md), so this renders an animated
/// icon-on-glass illustration instead. It's the single drop-in point: once a
/// real `assets/lottie/<name>.json` exists, swap this widget's body for a
/// `Lottie.asset(...)` without touching [OnboardingScreen].
class OnboardingIllustration extends StatefulWidget {
  const OnboardingIllustration({super.key, required this.icon});

  final List<List<dynamic>> icon;

  @override
  State<OnboardingIllustration> createState() => _OnboardingIllustrationState();
}

class _OnboardingIllustrationState extends State<OnboardingIllustration> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    return ScaleTransition(
      scale: scale,
      child: Container(
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.4),
        ),
        alignment: Alignment.center,
        child: AppIcon(widget.icon, color: Colors.white, size: 84),
      ),
    );
  }
}
