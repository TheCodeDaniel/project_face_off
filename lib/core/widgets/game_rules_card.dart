import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../game_engine/game_pool.dart';
import '../theme/app_text_styles.dart';
import '../theme/match_palette.dart';
import 'app_icon.dart';

/// Brief pre-round rules card for whichever game was picked for this match
/// (multi-game plan Section 4.6): "let each individual match's own pre-round
/// moment carry that specific game's quick rules," shown right after
/// matchmaking confirms, before [DuelVsTransition] plays — deliberately not
/// part of onboarding, which would mean teaching all three games' rules
/// before a player has played once.
class GameRulesCard extends StatelessWidget {
  const GameRulesCard({super.key, required this.gameId});

  final GameId gameId;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<MatchPalette>() ?? MatchPalette.standard;
    final definition = gameDefinitionFor(gameId);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(HugeIcons.strokeRoundedDiceFaces01, color: palette.neonViolet, size: 56),
          const SizedBox(height: 16),
          Text("Today's game:", style: AppTextStyles.label.copyWith(color: Colors.white54)),
          const SizedBox(height: 4),
          Text(definition.displayName, style: AppTextStyles.display.copyWith(color: Colors.white, fontSize: 30)),
          const SizedBox(height: 12),
          Text(
            definition.quickRules,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
