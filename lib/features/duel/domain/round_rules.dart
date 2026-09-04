/// Tunable constants for round timing (master prompt Section 8.4/8.5). Kept
/// as named constants, not magic numbers, so they can be retuned during
/// playtesting without touching `DuelRoundEngine` logic.
abstract final class RoundRules {
  /// Rounds needed to win a best-of-5 match.
  static const int roundsToWinMatch = 3;

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

  /// Grace period after this device loses connectivity mid-match before the
  /// match is forfeited (master prompt Section 12 / Blueprint Section 5:
  /// "a reasonable timeout (e.g., 20s) before the match is forfeited
  /// gracefully").
  static const Duration offlineForfeitTimeout = Duration(seconds: 20);

  /// Spec default: a clean dodge resets to an active exchange rather than
  /// instantly winning the round for the dodger. Flip during playtesting to
  /// try the alternate rule (see master prompt 8.4).
  static const bool dodgeEndsRoundOnSuccess = false;
}
