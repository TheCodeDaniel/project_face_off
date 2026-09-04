import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../theme/app_text_styles.dart';
import '../theme/lobby_palette.dart';
import 'app_icon.dart';
import 'shimmer_card.dart';

/// Persistent top-right currency pill (MiMeo reference, Blueprint Section 1).
/// [ShimmerCard] already wraps its own [RepaintBoundary] so the coin count's
/// sheen sweep never repaints the rest of the app bar. Demo:
/// ```dart
/// CoinBadge(coins: 1250)
/// ```
class CoinBadge extends StatelessWidget {
  const CoinBadge({super.key, required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<LobbyPalette>() ?? LobbyPalette.standard;
    return ShimmerCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      borderRadius: BorderRadius.circular(999),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 3))],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(HugeIcons.strokeRoundedCoins01, color: palette.coinGold, size: 18),
          const SizedBox(width: 6),
          Text('$coins', style: AppTextStyles.numeric.copyWith(color: Colors.black87)),
        ],
      ),
    );
  }
}
