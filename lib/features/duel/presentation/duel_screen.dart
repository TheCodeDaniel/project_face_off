import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/match_palette.dart';
import '../../../core/widgets/activity_toast.dart';
import '../domain/round_state.dart';
import 'duel_controller.dart';
import 'duel_outcome_message.dart';
import 'widgets/dev_gesture_controls.dart';
import 'widgets/duel_match_result_view.dart';
import 'widgets/duel_phase_view.dart';
import 'widgets/duel_scoreboard_panel.dart';

/// The live duel screen (master prompt Section 8) — dark/neon match register
/// (Blueprint Section 3), a deliberate contrast to the bright lobby. Owns
/// [duelControllerProvider] for the lifetime of one match.
class DuelScreen extends ConsumerStatefulWidget {
  const DuelScreen({super.key, required this.opponentName});

  final String opponentName;

  @override
  ConsumerState<DuelScreen> createState() => _DuelScreenState();
}

class _DuelScreenState extends ConsumerState<DuelScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(duelControllerProvider.notifier).startMatch(widget.opponentName);
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<MatchPalette>() ?? MatchPalette.standard;
    final controller = ref.read(duelControllerProvider.notifier);

    ref.listen(duelControllerProvider, (previous, next) {
      if (next is RoundResultRoundState && previous is! RoundResultRoundState) {
        ActivityToast.show(context, message: duelOutcomeMessage(next.outcome, widget.opponentName));
      }
    });

    final state = ref.watch(duelControllerProvider);
    final scores = controller.scores;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: palette.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: DuelScoreboardPanel(
                  myScore: scores[DuelController.meId] ?? 0,
                  opponentScore: scores[DuelController.opponentId] ?? 0,
                  opponentLabel: widget.opponentName,
                ),
              ),
              Expanded(
                child: Center(
                  child: state is MatchResultRoundState
                      ? DuelMatchResultView(
                          result: state,
                          opponentLabel: widget.opponentName,
                          onRematch: () => controller.startMatch(widget.opponentName),
                          onExit: () => Navigator.of(context).popUntil((r) => r.isFirst),
                        )
                      : DuelPhaseView(state: state),
                ),
              ),
              if (state is! MatchResultRoundState)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: DevGestureControls(
                    opponentLabel: widget.opponentName,
                    onFire: controller.triggerFire,
                    onDodge: controller.triggerDodge,
                    onCrack: controller.triggerCrack,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
