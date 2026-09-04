import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/lobby_palette.dart';
import '../../../../core/widgets/app_icon.dart';

/// Paywall's post-purchase confirmation — swapped in via `AnimatedSwitcher`
/// in place of the package picker, then the screen auto-closes shortly
/// after (see `PaywallScreen._purchase`). Same crossfade-confirmation
/// language as `AddFriendSheet`'s success state.
class PurchaseSuccessView extends StatelessWidget {
  const PurchaseSuccessView({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<LobbyPalette>() ?? LobbyPalette.standard;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.coinGold.withValues(alpha: 0.22),
                border: Border.all(color: palette.coinGold, width: 1.6),
              ),
              alignment: Alignment.center,
              child: AppIcon(HugeIcons.strokeRoundedCheckmarkCircle02, color: palette.coinGold, size: 42),
            ),
            const SizedBox(height: 20),
            Text(
              "You're on Face Off Plus!",
              textAlign: TextAlign.center,
              style: AppTextStyles.headline.copyWith(color: Colors.white, fontSize: 22),
            ),
            const SizedBox(height: 6),
            Text(
              'Enjoy the full experience.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
