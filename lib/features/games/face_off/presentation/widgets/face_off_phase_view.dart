import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/match_palette.dart';
import '../../../../../core/widgets/app_icon.dart';
import '../../domain/round_state.dart';

/// Center-stage content for the current [RoundState] (master prompt Section
/// 8.4). Cue timing is deliberately never shown numerically during
/// [CueArmedRoundState] — the spec requires the cue-fire moment stay hidden
/// from the player, only a tense "get ready" visual.
class FaceOffPhaseView extends StatelessWidget {
  const FaceOffPhaseView({super.key, required this.state});

  final RoundState state;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<MatchPalette>() ?? MatchPalette.standard;
    return switch (state) {
      NeutralRoundState() => const _PhaseMessage(
        icon: HugeIcons.strokeRoundedFaceId,
        color: Colors.white70,
        title: 'Relax your face to begin',
        subtitle: 'Mouth closed, brows down.',
      ),
      CueArmedRoundState() => _PhaseMessage(
        icon: HugeIcons.strokeRoundedTarget02,
        color: palette.neonViolet,
        title: 'Get ready…',
        subtitle: "The cue could fire any moment.",
        pulse: true,
      ),
      CueFiredRoundState(attackerId: final attackerId) => _PhaseMessage(
        icon: HugeIcons.strokeRoundedFlash,
        color: palette.neonCyan,
        title: attackerId == null ? 'FIRE!' : 'Dodge!',
        subtitle: attackerId == null ? 'Be first to attack.' : 'Raise your eyebrows to survive.',
        pulse: true,
      ),
      ResolvingRoundState() => const _PhaseMessage(
        icon: HugeIcons.strokeRoundedHourglass,
        color: Colors.white70,
        title: 'Resolving…',
        subtitle: '',
      ),
      RoundResultRoundState() => const SizedBox.shrink(),
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
