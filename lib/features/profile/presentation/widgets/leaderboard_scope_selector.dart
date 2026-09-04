import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/lobby_palette.dart';
import '../../domain/leaderboard_scope.dart';

/// Global/Regional/Friends toggle for the Leaderboard screen. A segmented
/// pill with a sliding accent highlight rather than a dropdown — a small
/// fixed set of options, so a tap-to-switch segmented control reads faster
/// than opening a menu, and it matches `FloatingNavBar`'s own "selected item
/// grows an accent-colored pill" motif (same 220ms `Curves.easeOutCubic`
/// animation) rather than introducing a new interaction language for the
/// lobby chrome. The sliding-highlight position is computed generically from
/// `LeaderboardScope.values.length`, so it isn't hardcoded to any particular
/// segment count.
class LeaderboardScopeSelector extends StatelessWidget {
  const LeaderboardScopeSelector({super.key, required this.scope, required this.onChanged});

  final LeaderboardScope scope;
  final ValueChanged<LeaderboardScope> onChanged;

  static const _labels = {
    LeaderboardScope.global: 'Global',
    LeaderboardScope.regional: 'Regional',
    LeaderboardScope.friends: 'Friends',
  };

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<LobbyPalette>() ?? LobbyPalette.standard;
    final selectedIndex = LeaderboardScope.values.indexOf(scope);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.2),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = constraints.maxWidth / LeaderboardScope.values.length;
          return Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: Alignment(-1 + (2 * selectedIndex) / (LeaderboardScope.values.length - 1), 0),
                child: Container(
                  width: segmentWidth,
                  height: 36,
                  decoration: BoxDecoration(color: palette.gradientMid, borderRadius: BorderRadius.circular(999)),
                ),
              ),
              Row(
                children: [
                  for (final value in LeaderboardScope.values)
                    Expanded(
                      child: _SegmentButton(
                        label: _labels[value]!,
                        selected: value == scope,
                        onTap: () => onChanged(value),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: SizedBox(
        height: 36,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            style: AppTextStyles.label.copyWith(
              color: selected ? Colors.white : Colors.white70,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}
