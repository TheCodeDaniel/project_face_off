import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';
import '../theme/lobby_palette.dart';

/// The two CTA button styles (Blueprint Section 3). Demo:
/// ```dart
/// PrimaryPillButton(label: 'Quick Match', onPressed: () {})
/// SecondaryPillButton(label: 'How to Play', onPressed: () {})
/// ```
class PrimaryPillButton extends StatelessWidget {
  const PrimaryPillButton({super.key, required this.label, required this.onPressed, this.icon});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<LobbyPalette>() ?? LobbyPalette.standard;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.gradientMid,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          elevation: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon), const SizedBox(width: 8)],
            Text(label, style: AppTextStyles.headline.copyWith(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class SecondaryPillButton extends StatelessWidget {
  const SecondaryPillButton({super.key, required this.label, required this.onPressed, this.icon});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<LobbyPalette>() ?? LobbyPalette.standard;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.gradientStart,
          side: BorderSide(color: palette.gradientStart, width: 1.5),
          shape: const StadiumBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
            Text(label, style: AppTextStyles.label.copyWith(color: palette.gradientStart)),
          ],
        ),
      ),
    );
  }
}
