import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../../core/game_engine/match_controller.dart';
import '../../../../../core/game_engine/match_state.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/match_palette.dart';
import '../../../../../core/widgets/app_icon.dart';
import '../../../../../core/widgets/primary_pill_button.dart';

/// Final score screen (master prompt Section 8.4 MatchResult phase): winner
/// declaration, rematch / return options. This is also the documented
/// trigger point for the post-match rewarded-ad offer and match-history
/// save (Section 11 / Firestore) — neither is wired up yet, see CLAUDE.md.
class FaceOffMatchResultView extends StatelessWidget {
  const FaceOffMatchResultView({
    super.key,
    required this.result,
    required this.opponentLabel,
    required this.onRematch,
    required this.onExit,
  });

  final MatchCompleteMatchState result;
  final String opponentLabel;
  final VoidCallback onRematch;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<MatchPalette>() ?? MatchPalette.standard;
    final iWon = result.winnerId == MatchController.meId;
    final myScore = result.scores[MatchController.meId] ?? 0;
    final opponentScore = result.scores[MatchController.opponentId] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(
            iWon ? HugeIcons.strokeRoundedCrown : HugeIcons.strokeRoundedSadDizzy,
            color: iWon ? palette.neonCyan : palette.hotRed,
            size: 72,
          ),
          const SizedBox(height: 16),
          Text(
            iWon ? 'You won!' : '$opponentLabel won',
            style: AppTextStyles.display.copyWith(color: Colors.white, fontSize: 32),
          ),
          const SizedBox(height: 8),
          Text(
            '$myScore — $opponentScore',
            style: AppTextStyles.numericLarge.copyWith(color: Colors.white70, fontSize: 24),
          ),
          const SizedBox(height: 32),
          PrimaryPillButton(label: 'Rematch', icon: HugeIcons.strokeRoundedRefresh, onPressed: onRematch),
          const SizedBox(height: 12),
          SecondaryPillButton(label: 'Back to Play', icon: HugeIcons.strokeRoundedArrowLeft01, onPressed: onExit),
        ],
      ),
    );
  }
}
