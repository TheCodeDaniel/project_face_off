import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/match_palette.dart';
import '../../../../core/widgets/collapsible_panel.dart';

/// In-match score panel (Blueprint Section 1, voxel mini-golf collapsible
/// scorecard pattern — reused via [CollapsiblePanel] from Section 4).
class DuelScoreboardPanel extends StatelessWidget {
  const DuelScoreboardPanel({
    super.key,
    required this.myScore,
    required this.opponentScore,
    required this.opponentLabel,
  });

  final int myScore;
  final int opponentScore;
  final String opponentLabel;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<MatchPalette>() ?? MatchPalette.standard;
    return CollapsiblePanel(
      title: 'Scorecard',
      backgroundColor: Colors.black.withValues(alpha: 0.4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ScoreEntry(label: 'You', score: myScore, color: palette.neonCyan),
          Text('vs', style: AppTextStyles.label.copyWith(color: Colors.white54)),
          _ScoreEntry(label: opponentLabel, score: opponentScore, color: palette.hotRed),
        ],
      ),
    );
  }
}

class _ScoreEntry extends StatelessWidget {
  const _ScoreEntry({required this.label, required this.score, required this.color});

  final String label;
  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.label.copyWith(color: Colors.white70)),
        Text('$score', style: AppTextStyles.numericLarge.copyWith(color: color, fontSize: 28)),
      ],
    );
  }
}
