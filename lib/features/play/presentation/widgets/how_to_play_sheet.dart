import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/lobby_palette.dart';
import '../../../../core/widgets/app_icon.dart';

/// Condensed rules explainer (master prompt Section 7) — deliberately *not*
/// the full onboarding showcase, just a quick reference a player can re-open
/// any time from the Play tab.
class HowToPlaySheet extends StatelessWidget {
  const HowToPlaySheet({super.key});

  static const _rules = [
    (icon: HugeIcons.strokeRoundedTarget02, text: 'Best of 5 rounds. First to 3 round wins takes the match.'),
    (icon: HugeIcons.strokeRoundedFaceId, text: 'Relax your face to start each round — no smiling, brows down.'),
    (icon: HugeIcons.strokeRoundedFlash, text: 'When the cue fires, be first to open your mouth to attack.'),
    (icon: HugeIcons.strokeRoundedAlertCircle, text: 'Fire early and you lose the round instantly — false start.'),
    (icon: HugeIcons.strokeRoundedWink, text: 'Raise your eyebrows fast enough after their attack to dodge it.'),
    (icon: HugeIcons.strokeRoundedSmile, text: "Crack a smile at the wrong moment and you lose the round on the spot."),
  ];

  /// [useRootNavigator]: true is the fix for a real bug, not a style choice
  /// — each tab has its own nested [Navigator] (Section 5, for per-tab
  /// back-stacks), and `AppShellScreen` paints `FloatingNavBar` as a Stack
  /// sibling *after* those nested navigators. A sheet pushed on the tab's
  /// own Navigator therefore renders underneath the nav bar, not above it.
  /// Pushing on the root Navigator instead puts the sheet above the entire
  /// shell, nav bar included.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const HowToPlaySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<LobbyPalette>() ?? LobbyPalette.standard;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                Text('How to Play', style: AppTextStyles.headline.copyWith(color: Colors.black87)),
                const SizedBox(height: 16),
                for (final rule in _rules) _RuleRow(icon: rule.icon, text: rule.text, accent: palette.gradientMid),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.icon, required this.text, required this.accent});

  final List<List<dynamic>> icon;
  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(icon, color: accent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: AppTextStyles.body.copyWith(color: Colors.black87)),
          ),
        ],
      ),
    );
  }
}
