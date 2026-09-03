import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography tokens (Blueprint Section 3), built on three deliberately
/// distinct Google Fonts rather than one system default — each earns its
/// keep:
/// - **Fredoka** for display/headline: bold, rounded, high-personality —
///   matches the "MiMeo chunky" party-game register the blueprint calls for.
/// - **Plus Jakarta Sans** for body/UI: a clean geometric sans that stays
///   legible at small sizes without competing with the display face.
/// - **Space Grotesk** for numerics: scores, coin counts, timers get a
///   techy/tabular feel that reads as "instrumentation" rather than prose —
///   paired with [FontFeature.tabularFigures] so digits never jitter width
///   during countdowns.
///
/// These are getters, not `const` fields — [GoogleFonts] resolves lazily and
/// caches the downloaded font file itself.
abstract final class AppTextStyles {
  static const _tabularFigures = [FontFeature.tabularFigures()];

  static TextStyle get display => GoogleFonts.fredoka(fontWeight: FontWeight.w600, fontSize: 34, height: 1.08);

  static TextStyle get headline => GoogleFonts.fredoka(fontWeight: FontWeight.w600, fontSize: 22, height: 1.15);

  static TextStyle get body => GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500, fontSize: 15, height: 1.4);

  static TextStyle get label => GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13, height: 1.2);

  /// Scores, coin counts, timers — tabular figures prevent digit-width jitter.
  static TextStyle get numeric =>
      GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 20, height: 1.1, fontFeatures: _tabularFigures);

  static TextStyle get numericLarge =>
      GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 42, height: 1.0, fontFeatures: _tabularFigures);

  /// Base [TextTheme] fallback so any un-styled `Text` widget still lands on
  /// the body font instead of the platform default.
  static TextTheme textTheme(TextTheme base) => GoogleFonts.plusJakartaSansTextTheme(base);
}
