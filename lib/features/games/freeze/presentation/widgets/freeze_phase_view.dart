import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/match_palette.dart';
import '../../../../../core/widgets/app_icon.dart';
import '../../domain/freeze_state.dart';

/// Center-stage content for the current [FreezeState] — same role as Face
/// Off's `FaceOffPhaseView`. The freeze cue is deliberately unpredictable —
/// never a countdown — so [BuildingFreezeState] shows only loose "keep
/// moving" framing, never a timer that would let a player time the freeze.
class FreezePhaseView extends StatelessWidget {
  const FreezePhaseView({super.key, required this.state});

  final FreezeState state;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<MatchPalette>() ?? MatchPalette.standard;
    return switch (state) {
      BuildingFreezeState() => const _PhaseMessage(
        icon: HugeIcons.strokeRoundedWalking,
        color: Colors.white70,
        title: 'Keep moving…',
        subtitle: 'The freeze could hit any moment.',
      ),
      FrozenState() => _PhaseMessage(
        icon: HugeIcons.strokeRoundedSnow,
        color: palette.neonCyan,
        title: 'FREEZE!',
        subtitle: "Don't move a muscle.",
        pulse: true,
      ),
      ResolvingFreezeState() => const _PhaseMessage(
        icon: HugeIcons.strokeRoundedHourglass,
        color: Colors.white70,
        title: 'Resolving…',
        subtitle: '',
      ),
      FreezeResultState() => const SizedBox.shrink(),
    };
  }
}

class _PhaseMessage extends StatelessWidget {
  const _PhaseMessage({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.pulse = false,
  });

  final List<List<dynamic>> icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon(icon, color: color, size: 64),
        const SizedBox(height: 20),
        Text(title, style: AppTextStyles.display.copyWith(color: Colors.white, fontSize: 30)),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTextStyles.body.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
