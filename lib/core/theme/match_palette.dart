import 'package:flutter/material.dart';

/// Theme tokens for the live duel screen only. Blueprint Section 3 — deliberately
/// dark/neon, a contrast to [LobbyPalette]'s warm/playful register.
@immutable
class MatchPalette extends ThemeExtension<MatchPalette> {
  const MatchPalette({
    required this.backgroundNavy,
    required this.backgroundIndigo,
    required this.neonViolet,
    required this.neonCyan,
    required this.hotRed,
  });

  final Color backgroundNavy;
  final Color backgroundIndigo;
  final Color neonViolet;
  final Color neonCyan;
  final Color hotRed;

  static const MatchPalette standard = MatchPalette(
    backgroundNavy: Color(0xFF0A0E27),
    backgroundIndigo: Color(0xFF1B1F4B),
    neonViolet: Color(0xFF8B5CF6),
    neonCyan: Color(0xFF4CD9E8),
    hotRed: Color(0xFFFF4D6D),
  );

  LinearGradient get backgroundGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundNavy, backgroundIndigo],
  );

  @override
  MatchPalette copyWith({
    Color? backgroundNavy,
    Color? backgroundIndigo,
    Color? neonViolet,
    Color? neonCyan,
    Color? hotRed,
  }) {
    return MatchPalette(
      backgroundNavy: backgroundNavy ?? this.backgroundNavy,
      backgroundIndigo: backgroundIndigo ?? this.backgroundIndigo,
      neonViolet: neonViolet ?? this.neonViolet,
      neonCyan: neonCyan ?? this.neonCyan,
      hotRed: hotRed ?? this.hotRed,
    );
  }

  @override
  MatchPalette lerp(ThemeExtension<MatchPalette>? other, double t) {
    if (other is! MatchPalette) return this;
    return MatchPalette(
      backgroundNavy: Color.lerp(backgroundNavy, other.backgroundNavy, t)!,
      backgroundIndigo: Color.lerp(backgroundIndigo, other.backgroundIndigo, t)!,
      neonViolet: Color.lerp(neonViolet, other.neonViolet, t)!,
      neonCyan: Color.lerp(neonCyan, other.neonCyan, t)!,
      hotRed: Color.lerp(hotRed, other.hotRed, t)!,
    );
  }
}
