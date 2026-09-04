import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/theme/match_palette.dart';
import '../../../../../core/widgets/app_icon.dart';

/// Live-match header: an explicit exit control (see [onExit] doc), round
/// number + running score, and two minimal ring "face" avatars either side
/// of a "vs" — a from-scratch abstract look (no camera-driven expressions
/// exist yet) rather than a plain numbers-only scorecard.
class DuelMatchHeader extends StatelessWidget {
  const DuelMatchHeader({
    super.key,
    required this.roundNumber,
    required this.myScore,
    required this.opponentScore,
    required this.onExit,
  });

  final int roundNumber;
  final int myScore;
  final int opponentScore;

  /// Always-visible exit affordance — iOS has no system back button, and the
  /// swipe-back gesture isn't obviously discoverable mid-match, so relying
  /// on `PopScope` alone leaves no way out for a player who doesn't know (or
  /// can't perform) that gesture. Wired to the same quit-confirmation flow
  /// as the gesture in `FaceOffScreen`, not a silent bypass of it.
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
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _FaceAvatar(color: palette.neonViolet),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Text('vs', style: AppTextStyles.label.copyWith(color: Colors.white54)),
            ),
            _FaceAvatar(color: palette.neonCyan),
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

class _FaceAvatar extends StatelessWidget {
  const _FaceAvatar({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 1.4),
          color: color.withValues(alpha: 0.12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _EyeDot(color: color),
            const SizedBox(width: 6),
            _EyeDot(color: color),
          ],
        ),
      ),
    );
  }
}

class _EyeDot extends StatelessWidget {
  const _EyeDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
