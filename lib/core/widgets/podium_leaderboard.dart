import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../theme/app_text_styles.dart';
import '../theme/lobby_palette.dart';
import 'app_icon.dart';

class LeaderboardEntry {
  const LeaderboardEntry({required this.name, required this.score, this.avatarUrl});

  final String name;
  final int score;
  final String? avatarUrl;
}

/// 3D-ish podium blocks with a crown on 1st, numbered list for ranks 4+
/// (Blueprint Section 1). Used by Profile → Leaderboard. Demo:
/// ```dart
/// PodiumLeaderboard(entries: [LeaderboardEntry(name: 'Ama', score: 980), ...])
/// ```
class PodiumLeaderboard extends StatelessWidget {
  const PodiumLeaderboard({super.key, required this.entries});

  final List<LeaderboardEntry> entries;

  @override
  Widget build(BuildContext context) {
    final top3 = entries.take(3).toList();
    final rest = entries.skip(3).toList();
    return Column(
      children: [
        if (top3.isNotEmpty) _Podium(top3: top3),
        const SizedBox(height: 16),
        for (var i = 0; i < rest.length; i++) _RankRow(rank: i + 4, entry: rest[i]),
      ],
    );
  }
}

class _Podium extends StatelessWidget {
  const _Podium({required this.top3});

  final List<LeaderboardEntry> top3;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<LobbyPalette>() ?? LobbyPalette.standard;
    LeaderboardEntry? at(int i) => i < top3.length ? top3[i] : null;
    return SizedBox(
      height: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PodiumBlock(entry: at(1), rank: 2, height: 90, color: Colors.grey.shade400),
          const SizedBox(width: 8),
          _PodiumBlock(entry: at(0), rank: 1, height: 130, color: palette.coinGold, crowned: true),
          const SizedBox(width: 8),
          _PodiumBlock(entry: at(2), rank: 3, height: 70, color: const Color(0xFFCD7F32)),
        ],
      ),
    );
  }
}

class _PodiumBlock extends StatelessWidget {
  const _PodiumBlock({
    required this.entry,
    required this.rank,
    required this.height,
    required this.color,
    this.crowned = false,
  });

  final LeaderboardEntry? entry;
  final int rank;
  final double height;
  final Color color;
  final bool crowned;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (crowned) const AppIcon(HugeIcons.strokeRoundedCrown, color: Color(0xFFFFC94A), size: 26),
          CircleAvatar(radius: 22, backgroundColor: Colors.white, child: Text(entry?.name.characters.first ?? '?')),
          const SizedBox(height: 4),
          Text(
            entry?.name ?? '—',
            style: AppTextStyles.label.copyWith(color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text('${entry?.score ?? 0}', style: AppTextStyles.numeric.copyWith(color: Colors.white)),
          const SizedBox(height: 6),
          Container(
            height: height,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(top: 8),
            child: Text('$rank', style: AppTextStyles.headline.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.rank, required this.entry});

  final int rank;
  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<LobbyPalette>() ?? LobbyPalette.standard;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: palette.cardBackground, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Text('$rank', style: AppTextStyles.label.copyWith(color: Colors.black45)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(entry.name, style: AppTextStyles.body.copyWith(color: Colors.black87)),
          ),
          Text('${entry.score}', style: AppTextStyles.numeric.copyWith(color: Colors.black87)),
        ],
      ),
    );
  }
}
