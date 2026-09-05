import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/game_engine/game_pool.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/lobby_palette.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../domain/game_stats.dart';

/// Per-game stats breakdown, reachable by tapping the aggregate stat grid
/// (multi-game plan Section 4.2) — deliberately a bottom sheet, not a new
/// top-level screen, per the plan's "keep this simple" instruction.
class PerGameStatsSheet extends StatelessWidget {
  const PerGameStatsSheet({super.key, required this.perGameStats});

  final Map<GameId, GameStats> perGameStats;

  static Future<void> show(BuildContext context, Map<GameId, GameStats> perGameStats) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PerGameStatsSheet(perGameStats: perGameStats),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<LobbyPalette>() ?? LobbyPalette.standard;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('Stats by game', style: AppTextStyles.headline.copyWith(color: Colors.black87)),
              ),
              const SizedBox(height: 8),
              for (final definition in gamePool)
                _GameStatsRow(label: definition.displayName, stats: perGameStats[definition.id]),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameStatsRow extends StatelessWidget {
  const _GameStatsRow({required this.label, required this.stats});

  final String label;
  final GameStats? stats;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const AppIcon(HugeIcons.strokeRoundedBoxingGlove01, color: Colors.black54, size: 20),
      title: Text(label, style: AppTextStyles.body.copyWith(color: Colors.black87)),
      subtitle: stats == null
          ? Text('No matches yet', style: AppTextStyles.label.copyWith(color: Colors.black45))
          : Text(
              '${stats!.totalMatches} matches · ${stats!.winRatePercent}% win rate · ${stats!.winStreak} streak',
              style: AppTextStyles.label.copyWith(color: Colors.black45),
            ),
    );
  }
}
