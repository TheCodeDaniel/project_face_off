import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../features/friends/presentation/friends_providers.dart';
import '../../features/friends/presentation/widgets/report_user_sheet.dart';
import '../../features/play/presentation/matchmaking_screen.dart';
import '../game_engine/match_controller.dart';
import '../game_engine/match_rules.dart';
import '../game_engine/match_state.dart';
import '../game_engine/rematch/rematch_controller.dart';
import '../game_engine/rematch/rematch_state.dart';
import '../theme/app_text_styles.dart';
import '../theme/match_palette.dart';
import 'app_icon.dart';
import 'match_found_screen.dart';
import 'primary_pill_button.dart';

/// Final score screen (post-match flow plan), shared by every game in the
/// pool since it only ever reads the game-agnostic [MatchCompleteMatchState]:
/// **Next** (instant re-queue into normal Quick Match — the fast, low-
/// friction default), **Rematch** (an ephemeral live request to this
/// specific opponent, plan Section 3), **Add Friend** (a normal persistent
/// request, reusing the exact Friends-tab pending-request system), and
/// **Report/Block** surfaced directly here rather than buried in the
/// Friends tab, since post-match is exactly when someone is most likely to
/// want to report bad behavior.
///
/// A player who takes no action at all is auto-returned to the Play tab
/// home after [MatchRules.resultsScreenIdleTimeout] — see the class-level
/// `_idleTimer` below. This is also the documented trigger point for the
/// post-match rewarded-ad offer and match-history save (Section 11 /
/// Firestore) — neither is wired up yet, see CLAUDE.md.
class GameMatchResultView extends ConsumerStatefulWidget {
  const GameMatchResultView({
    super.key,
    required this.result,
    required this.matchId,
    required this.opponentId,
    required this.opponentLabel,
  });

  final MatchCompleteMatchState result;
  final String matchId;
  final String opponentId;
  final String opponentLabel;

  @override
  ConsumerState<GameMatchResultView> createState() => _GameMatchResultViewState();
}

class _GameMatchResultViewState extends ConsumerState<GameMatchResultView> {
  Timer? _idleTimer;
  Timer? _rematchMessageResetTimer;
  bool _friendRequestSent = false;
  bool _blocked = false;

  @override
  void initState() {
    super.initState();
    _idleTimer = Timer(MatchRules.resultsScreenIdleTimeout, () {
      if (mounted) _exitToPlayHome();
    });
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _rematchMessageResetTimer?.cancel();
    super.dispose();
  }

  /// Any action at all counts as "not idle" — cancelled once, never
  /// restarted, since the plan's idle timeout is about a player who never
  /// engages with this screen, not about pacing between engagements.
  void _markActive() => _idleTimer?.cancel();

