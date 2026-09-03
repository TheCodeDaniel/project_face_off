import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';
import '../theme/lobby_palette.dart';
import 'app_icon.dart';
import 'shimmer_card.dart';

/// One tile in the 4-grid Profile stat pattern (Blueprint Section 1, quiz-app
/// reference). Demo:
/// ```dart
/// GridView.count(crossAxisCount: 2, children: [
///   StatTile(label: 'Win streak', value: '5', icon: HugeIcons.strokeRoundedFire),
///   StatTile(label: 'Matches', value: '128'),
/// ])
/// ```
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value, this.icon});

  final String label;
  final String value;

  /// A `HugeIcons.strokeRounded*` constant, e.g. `HugeIcons.strokeRoundedFire`.
  final List<List<dynamic>>? icon;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<LobbyPalette>() ?? LobbyPalette.standard;
    return ShimmerCard(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4))],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) AppIcon(icon!, color: palette.gradientMid, size: 22),
          if (icon != null) const SizedBox(height: 8),
          Text(value, style: AppTextStyles.numericLarge.copyWith(color: Colors.black87, fontSize: 26)),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.label.copyWith(color: Colors.black54),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
