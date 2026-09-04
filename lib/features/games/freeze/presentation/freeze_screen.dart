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
import '../../../../core/widgets/floating_label_layer.dart';
import '../../../../core/widgets/game_match_result_view.dart';
import '../../../../core/widgets/match_header.dart';
import '../../../../core/widgets/quit_match_dialog.dart';
import '../../../../core/widgets/reconnecting_banner.dart';
import '../domain/freeze_game_module.dart';
import 'freeze_outcome_message.dart';
import 'widgets/dev_freeze_controls.dart';
import 'widgets/freeze_phase_view.dart';

/// The live Freeze match screen — same shape as `FaceOffScreen` (see its doc
/// comment for the shared match-chrome/`GameModule` split rationale), just
/// delegating round-phase detail to [FreezePhaseView] instead.
class FreezeScreen extends ConsumerStatefulWidget {
  const FreezeScreen({
    super.key,
    required this.matchId,
    required this.opponentId,
    required this.opponentName,
    this.gameId = GameId.freeze,
  });

  final String matchId;
  final String opponentId;
  final String opponentName;
  final GameId gameId;

  @override
  ConsumerState<FreezeScreen> createState() => _FreezeScreenState();
}

class _FreezeScreenState extends ConsumerState<FreezeScreen> {
  final _labelController = FloatingLabelController();
  Size _visualAreaSize = Size.zero;

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
        ActivityToast.show(context, message: freezeOutcomeMessage(next.outcome, widget.opponentName));
        final iWon = next.outcome.winnerId == MatchController.meId;
        final isDraw = next.outcome.winnerId == null;
        final labelColor = isDraw ? Colors.white70 : (iWon ? palette.neonCyan : palette.hotRed);
        final labelText = isDraw ? 'SAFE' : (iWon ? 'SAFE!' : 'BUSTED!');
        _labelController.spawn(
          text: labelText,
          position: Offset(_visualAreaSize.width / 2 - 30, _visualAreaSize.height * 0.4),
          color: labelColor,
        );
      }
    });

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
    // build against a *stale* MatchController still holding the *previous*
    // game's module (a hard `as FreezeGameModule` cast on that would throw a
    // real, reproducible `_TypeError`, caught live rebuilding straight from
    // BowDrawScreen). Guard on the module's actual type, not just the coarse
    // match state, and fall back to the same blank placeholder either way —
    // it clears itself within a frame once startMatch actually applies.
    if (matchState is NoActiveMatchState || controller.activeModule is! FreezeGameModule) {
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
                    onExit: () => _handlePopAttempt(matchState),
                  ),
                ),
                if (isOfflinePaused) const ReconnectingBanner(),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      _visualAreaSize = constraints.biggest;
                      return Center(
                        child: matchState is MatchCompleteMatchState
                            ? GameMatchResultView(
                                result: matchState,
                                matchId: widget.matchId,
                                opponentId: widget.opponentId,
                                opponentLabel: widget.opponentName,
                              )
                            : ListenableBuilder(
                                listenable: controller.activeModule as FreezeGameModule,
                                builder: (context, _) => FreezePhaseView(
                                  state: (controller.activeModule as FreezeGameModule).freezeState,
                                  labelController: _labelController,
                                ),
                              ),
                      );
                    },
                  ),
                ),
                if (matchState is! MatchCompleteMatchState)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: DevFreezeControls(
                      opponentLabel: widget.opponentName,
                      onMove: (controller.activeModule as FreezeGameModule).triggerMove,
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
