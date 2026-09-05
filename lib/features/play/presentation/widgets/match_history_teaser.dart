import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/game_engine/game_pool.dart';
import '../../../../core/game_engine/match_controller.dart';
import '../../../../core/game_engine/match_result_record.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_icon.dart';

final _recentMatchesProvider = StreamProvider.autoDispose<List<MatchResultRecord>>((ref) {
  return ref.watch(matchRepositoryProvider).watchRecentMatches();
});

/// Last-3-results teaser on the Play tab (master prompt Section 7); full
/// history lives in Profile. Backed by `MatchRepository` (game/UI/backend
/// guideline Section 3) — `FakeMatchRepository` today, in-memory for the
/// session's lifetime, until a real Supabase project exists.
class MatchHistoryTeaser extends ConsumerWidget {
  const MatchHistoryTeaser({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(_recentMatchesProvider).valueOrNull ?? const [];

    if (matches.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const AppIcon(HugeIcons.strokeRoundedClock01, color: Colors.white70, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No matches yet — play your first duel to see your recent results here.',
                style: AppTextStyles.body.copyWith(color: Colors.white70),
              ),
            ),
          ],
        ),
      );
    }

    return Column(children: matches.take(3).map((match) => _MatchHistoryRow(match: match)).toList(growable: false));
  }
}

class _MatchHistoryRow extends StatelessWidget {
  const _MatchHistoryRow({required this.match});

  final MatchResultRecord match;

  @override
  Widget build(BuildContext context) {
    final won = match.iWon;
    final resultColor = won == null ? Colors.white70 : (won ? const Color(0xFF4CD9E8) : const Color(0xFFFF4D6D));
    final resultLabel = won == null ? 'Draw' : (won ? 'Won' : 'Lost');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          AppIcon(HugeIcons.strokeRoundedGameController01, color: resultColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gameDefinitionFor(match.gameId).displayName,
                  style: AppTextStyles.label.copyWith(color: Colors.white),
                ),
                Text(
                  'vs ${match.opponentLabel}',
                  style: AppTextStyles.body.copyWith(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${match.myScore}-${match.opponentScore}',
            style: AppTextStyles.numeric.copyWith(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(width: 10),
          Text(resultLabel, style: AppTextStyles.label.copyWith(color: resultColor, fontSize: 13)),
        ],
      ),
    );
  }
}
