import 'package:flutter/foundation.dart';

/// Matchmaking-queue state (master prompt Section 7). Modeled as a sealed
/// hierarchy, same rationale as `RoundState` in the duel feature: exhaustive
/// `switch` handling, no ad-hoc booleans.
@immutable
sealed class MatchmakingState {
  const MatchmakingState();
}

final class MatchmakingIdle extends MatchmakingState {
  const MatchmakingIdle();
}

/// Waiting in queue. [elapsed] drives the timeout check — a reasonable
/// timeout (e.g. 20s) shows a friendly retry/cancel prompt rather than
/// leaving the player in an indefinite spinner.
final class MatchmakingSearching extends MatchmakingState {
  const MatchmakingSearching();
}

final class MatchmakingFound extends MatchmakingState {
  const MatchmakingFound({required this.matchId, required this.opponentId, required this.opponentName});

  final String matchId;

  /// The opponent's stable player id — distinct from `MatchController`'s
  /// internal `'me'`/`'opponent'` round-engine slot labels, which never
  /// leave the local game engine. This is the real identity used for
  /// post-match actions (Rematch, Add Friend, Report/Block) that need to
  /// target a specific player.
  final String opponentId;
  final String opponentName;
}

final class MatchmakingTimedOut extends MatchmakingState {
  const MatchmakingTimedOut();
}
