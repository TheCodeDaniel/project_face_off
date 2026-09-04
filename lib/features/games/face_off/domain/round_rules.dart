/// Tunable constants for Face Off's own round timing (master prompt Section
/// 8.4/8.5). Kept as named constants, not magic numbers, so they can be
/// retuned during playtesting without touching `FaceOffRoundEngine` logic.
/// Match-level rules shared by every game (best-of-5, connectivity forfeit)
/// live in `core/game_engine/match_rules.dart` instead — see that file.
abstract final class RoundRules {
  /// Grace period before a "relax your face to begin" nudge — UI-only, never
  /// fails the match.
  static const Duration neutralGracePeriod = Duration(seconds: 3);

  /// Random cue-arm delay range, generated server-side (master prompt 8.4).
  static const Duration cueDelayMin = Duration(milliseconds: 1000);
  static const Duration cueDelayMax = Duration(milliseconds: 4000);

  /// Window during which a second crack counts as "simultaneous" -> draw.
  static const Duration simultaneousCrackWindow = Duration(milliseconds: 150);

  /// Reaction window for a dodge to negate an attacker's fire.
  static const Duration dodgeWindow = Duration(milliseconds: 400);

  /// Overall round timeout guarding against a stuck/disconnected client.
  static const Duration roundTimeout = Duration(seconds: 8);

  /// Spec default: a clean dodge resets to an active exchange rather than
  /// instantly winning the round for the dodger. Flip during playtesting to
  /// try the alternate rule (see master prompt 8.4).
  static const bool dodgeEndsRoundOnSuccess = false;
}
