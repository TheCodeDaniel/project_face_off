# Face Off — Post-Match Flow & Timeout Policy (new section, adds to existing plans)

This corrects the results-screen design implied (but not fully specified) in
the original build prompt. It also consolidates every timeout in the app
into one table, since they were previously scattered across sections.

---

## 1. Design philosophy

Continuous play, Omegle/Monkey-style: after a match, the fastest, lowest-
friction action is always "find someone new." Anything that continues with
the *same* stranger is a deliberate, consenting action, not a default. This
matters for two separate reasons: it's the UX pattern that keeps stranger-
matching apps engaging, and it's the safer pattern — nobody should end up
stuck in repeated matches with someone they don't want to keep playing.

## 2. Results screen — three distinct actions, three different mechanics

**Next (primary button, most prominent):**
Instant re-queue into normal Quick Match matchmaking, same mechanism as
tapping Quick Match from the Play tab — this is not a new system, just a
shortcut entry point. No request, no waiting on the previous opponent, no
confirmation needed. Always available immediately, even if a rematch
request (below) is pending in either direction — tapping Next silently
cancels/declines any pending rematch state for that player.

**Rematch (secondary button):**
Sends a live, ephemeral request to the specific opponent just played. Not a
friend request, not persistent — see Section 3.

**Add Friend (small, tertiary action):**
Sends a normal, persistent friend request through the existing Friends-tab
request system already specified in the original build prompt (Section 9
there). Unlike Rematch, this is not time-boxed or urgent — it behaves
exactly like any other friend request, sitting in the recipient's pending
list until they act on it, even if that's days later.

**Report/Block should also be one tap away here, not buried.** Post-match is
exactly when someone is most likely to want to report bad behavior. Surface
the existing report/block flow (already specified under Friends) directly
on the results screen too — same backend, just a second, contextual entry
point.

## 3. Rematch requests — ephemeral, in-app only for v1

- When Player A taps Rematch, Player B sees a live prompt ("A wants a
  rematch") with Accept/Decline, and a visible countdown.
- **This only works while both players are still on the results screen in
  the app.** For v1, do not build push-notification delivery for this — if
  the opponent has already backgrounded the app or navigated away, the
  request simply times out on the requester's side. Full async
  (push-notification-reachable) rematch requests are a reasonable v2
  addition, not a v1 requirement — flag it as such in a code comment rather
  than building FCM integration now for a 15-20 second window.
- If accepted: both clients skip the matchmaking queue entirely and go
  straight into a new match against each other, game re-randomized the same
  way a fresh Quick Match would be (server-authoritative pick, same
  mechanism as before — rematching does not mean replaying the same game
  that was just played, it's a new random pick unless you decide otherwise;
  note this as the default and revisit only if playtesting suggests players
  want "same game again" instead).
- If declined, ignored, or timed out: the requester's UI simply reverts to
  the normal results-screen state (Next / Add Friend / Report still
  available) — no error state, no dead end.
- The requester is never blocked from doing something else while waiting —
  they can tap Next themselves at any point, which cancels their own
  pending request.

## 4. Consolidated timeout policy (single source of truth)

Several timeouts already existed scattered across the original docs. This
table is now the canonical reference — if a future change needs to adjust
one of these, update it here.

| Moment | Timeout | Resulting behavior |
|---|---|---|
| Matchmaking queue (Quick Match / Next) | 20s | Friendly retry/cancel prompt |
| In-round, no gesture input from either player | 8s | Round resolves as a draw |
| Mid-match disconnect (reconnect grace period) | 20s | Graceful forfeit if not reconnected |
| Rematch request awaiting response | 15-20s | Auto-expires, requester's UI reverts to normal |
| Idle on results screen (no action taken at all) | 30-45s | Auto-return to Play tab home |

The idle-results-screen timeout is new and distinct from the rematch-request
timeout — it exists so a player who just closes their eyes/walks away
doesn't sit on a dead screen indefinitely; it's a much longer, gentler
timeout than the rematch-specific one.

## 5. Data model additions

- A lightweight ephemeral node for rematch requests (Realtime DB, not
  Firestore, since it's short-lived — same reasoning as the match event
  log): `/rematchRequests/{matchId}` with requester ID, target ID, and a
  server timestamp, cleared on accept/decline/timeout.
- No changes needed to the Friends request schema — Add Friend reuses it
  exactly as already specified.
- No changes needed to the report/block schema — reused as-is.

## 6. What this touches in the existing plans

- **`features/games/` results screen** (wherever the current match-result
  UI lives): add the three-action layout from Section 2, plus the
  report/block shortcut.
- **Friends feature:** no schema change, just confirms the existing
  add-friend and report/block flows are the ones reused here — no new
  Friends-tab work required.
- **Matchmaking:** Next reuses the exact existing queue logic — no new
  matchmaking code, just a second entry point into it.
- **Auth, Profile, onboarding, offline handling:** untouched by this
  section.

## 7. Tests to add

- Next correctly re-queues into normal matchmaking from the results screen,
  identical behavior to the Play tab's Quick Match.
- Rematch request: accept path skips the queue and starts a new match
  directly between the two specific players.
- Rematch request: decline, timeout, and requester-cancels-via-Next paths
  all correctly revert UI state with no dead ends.
- Add Friend from results screen produces the same pending-request state as
  the existing Friends-tab flow (shared code path, not a duplicate one).
- Idle-on-results-screen timeout correctly returns to Play tab home after
  the configured window.
- Report/block triggered from the results screen writes to the same
  backend record as the Friends-tab version (confirm no divergent/duplicate
  implementation was created).
