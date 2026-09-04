import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';
import '../theme/lobby_palette.dart';
import 'app_icon.dart';

/// The two CTA button styles (Blueprint Section 3). Demo:
/// ```dart
/// PrimaryPillButton(label: 'Quick Match', icon: HugeIcons.strokeRoundedZap, onPressed: () {})
/// SecondaryPillButton(label: 'How to Play', icon: HugeIcons.strokeRoundedHelpCircle, onPressed: () {})
/// ```
class PrimaryPillButton extends StatelessWidget {
  const PrimaryPillButton({super.key, required this.label, required this.onPressed, this.icon, this.loading = false});

  final String label;
  final VoidCallback? onPressed;
  final List<List<dynamic>>? icon;

  /// Shows a spinner in place of the icon/label and disables tap — for an
  /// async action (e.g. a purchase) the button itself triggers, per the
  /// paywall's purchase flow.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<LobbyPalette>() ?? LobbyPalette.standard;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.gradientMid,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          elevation: 4,
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[AppIcon(icon!, color: Colors.white, size: 20), const SizedBox(width: 8)],
                  Text(label, style: AppTextStyles.headline.copyWith(color: Colors.white, fontSize: 18)),
                ],
              ),
      ),
    );
  }
}

/// Frosted-glass secondary CTA. Deliberately **not** styled with
/// `LobbyPalette.gradientStart` as an outline — a deep-violet border on the
/// violet→magenta→orange background it's almost always placed on has too
/// little contrast (this was the "barely visible How to Play button" fix).
/// A translucent white pill reads clearly at any point on the gradient and
/// doubles as the glass motif used by [FloatingNavBar].
class SecondaryPillButton extends StatelessWidget {
  const SecondaryPillButton({super.key, required this.label, required this.onPressed, this.icon});

  final String label;
  final VoidCallback? onPressed;
  final List<List<dynamic>>? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 1.4),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onPressed,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[AppIcon(icon!, color: Colors.white, size: 18), const SizedBox(width: 8)],
                Text(label, style: AppTextStyles.label.copyWith(color: Colors.white, fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
