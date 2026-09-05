import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../game_engine/match_rules.dart';
import '../theme/app_text_styles.dart';
import '../theme/match_palette.dart';
import 'app_icon.dart';
import 'player_hud_capsule.dart';

/// Live-match header, shared by every game in the pool: an explicit exit
/// control (see [onExit] doc), round number + running score, and a
/// [PlayerHudCapsule] per side — top-left for the local player, mirrored
/// top-right for the opponent — the guideline's "simple capsule HUD"
/// applied consistently across Face Off, Bow & Draw, and Freeze rather than
/// each game growing its own scoreboard treatment.
class MatchHeader extends StatelessWidget {
  const MatchHeader({
    super.key,
    required this.roundNumber,
    required this.myScore,
    required this.opponentScore,
    required this.opponentLabel,
    required this.onExit,
  });

  final int roundNumber;
  final int myScore;
  final int opponentScore;
  final String opponentLabel;

  /// Always-visible exit affordance — iOS has no system back button, and the
  /// swipe-back gesture isn't obviously discoverable mid-match, so relying
  /// on `PopScope` alone leaves no way out for a player who doesn't know (or
  /// can't perform) that gesture. Wired to the same quit-confirmation flow
  /// as the gesture in each game's own screen, not a silent bypass of it.
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<MatchPalette>() ?? MatchPalette.standard;
    return Column(
      children: [
        Row(
          children: [
            _ExitButton(onTap: onExit),
            const SizedBox(width: 12),
            Text('Round $roundNumber', style: AppTextStyles.headline.copyWith(color: palette.neonViolet, fontSize: 16)),
            const Spacer(),
            Text('$myScore - $opponentScore', style: AppTextStyles.numeric.copyWith(color: Colors.white)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            PlayerHudCapsule(
              label: 'You',
              wins: myScore,
              winsNeeded: MatchRules.roundsToWinMatch,
              accentColor: palette.neonViolet,
            ),
            const Spacer(),
            PlayerHudCapsule(
              label: opponentLabel,
              wins: opponentScore,
              winsNeeded: MatchRules.roundsToWinMatch,
              accentColor: palette.neonCyan,
              reversed: true,
            ),
          ],
        ),
      ],
    );
  }
}

class _ExitButton extends StatelessWidget {
  const _ExitButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const Key('duelExitButton'),
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), shape: BoxShape.circle),
        alignment: Alignment.center,
        child: const AppIcon(HugeIcons.strokeRoundedCancel01, color: Colors.white, size: 16),
      ),
    );
  }
}