  void _exitToPlayHome() {
    ref.read(rematchControllerProvider.notifier).cancel();
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  void _handleNext() {
    _markActive();
    ref.read(rematchControllerProvider.notifier).cancel();
    // Captured before popUntil, which can deactivate this widget's own
    // context synchronously (same fix as FriendActionsSheet's challenge
    // flow) — reusing context afterward for the rootNavigator lookup is not
    // safe to assume works.
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    Navigator.of(context).popUntil((r) => r.isFirst);
    rootNavigator.push(MaterialPageRoute(builder: (_) => const MatchmakingScreen()));
  }

  void _handleRematch() {
    _markActive();
    ref.read(rematchControllerProvider.notifier).sendRequest(matchId: widget.matchId, opponentId: widget.opponentId);
  }

  void _handleRematchAccepted(RematchAccepted accepted) {
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    Navigator.of(context).popUntil((r) => r.isFirst);
    rootNavigator.push(
      MaterialPageRoute(
        builder: (_) => MatchFoundScreen(
          matchId: accepted.matchId,
          opponentId: widget.opponentId,
          opponentName: widget.opponentLabel,
          // Re-randomized, not "the same game again" — the documented v1
          // default (post-match flow plan Section 3); revisit only if
          // playtesting suggests players want a same-game rematch instead.
        ),
      ),
    );
  }

  /// Declined/timed-out revert to the normal idle state on their own after
  /// a moment, so the message is actually readable rather than vanishing
  /// the instant it appears.
  void _scheduleRematchMessageReset() {
    _rematchMessageResetTimer?.cancel();
    _rematchMessageResetTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) ref.read(rematchControllerProvider.notifier).acknowledge();
    });
  }

  Future<void> _handleAddFriend() async {
    _markActive();
    await ref.read(friendsRepositoryProvider).sendRequestToPlayer(widget.opponentId, widget.opponentLabel);
    if (mounted) setState(() => _friendRequestSent = true);
  }

  void _handleReport() {
    _markActive();
    ReportUserSheet.show(context, userId: widget.opponentId, displayName: widget.opponentLabel);
  }

  Future<void> _handleBlock() async {
    _markActive();
    await ref.read(friendsRepositoryProvider).blockUser(widget.opponentId);
    if (mounted) setState(() => _blocked = true);
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<MatchPalette>() ?? MatchPalette.standard;
    final iWon = widget.result.winnerId == MatchController.meId;
    final myScore = widget.result.scores[MatchController.meId] ?? 0;
    final opponentScore = widget.result.scores[MatchController.opponentId] ?? 0;

    ref.listen(rematchControllerProvider, (previous, next) {
      switch (next) {
        case RematchAccepted():
          _handleRematchAccepted(next);
        case RematchDeclined():
        case RematchTimedOut():
          _scheduleRematchMessageReset();
        case RematchIdle():
        case RematchRequesting():
          break;
      }
    });
    final rematchState = ref.watch(rematchControllerProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(
            iWon ? HugeIcons.strokeRoundedCrown : HugeIcons.strokeRoundedSadDizzy,
            color: iWon ? palette.neonCyan : palette.hotRed,
            size: 64,
          ),
          const SizedBox(height: 14),
          Text(
            iWon ? 'You won!' : '${widget.opponentLabel} won',
            style: AppTextStyles.display.copyWith(color: Colors.white, fontSize: 28),
          ),
          const SizedBox(height: 6),
          Text(
            '$myScore — $opponentScore',
            style: AppTextStyles.numericLarge.copyWith(color: Colors.white70, fontSize: 22),
          ),
          const SizedBox(height: 28),
          PrimaryPillButton(label: 'Next', icon: HugeIcons.strokeRoundedArrowRight01, onPressed: _handleNext),
          const SizedBox(height: 10),
          _RematchButton(state: rematchState, opponentLabel: widget.opponentLabel, onTap: _handleRematch),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _TertiaryAction(
                icon: _friendRequestSent ? HugeIcons.strokeRoundedCheckmarkCircle02 : HugeIcons.strokeRoundedUserAdd01,
                label: _friendRequestSent ? 'Sent' : 'Add Friend',
                onTap: _friendRequestSent ? null : _handleAddFriend,
              ),
              _TertiaryAction(icon: HugeIcons.strokeRoundedFlag02, label: 'Report', onTap: _handleReport),
              _TertiaryAction(
                icon: HugeIcons.strokeRoundedCancelCircle,
                label: _blocked ? 'Blocked' : 'Block',
                onTap: _blocked ? null : _handleBlock,
              ),
            ],
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: _exitToPlayHome,
            child: Text('Back to Play', style: AppTextStyles.label.copyWith(color: Colors.white54)),
          ),
        ],
      ),
    );
  }
}

class _RematchButton extends StatelessWidget {
  const _RematchButton({required this.state, required this.opponentLabel, required this.onTap});

  final RematchState state;
  final String opponentLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (label, enabled) = switch (state) {
      RematchIdle() => ('Rematch', true),
      RematchRequesting(:final secondsRemaining) => ('Waiting for $opponentLabel… ${secondsRemaining}s', false),
      RematchAccepted() => ('Rematch accepted!', false),
      RematchDeclined() => ('$opponentLabel declined', false),
      RematchTimedOut() => ('No response', false),
    };
    return SecondaryPillButton(label: label, icon: HugeIcons.strokeRoundedRefresh, onPressed: enabled ? onTap : null);
  }
}

class _TertiaryAction extends StatelessWidget {
  const _TertiaryAction({required this.icon, required this.label, required this.onTap});

  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = onTap == null ? Colors.white38 : Colors.white70;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyles.label.copyWith(color: color, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
