import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/match_palette.dart';
import '../../../../../core/widgets/app_icon.dart';
import '../../../../../core/widgets/floating_label_layer.dart';
import '../../domain/freeze_state.dart';
import 'freeze_stage_backdrop.dart';

/// Center-stage visual for the current [FreezeState] — same layered-depth
/// treatment as `BowDrawPhaseView` (game/UI/backend guideline Section 1),
/// just a stage instead of a range: no rig to draw here, so the phase
/// message stays the primary focus, sitting over [FreezeStageBackdrop]. The
/// freeze cue is deliberately unpredictable — never a countdown — so
/// [BuildingFreezeState] shows only loose "keep moving" framing, never a
/// timer that would let a player time the freeze.
class FreezePhaseView extends StatelessWidget {
  const FreezePhaseView({super.key, required this.state, required this.labelController});

  final FreezeState state;
  final FloatingLabelController labelController;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<MatchPalette>() ?? MatchPalette.standard;
    return Stack(
      fit: StackFit.expand,
      children: [
        const Positioned.fill(child: FreezeStageBackdrop()),
        Positioned.fill(child: FloatingLabelLayer(controller: labelController)),
        Center(
          child: switch (state) {
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
            ),
            ResolvingFreezeState() => const _PhaseMessage(
              icon: HugeIcons.strokeRoundedHourglass,
              color: Colors.white70,
              title: 'Resolving…',
              subtitle: '',
            ),
            FreezeResultState() => const SizedBox.shrink(),
          },
        ),
      ],
    );
  }
}

class _PhaseMessage extends StatelessWidget {
  const _PhaseMessage({required this.icon, required this.color, required this.title, required this.subtitle});

  final List<List<dynamic>> icon;
  final Color color;
  final String title;
  final String subtitle;

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
