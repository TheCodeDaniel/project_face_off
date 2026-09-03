import 'package:flutter/material.dart';

/// Theme tokens for the "social" surfaces: Play, Friends, Profile.
/// Blueprint Section 3. Pull via `Theme.of(context).extension<LobbyPalette>()`.
@immutable
class LobbyPalette extends ThemeExtension<LobbyPalette> {
  const LobbyPalette({
    required this.gradientStart,
    required this.gradientMid,
    required this.gradientEnd,
    required this.cardBackground,
    required this.coinGold,
  });

  final Color gradientStart;
  final Color gradientMid;
  final Color gradientEnd;
  final Color cardBackground;
  final Color coinGold;

  static const LobbyPalette standard = LobbyPalette(
    gradientStart: Color(0xFF5B2A9E),
    gradientMid: Color(0xFFC6339E),
    gradientEnd: Color(0xFFF2793E),
    cardBackground: Color(0xFFFFFBF5),
    coinGold: Color(0xFFFFC94A),
  );

  LinearGradient get backgroundGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientStart, gradientMid, gradientEnd],
  );

  @override
  LobbyPalette copyWith({
    Color? gradientStart,
    Color? gradientMid,
    Color? gradientEnd,
    Color? cardBackground,
    Color? coinGold,
  }) {
    return LobbyPalette(
      gradientStart: gradientStart ?? this.gradientStart,
      gradientMid: gradientMid ?? this.gradientMid,
      gradientEnd: gradientEnd ?? this.gradientEnd,
      cardBackground: cardBackground ?? this.cardBackground,
      coinGold: coinGold ?? this.coinGold,
    );
  }

  @override
  LobbyPalette lerp(ThemeExtension<LobbyPalette>? other, double t) {
    if (other is! LobbyPalette) return this;
    return LobbyPalette(
      gradientStart: Color.lerp(gradientStart, other.gradientStart, t)!,
      gradientMid: Color.lerp(gradientMid, other.gradientMid, t)!,
      gradientEnd: Color.lerp(gradientEnd, other.gradientEnd, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      coinGold: Color.lerp(coinGold, other.coinGold, t)!,
    );
  }
}
