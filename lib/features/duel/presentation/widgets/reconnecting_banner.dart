import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/match_palette.dart';
import '../../../../core/widgets/app_icon.dart';

/// Shown while [duelOfflinePauseProvider] is true — the match is paused
/// locally after this device lost connectivity mid-round (master prompt
/// Section 12). Deliberately plain/static rather than animated: this
/// screen already has enough motion, and a paused match is exactly the
/// moment *not* to add more.
class ReconnectingBanner extends StatelessWidget {
  const ReconnectingBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<MatchPalette>() ?? MatchPalette.standard;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: palette.hotRed.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.hotRed.withValues(alpha: 0.4), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(HugeIcons.strokeRoundedWifiOff01, color: palette.hotRed, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "You're offline — match paused. Reconnect before time runs out.",
              style: AppTextStyles.label.copyWith(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
