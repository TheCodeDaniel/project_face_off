import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/match_palette.dart';
import '../../../../../core/widgets/app_icon.dart';
import '../../domain/draw_state.dart';

/// Center-stage content for the current [DrawState] — same role as Face
/// Off's `FaceOffPhaseView`. The target's exact required power is
/// deliberately never shown as a number, same "don't reveal the precise
/// timing/target" instinct as Face Off's hidden cue — a stylized 2.5D range
/// visual is the real design target once assets exist (multi-game plan
/// Section 1: "stylized 2.5D... achieved with Flutter transforms and
/// layered sprites"); this is the placeholder read-out for the dev harness.
class BowDrawPhaseView extends StatelessWidget {
  const BowDrawPhaseView({super.key, required this.state});

  final DrawState state;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<MatchPalette>() ?? MatchPalette.standard;
    return switch (state) {
      NeutralDrawState() => const _PhaseMessage(
        icon: HugeIcons.strokeRoundedTarget01,
        color: Colors.white70,
        title: 'Get ready…',
        subtitle: 'The target will appear any moment.',
      ),
      ArmedDrawState() => _PhaseMessage(
        icon: HugeIcons.strokeRoundedTarget02,
        color: palette.neonCyan,
        title: 'Take your shot!',
        subtitle: 'Draw back, then release.',
        pulse: true,
      ),
      DrawResultState() => const SizedBox.shrink(),
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
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: AppTextStyles.body.copyWith(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
