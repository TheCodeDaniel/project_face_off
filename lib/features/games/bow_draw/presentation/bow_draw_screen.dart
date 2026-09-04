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
import '../domain/bow_draw_game_module.dart';
import 'bow_draw_outcome_message.dart';
import 'widgets/bow_draw_phase_view.dart';
import 'widgets/dev_draw_controls.dart';

/// The live Bow & Draw match screen — same shape as `FaceOffScreen` (see its
/// doc comment for the shared match-chrome/`GameModule` split rationale),
/// just delegating round-phase detail to [BowDrawPhaseView] instead.
class BowDrawScreen extends ConsumerStatefulWidget {
  const BowDrawScreen({super.key, required this.opponentName, this.gameId = GameId.bowDraw});

  final String opponentName;
  final GameId gameId;

  @override
  ConsumerState<BowDrawScreen> createState() => _BowDrawScreenState();
}

class _BowDrawScreenState extends ConsumerState<BowDrawScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(matchControllerProvider.notifier).startMatch(widget.gameId, widget.opponentName);
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
        ActivityToast.show(context, message: bowDrawOutcomeMessage(next.outcome, widget.opponentName));
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
                  child: MatchHeader(
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
                        ? GameMatchResultView(
                            result: matchState,
                            opponentLabel: widget.opponentName,
                            onRematch: () => controller.startMatch(widget.gameId, widget.opponentName),
                            onExit: () => Navigator.of(context).popUntil((r) => r.isFirst),
                          )
                        : ListenableBuilder(
                            listenable: controller.activeModule as BowDrawGameModule,
                            builder: (context, _) =>
                                BowDrawPhaseView(state: (controller.activeModule as BowDrawGameModule).drawState),
                          ),
                  ),
                ),
                if (matchState is! MatchCompleteMatchState)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: DevDrawControls(
                      opponentLabel: widget.opponentName,
                      onShoot: (controller.activeModule as BowDrawGameModule).triggerShoot,
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
