import 'package:flutter/foundation.dart';

/// State of a rematch request from the requester's own point of view
/// (post-match flow plan Section 3) — the results screen only ever needs
/// this local view; it never renders anything for the opponent's side of a
/// request it didn't send.
@immutable
sealed class RematchState {
  const RematchState();
}

/// No rematch request in flight — the normal results-screen state.
final class RematchIdle extends RematchState {
  const RematchIdle();
}

/// Request sent, awaiting the opponent's response. [secondsRemaining] backs
/// the visible countdown the plan calls for.
final class RematchRequesting extends RematchState {
  const RematchRequesting({required this.secondsRemaining});

  final int secondsRemaining;
}

/// Opponent accepted — [matchId] is the new match both sides jump straight
/// into, skipping the matchmaking queue.
final class RematchAccepted extends RematchState {
  const RematchAccepted({required this.matchId});

  final String matchId;
}

/// Opponent declined, or the request timed out — both revert to the same
/// idle-equivalent screen state (plan: "no error state, no dead end"), but
/// kept as distinct variants since a screen may briefly want to say
/// "declined" before resetting rather than snapping back silently.
final class RematchDeclined extends RematchState {
  const RematchDeclined();
}

final class RematchTimedOut extends RematchState {
  const RematchTimedOut();
}
