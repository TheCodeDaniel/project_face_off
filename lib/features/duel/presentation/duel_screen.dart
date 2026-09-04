import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../core/connectivity/connectivity_providers.dart';
import '../../../core/theme/match_palette.dart';
import '../../../core/widgets/activity_toast.dart';
import '../domain/round_state.dart';
import 'duel_controller.dart';
import 'duel_offline_pause_provider.dart';
import 'duel_outcome_message.dart';
import 'widgets/dev_gesture_controls.dart';
import 'widgets/duel_match_header.dart';
import 'widgets/duel_match_result_view.dart';
import 'widgets/duel_phase_view.dart';
import 'widgets/quit_match_dialog.dart';
import 'widgets/reconnecting_banner.dart';

/// The live duel screen (master prompt Section 8) — dark/neon match register
/// (Blueprint Section 3), a deliberate contrast to the bright lobby. Owns
/// [duelControllerProvider] for the lifetime of one match.
///
/// Wrapped in a [PopScope] that intercepts any attempt to leave — system
/// back gesture/button, or an in-app pop — while a round is still live and
/// confirms via [QuitMatchDialog] first, since leaving mid-match forfeits
/// it. Once the match has actually ended ([MatchResultRoundState]), leaving
/// is free. [DuelMatchHeader] also carries an explicit exit button wired to
/// the same [_handlePopAttempt] flow — iOS has no system back button and the
/// edge-swipe gesture isn't an obvious affordance mid-match, so `PopScope`
/// alone left no discoverable way out.
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

  Future<void> _handlePopAttempt(RoundState state) async {
    if (state is MatchResultRoundState) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final shouldQuit = await QuitMatchDialog.show(context);
    if (shouldQuit && mounted) Navigator.of(context).pop();
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

    // Master prompt Section 12: pauses the match locally, shows a
    // reconnecting toast, and forfeits after a grace period if the
    // connection doesn't return — see DuelController.handleConnectivityChange.
    ref.listen(isOnlineProvider, (previous, next) {
      final isOnline = next.valueOrNull ?? true;
      final wasOffline = previous?.valueOrNull == false;
      controller.handleConnectivityChange(isOnline);
      if (!isOnline) {
        ActivityToast.show(context, message: "You're offline — reconnecting…", icon: HugeIcons.strokeRoundedWifiOff01);
      } else if (wasOffline) {
        ActivityToast.show(context, message: 'Back online!', icon: HugeIcons.strokeRoundedWifiOff01);
      }
    });

    final state = ref.watch(duelControllerProvider);
    final isOfflinePaused = ref.watch(duelOfflinePauseProvider);
    final scores = controller.scores;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handlePopAttempt(state);
      },
      child: Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(gradient: palette.backgroundGradient),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: DuelMatchHeader(
                    roundNumber: controller.roundNumber,
                    myScore: scores[DuelController.meId] ?? 0,
                    opponentScore: scores[DuelController.opponentId] ?? 0,
                    onExit: () => _handlePopAttempt(state),
                  ),
                ),
                if (isOfflinePaused) const ReconnectingBanner(),
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
      ),
    );
  }
}
