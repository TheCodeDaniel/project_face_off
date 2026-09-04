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
import '../../../../core/widgets/game_match_result_view.dart';
import '../../../../core/widgets/match_header.dart';
import '../../../../core/widgets/quit_match_dialog.dart';
import '../../../../core/widgets/reconnecting_banner.dart';
import '../domain/face_off_game_module.dart';
import 'face_off_outcome_message.dart';
import 'widgets/dev_gesture_controls.dart';
import 'widgets/face_off_phase_view.dart';

/// The live Face Off match screen (master prompt Section 8) — dark/neon
/// match register (Blueprint Section 3), a deliberate contrast to the bright
/// lobby. Drives the game-agnostic [matchControllerProvider] for match-level
/// chrome (score header, recap toast, result screen, quit/connectivity
/// handling — multi-game plan Section 3.2) and separately listens to the
/// active [FaceOffGameModule]'s own `roundState` via [ListenableBuilder] for
/// this game's round-phase detail (cue/fire/dodge).
///
/// [gameId] is passed in rather than picked here — whoever hands off to this
/// screen (`MatchFoundScreen` for Quick Match, a friend-challenge flow for a
/// private match) already resolved which game the match is for (multi-game
/// plan Section 3.5); this screen just plays it. [matchId]/[opponentId] are
/// the real match/player identities `GameMatchResultView` needs for Rematch/
/// Add Friend/Report/Block (post-match flow plan) — distinct from
/// `MatchController`'s own internal `'me'`/`'opponent'` round-engine slot
/// labels, which never leave the local game engine.
///
/// Wrapped in a [PopScope] that intercepts any attempt to leave — system
/// back gesture/button, or an in-app pop — while a round is still live and
/// confirms via [QuitMatchDialog] first, since leaving mid-match forfeits
/// it. Once the match has actually ended ([MatchCompleteMatchState]), leaving
/// is free. [MatchHeader] also carries an explicit exit button wired to the
/// same [_handlePopAttempt] flow — iOS has no system back button and the
/// edge-swipe gesture isn't an obvious affordance mid-match, so `PopScope`
/// alone left no discoverable way out.
class FaceOffScreen extends ConsumerStatefulWidget {
  const FaceOffScreen({
    super.key,
    required this.matchId,
    required this.opponentId,
    required this.opponentName,
    this.gameId = GameId.faceOff,
  });

  final String matchId;
  final String opponentId;
  final String opponentName;
  final GameId gameId;

  @override
  ConsumerState<FaceOffScreen> createState() => _FaceOffScreenState();
}

class _FaceOffScreenState extends ConsumerState<FaceOffScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(matchControllerProvider.notifier)
          .startMatch(
            gameId: widget.gameId,
            matchId: widget.matchId,
            realOpponentId: widget.opponentId,
            opponentLabel: widget.opponentName,
          );
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
    // post-frame callback calls startMatch. It's not the only reason there's
    // nothing safe to render yet, though: `matchControllerProvider` is
    // autoDispose, and its teardown-and-recreate on a screen swap isn't
    // perfectly synchronous with widget building — briefly, this screen can
    // build against a *stale* MatchController still holding a *different*
    // game's module (a hard `as FaceOffGameModule` cast on that would throw
    // a real, reproducible `_TypeError`, caught live rebuilding straight
    // from BowDrawScreen to FreezeScreen). Guard on the module's actual
    // type, not just the coarse match state, and fall back to the same
    // blank placeholder either way — it clears itself within a frame once
    // startMatch actually applies.
    if (matchState is NoActiveMatchState || controller.activeModule is! FaceOffGameModule) {
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
                  child: MatchHeader(
                    roundNumber: roundNumber,
                    myScore: scores[MatchController.meId] ?? 0,
                    opponentScore: scores[MatchController.opponentId] ?? 0,
                    opponentLabel: widget.opponentName,
                    onExit: () => _handlePopAttempt(matchState),
                  ),
                ),
                if (isOfflinePaused) const ReconnectingBanner(),
                Expanded(
                  child: Center(
                    child: matchState is MatchCompleteMatchState
                        ? GameMatchResultView(
                            result: matchState,
                            matchId: widget.matchId,
                            opponentId: widget.opponentId,
                            opponentLabel: widget.opponentName,
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
