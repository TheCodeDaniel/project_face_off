import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/connectivity/connectivity_providers.dart';
import '../../../../core/game_engine/game_pool.dart';
import '../../../../core/game_engine/match_controller.dart';
import '../../../../core/game_engine/match_offline_pause_provider.dart';
import '../../../../core/game_engine/match_state.dart';
import '../../../../core/theme/match_palette.dart';
import '../../../../core/widgets/activity_toast.dart';
import '../domain/face_off_game_module.dart';
import 'face_off_outcome_message.dart';
import 'widgets/dev_gesture_controls.dart';
import 'widgets/duel_match_header.dart';
import 'widgets/face_off_match_result_view.dart';
import 'widgets/face_off_phase_view.dart';
import 'widgets/quit_match_dialog.dart';
import 'widgets/reconnecting_banner.dart';

/// The live Face Off match screen (master prompt Section 8) — dark/neon
/// match register (Blueprint Section 3), a deliberate contrast to the bright
/// lobby. Drives the game-agnostic [matchControllerProvider] for match-level
/// chrome (score header, recap toast, result screen, quit/connectivity
/// handling — multi-game plan Section 3.2) and separately listens to the
/// active [FaceOffGameModule]'s own `roundState` via [ListenableBuilder] for
/// this game's round-phase detail (cue/fire/dodge).
///
/// Wrapped in a [PopScope] that intercepts any attempt to leave — system
/// back gesture/button, or an in-app pop — while a round is still live and
/// confirms via [QuitMatchDialog] first, since leaving mid-match forfeits
/// it. Once the match has actually ended ([MatchCompleteMatchState]), leaving
/// is free. [DuelMatchHeader] also carries an explicit exit button wired to
/// the same [_handlePopAttempt] flow — iOS has no system back button and the
/// edge-swipe gesture isn't an obvious affordance mid-match, so `PopScope`
/// alone left no discoverable way out.
class FaceOffScreen extends ConsumerStatefulWidget {
  const FaceOffScreen({super.key, required this.opponentName});

  final String opponentName;

  @override
  ConsumerState<FaceOffScreen> createState() => _FaceOffScreenState();
}

class _FaceOffScreenState extends ConsumerState<FaceOffScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(matchControllerProvider.notifier).startMatch(pickRandomGameId(), widget.opponentName);
    });
  }

  Future<void> _handlePopAttempt(MatchState state) async {
    if (state is MatchCompleteMatchState) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final shouldQuit = await QuitMatchDialog.show(context);
    if (shouldQuit && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<MatchPalette>() ?? MatchPalette.standard;
    final controller = ref.read(matchControllerProvider.notifier);

    ref.listen(matchControllerProvider, (previous, next) {
      if (next is RoundRecapMatchState && previous is! RoundRecapMatchState) {
        ActivityToast.show(context, message: faceOffOutcomeMessage(next.outcome, widget.opponentName));
      }
    });

    // Master prompt Section 12: pauses the match locally, shows a
    // reconnecting toast, and forfeits after a grace period if the
    // connection doesn't return — see MatchController.handleConnectivityChange.
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

    final matchState = ref.watch(matchControllerProvider);
    final isOfflinePaused = ref.watch(matchOfflinePauseProvider);

    // NoActiveMatchState only exists for the single frame before initState's
    // post-frame callback calls startMatch — activeModule isn't set up yet,
    // so there's nothing meaningful to render besides the background.
    if (matchState is NoActiveMatchState) {
      return Scaffold(
        body: DecoratedBox(decoration: BoxDecoration(gradient: palette.backgroundGradient)),
      );
    }

    final scores = matchState is MatchCompleteMatchState ? matchState.scores : controller.scores;
    final roundNumber = controller.roundNumber;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handlePopAttempt(matchState);
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
                    roundNumber: roundNumber,
                    myScore: scores[MatchController.meId] ?? 0,
                    opponentScore: scores[MatchController.opponentId] ?? 0,
                    onExit: () => _handlePopAttempt(matchState),
                  ),
                ),
                if (isOfflinePaused) const ReconnectingBanner(),
                Expanded(
                  child: Center(
                    child: matchState is MatchCompleteMatchState
                        ? FaceOffMatchResultView(
                            result: matchState,
                            opponentLabel: widget.opponentName,
                            onRematch: () => controller.startMatch(pickRandomGameId(), widget.opponentName),
                            onExit: () => Navigator.of(context).popUntil((r) => r.isFirst),
                          )
                        : ListenableBuilder(
                            listenable: controller.activeModule as FaceOffGameModule,
                            builder: (context, _) =>
                                FaceOffPhaseView(state: (controller.activeModule as FaceOffGameModule).roundState),
                          ),
                  ),
                ),
                if (matchState is! MatchCompleteMatchState)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: DevGestureControls(
                      opponentLabel: widget.opponentName,
                      onFire: (controller.activeModule as FaceOffGameModule).triggerFire,
                      onDodge: (controller.activeModule as FaceOffGameModule).triggerDodge,
                      onCrack: (controller.activeModule as FaceOffGameModule).triggerCrack,
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
