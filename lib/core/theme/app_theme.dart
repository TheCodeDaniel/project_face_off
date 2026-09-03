import 'package:flutter/material.dart';

import 'app_text_styles.dart';
import 'lobby_palette.dart';
import 'match_palette.dart';

/// Single entry point for [ThemeData]. Screens must pull colors via
/// `Theme.of(context).extension<LobbyPalette>()` /
/// `Theme.of(context).extension<MatchPalette>()` — no raw hex colors outside
/// `lib/core/theme/` anywhere in the app (Definition of Done, master prompt).
abstract final class AppTheme {
  static ThemeData get light {
    const lobby = LobbyPalette.standard;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lobby.cardBackground,
      colorScheme: ColorScheme.fromSeed(seedColor: lobby.gradientStart, brightness: Brightness.light),
      textTheme: AppTextStyles.textTheme(ThemeData(brightness: Brightness.light).textTheme),
      extensions: const [LobbyPalette.standard, MatchPalette.standard],
    );
  }
}
