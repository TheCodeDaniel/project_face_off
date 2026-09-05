import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';

/// Simple capsule HUD — portrait + wins-progress bar — reusing [CoinBadge]'s
/// pill-shaped, icon-plus-text capsule language for the live-match header
/// instead of a bespoke shape (game/UI/backend guideline Section 1: "a
/// simple capsule HUD ... applied consistently across all three games'
/// HUDs"). One instance per player, mirrored via [reversed] so the
/// portraits face inward from either side of the header — same widget, same
/// visual language, for Face Off, Bow & Draw, and Freeze alike.
class PlayerHudCapsule extends StatelessWidget {
  const PlayerHudCapsule({
    super.key,
    required this.label,
    required this.wins,
    required this.winsNeeded,
    required this.accentColor,
    this.reversed = false,
  });

  final String label;
  final int wins;
  final int winsNeeded;
  final Color accentColor;

  /// `true` for the side of the header where the portrait should sit
  /// closest to the screen edge (typically the opponent, top-right) rather
  /// than closest to the center.
  final bool reversed;

  @override
  Widget build(BuildContext context) {
    final portrait = _Portrait(color: accentColor);
    final labelAndBar = Column(
      crossAxisAlignment: reversed ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppTextStyles.label.copyWith(color: Colors.white, fontSize: 12)),
        const SizedBox(height: 4),
        _WinsBar(wins: wins, winsNeeded: winsNeeded, color: accentColor, reversed: reversed),
      ],
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accentColor.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: reversed
            ? [labelAndBar, const SizedBox(width: 10), portrait]
            : [portrait, const SizedBox(width: 10), labelAndBar],
      ),
    );
  }
}

class _Portrait extends StatelessWidget {
  const _Portrait({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _EyeDot(color: color),
          const SizedBox(width: 3),
          _EyeDot(color: color),
        ],
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
      width: 3,
      height: 3,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _WinsBar extends StatelessWidget {
  const _WinsBar({required this.wins, required this.winsNeeded, required this.color, required this.reversed});

  final int wins;
  final int winsNeeded;
  final Color color;
  final bool reversed;

  @override
  Widget build(BuildContext context) {
    final indices = List.generate(winsNeeded, (i) => i);
    final ordered = reversed ? indices.reversed.toList(growable: false) : indices;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var pos = 0; pos < ordered.length; pos++)
          Container(
            width: 16,
            height: 5,
            margin: EdgeInsets.only(right: pos == ordered.length - 1 ? 0 : 4),
            decoration: BoxDecoration(
              color: ordered[pos] < wins ? color : Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}
