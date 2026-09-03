import 'package:flutter/material.dart';

/// Typography tokens (Blueprint Section 3): a bold rounded display face for
/// headlines/scores, a clean geometric sans for body/UI text. Numbers always use
/// tabular figures so they don't jitter during countdowns.
///
/// No custom font files are bundled yet — these use Flutter's platform default
/// with the required weights/features until brand fonts are added under
/// `assets/fonts/` (see pubspec `flutter.fonts`).
abstract final class AppTextStyles {
  static const _tabularFigures = [FontFeature.tabularFigures()];

  static const TextStyle display = TextStyle(
    fontWeight: FontWeight.w900,
    fontSize: 32,
    height: 1.1,
    letterSpacing: -0.5,
  );

  static const TextStyle headline = TextStyle(fontWeight: FontWeight.w800, fontSize: 22, height: 1.15);

  static const TextStyle body = TextStyle(fontWeight: FontWeight.w500, fontSize: 15, height: 1.4);

  static const TextStyle label = TextStyle(fontWeight: FontWeight.w600, fontSize: 13, height: 1.2);

  /// Scores, coin counts, timers — tabular figures prevent digit-width jitter.
  static const TextStyle numeric = TextStyle(
    fontWeight: FontWeight.w800,
    fontSize: 20,
    height: 1.1,
    fontFeatures: _tabularFigures,
  );

  static const TextStyle numericLarge = TextStyle(
    fontWeight: FontWeight.w900,
    fontSize: 40,
    height: 1.0,
    fontFeatures: _tabularFigures,
  );
}
