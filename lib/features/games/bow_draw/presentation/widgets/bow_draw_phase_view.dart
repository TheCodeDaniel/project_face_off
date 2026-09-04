import 'package:flutter/material.dart';

import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/match_palette.dart';
import '../../../../../core/widgets/floating_label_layer.dart';
import '../../domain/draw_state.dart';
import 'bow_draw_range_backdrop.dart';
import 'bow_draw_target.dart';
import 'bow_rig.dart';

/// Center-stage visual for the current [DrawState] — first-person archery
/// framing (game/UI/backend guideline Section 1): a layered range backdrop,
/// a target that pulses once the shot window is actually open, and a bow
/// rig whose draw-back tracks [livePower] frame-for-frame. The target's
/// exact required power is deliberately never shown as a number, same
/// "don't reveal the precise timing/target" instinct as Face Off's hidden
/// cue.
class BowDrawPhaseView extends StatelessWidget {
  const BowDrawPhaseView({super.key, required this.state, required this.livePower, required this.labelController});

  final DrawState state;
  final double livePower;
  final FloatingLabelController labelController;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<MatchPalette>() ?? MatchPalette.standard;
    final armed = state is ArmedDrawState;

    return Stack(
      fit: StackFit.expand,
      children: [
        const Positioned.fill(child: BowDrawRangeBackdrop()),
        Positioned.fill(child: FloatingLabelLayer(controller: labelController)),
        Align(
          alignment: const Alignment(0, -0.35),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BowDrawTarget(armed: armed, accentColor: palette.neonCyan),
              const SizedBox(height: 20),
              switch (state) {
                NeutralDrawState() => const _PhaseMessage(
                  color: Colors.white70,
                  title: 'Get ready…',
                  subtitle: 'The target will appear any moment.',
                ),
                ArmedDrawState() => _PhaseMessage(
                  color: palette.neonCyan,
                  title: 'Take your shot!',
                  subtitle: 'Draw back, then release.',
                ),
                DrawResultState() => const SizedBox.shrink(),
              },
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: BowRig(power: livePower, accentColor: palette.neonCyan),
        ),
      ],
    );
  }
}

class _PhaseMessage extends StatelessWidget {
  const _PhaseMessage({required this.color, required this.title, required this.subtitle});

  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: AppTextStyles.display.copyWith(color: color, fontSize: 26)),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: AppTextStyles.body.copyWith(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
