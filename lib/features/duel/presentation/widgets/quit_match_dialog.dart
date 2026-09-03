import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/match_palette.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/primary_pill_button.dart';

/// Confirmation shown when the player tries to leave [DuelScreen] mid-round
/// (system back gesture/button, or any other pop) — leaving mid-match
/// forfeits it, so this guards against losing a live duel to an accidental
/// swipe-back. Not shown once the match has already ended; see
/// `DuelScreen`'s `PopScope`.
class QuitMatchDialog extends StatelessWidget {
  const QuitMatchDialog({super.key});

  /// Returns true if the player confirmed they want to quit.
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => const QuitMatchDialog(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<MatchPalette>() ?? MatchPalette.standard;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        decoration: BoxDecoration(
          gradient: palette.backgroundGradient,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(HugeIcons.strokeRoundedAlertCircle, color: palette.hotRed, size: 40),
            const SizedBox(height: 16),
            Text('Quit the match?', style: AppTextStyles.headline.copyWith(color: Colors.white)),
            const SizedBox(height: 8),
            Text(
              "You'll forfeit this duel if you leave now.",
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            PrimaryPillButton(
              label: 'Keep Playing',
              icon: HugeIcons.strokeRoundedBoxingGlove01,
              onPressed: () => Navigator.of(context).pop(false),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Quit Match', style: AppTextStyles.label.copyWith(color: palette.hotRed)),
            ),
          ],
        ),
      ),
    );
  }
}
