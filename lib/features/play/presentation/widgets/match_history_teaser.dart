import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_icon.dart';

/// Last-3-results teaser on the Play tab (master prompt Section 7); full
/// history lives in Profile. No match history exists yet — needs the duel
/// feature's Firestore write-back (Section 8/CLAUDE.md) — so this renders an
/// empty state rather than fabricated results.
class MatchHistoryTeaser extends StatelessWidget {
  const MatchHistoryTeaser({super.key});

  @override
  Widget build(BuildContext context) {
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
}
