/// Match-level tunables shared by every game (multi-game plan Section 3.2) —
/// best-of-5 structure, connectivity forfeit, and recap pacing are the same
/// regardless of which game is being played. A single game's own *round*-
/// level timing (Face Off's cue delay/dodge window/etc.) stays local to that
/// game's own rules file — see `features/games/face_off/domain/round_rules.dart`.
abstract final class MatchRules {
  /// Rounds needed to win a best-of-5 match, any game.
  static const int roundsToWinMatch = 3;

  /// Brief pause after a round resolves, showing the recap, before the next
  /// round (or match result) begins.
  static const Duration roundRecapDuration = Duration(milliseconds: 2500);

  /// Grace period after this device loses connectivity mid-match before the
  /// match is forfeited (master prompt Section 12 / Blueprint Section 5).
  static const Duration offlineForfeitTimeout = Duration(seconds: 20);

  /// How long a rematch request stays open before auto-expiring back to the
  /// requester's normal results-screen state (post-match flow plan Section 4
  /// consolidated timeout table). v1 is in-app-only — this window only
  /// matters while both players are still on the results screen; no push
  /// notification wakes a backgrounded opponent to answer it.
  static const Duration rematchRequestTimeout = Duration(seconds: 18);

  /// A player who takes no action at all on the results screen (doesn't tap
  /// Next/Rematch/Add Friend/Report/Block) is auto-returned to the Play tab
  /// home after this — distinct from, and much longer than,
  /// [rematchRequestTimeout] (post-match flow plan Section 4).
  static const Duration resultsScreenIdleTimeout = Duration(seconds: 35);
}
