# Face Off — Multi-Game Expansion Plan (supersedes single-game scope)

This document corrects and extends the original master build prompt. The app
no longer hardcodes one game. It ships with a **pool of games**, one of which
is randomly selected per match. Read this fully before touching architecture
— it changes the `duel` feature, the data model, and (in smaller ways)
Friends and Profile. It does **not** change Auth.

---

## 1. Decisions made, so you don't have to re-litigate them

- **Game pool for v1: three games.** Face Off (built), Bow & Draw (new),
  Freeze (new). All three ship, but build in that priority order — see
  Section 8.
- **One game per match, chosen at match start, for the whole best-of-5.**
  No mid-match game switching. Re-teaching rules between rounds of the same
  match is bad pacing — rejected outright, don't revisit this.
- **Quick Match stays fully random-game.** Players do not pick a game before
  matchmaking. Reason: letting strangers pick a specific game before queueing
  would fragment the matchmaking pool into N smaller queues, which directly
  increases wait time — the opposite of what a fast matchmaking loop needs.
  Random-game-per-match keeps one unified queue.
- **Private/friend matches CAN specify a game.** When challenging a friend
  directly (Friends tab), the challenger picks a specific game, or "surprise
  me" for random. This is safe here because there's no shared queue to
  fragment — it's a 1:1 invite.
- **No backend-driven remote game catalog for v1.** The original blueprint
  explicitly deferred a Supabase-configured game manifest to v2 — that
  decision stands. The game pool is a **local, compiled enum/config list** in
  this version. Do not build remote game-config fetching now; it adds real
  complexity for zero v1 benefit with only 3 games.
- **Bow & Draw is stylized 2.5D, not a real 3D engine.** "3D" here means
  visual presentation (perspective-skewed target range, layered depth,
  parallax, drop shadows) achieved with Flutter transforms and layered
  sprites — not a physics-based 3D engine with camera/lighting. A real 3D
  engine (Flame 3D or similar) is a meaningful scope and performance risk on
  top of everything else already being built solo against this deadline.
  Flag true 3D as a v2/stretch idea in code comments; do not build it now.

---

## 2. The three games

### 2.1 Face Off (already built — reclassify, don't rewrite)
Face gestures only. `jawOpen` = fire, `browInnerUp` = dodge, smile-curvature
= crack (instant round loss, overrides everything, per the original state
machine — unchanged). Requires: **Face Landmarker** only.

### 2.2 Bow & Draw (new)
Hand gestures. Player pulls a hand back toward the shoulder/ear — distance
from an anchor point (detected shoulder or initial hand-rest position) maps
to draw power. An open-hand snap gesture releases the shot. A target
(stationary or slow-moving) sits in a stylized 2.5D range; hitting it scores
the round. In direct PvP framing, aim can instead target a weak point on the
opponent's avatar rather than a static bullseye — pick whichever plays
better once you have it running, both are valid, don't over-plan this before
building a first pass. Requires: **Hand Landmarker** (MediaPipe Tasks
Vision — same underlying pipeline as the Face Landmarker already
integrated, just a different task file, not a new framework).

Round win condition: best shot placement within a time window, or first to
land a clean hit — pick one and note the choice in a code comment; this is a
tunable, not a rule to agonize over before a first playable pass exists.

### 2.3 Freeze (new)
Motion-delta, not gesture classification. Music/tension builds, players move
loosely; on an unpredictable stop cue, any player whose tracked landmarks
(face + visible hand points, whatever's already streaming) shift more than a
configurable threshold during the freeze window loses the round. Requires:
**no new model** — reuses whichever landmarker(s) are already active for
that match's other detection needs, just measuring frame-to-frame delta
instead of semantic gestures.

---

## 3. Architecture changes

### 3.1 `GameModule` contract (new, in `lib/core/game_engine/`)

Every game implements a common interface so the match wrapper never needs
game-specific knowledge:

```
abstract class GameModule {
  String get id;
  Set<LandmarkerType> get requiredLandmarkers;   // e.g. {face} or {hand}
  Stream<GameSemanticEvent> get events;           // this game's own events
  void startRound();
  void resetRound();
  // Emits a RoundOutcome (winner/draw/reason) back to MatchController
}
```

Each game's domain layer owns translating raw landmark streams into its own
semantic events (`fireDetected`/`dodgeDetected`/`crackDetected` for Face Off;
`drawStarted`/`released`/`targetHit` for Bow & Draw; `motionExceeded` for
Freeze) — this preserves the isolate/state-machine separation already built
for Face Off, just generalized one level up. The state-machine-never-touches-
raw-landmarks rule from the original build prompt is unchanged and now
applies to all three games equally.

### 3.2 `MatchController` becomes game-agnostic

The existing best-of-5 orchestrator (currently living inside `duel/`) moves
to `lib/core/game_engine/` and stops knowing anything about Face Off
specifically. It holds a reference to whichever `GameModule` is active for
the current match, handles scoring, triggers `DuelVsTransition`, and drives
the results screen — identical responsibilities to before, just no longer
hardcoded to one game's rules.

### 3.3 Folder structure change

```
lib/
  core/
    game_engine/          -- NEW: GameModule contract, MatchController,
                              game pool config/enum, random-game selection
    gesture_engine/          -- unchanged, but now must support loading
                                 Face Landmarker and/or Hand Landmarker
                                 based on the active game's requirements
  features/
    games/                  -- NEW parent folder
      face_off/              -- renamed/moved from the old duel/ feature
        data/ domain/ presentation/
      bow_draw/               -- new
        data/ domain/ presentation/
      freeze/                  -- new
        data/ domain/ presentation/
```

Migrate the existing `duel/` feature into `features/games/face_off/` as a
rename+refactor, not a rewrite — the round state machine, false-start logic,
crack detection, and networking approach documented in the original master
prompt (Section 8 there) are correct and stay as-is; only the
game-agnostic parts (best-of-5 orchestration, match result handling) move
out into `core/game_engine/`.

### 3.4 Gesture engine: load only what the active game needs

Don't run both landmarkers all the time — that's wasted performance for no
benefit. At match start, once the game is selected (Section 4), initialize
only the landmarker(s) that game's `requiredLandmarkers` declares. Face Off
needs face-only; Bow & Draw needs hand-only; Freeze uses whatever's already
active for the match's context. This keeps the 30fps performance floor
realistic instead of paying for two detection pipelines when only one is
in use.

### 3.5 Random game selection must be server-authoritative

Same principle already applied to cue-fire timing: don't let each client
independently randomize which game to play, or the two clients can desync
on what they think they're playing. The random game pick for a Quick Match
is generated server-side (Cloud Function or a Realtime DB server-seeded
value) at the moment two players are paired, and both clients read the same
authoritative value.

---

## 4. Impact on Friends, Profile, and data model

### 4.1 Friends feature — one addition, nothing removed
The existing friend list, add-by-link/code, block/report/unfriend flows are
unaffected. **Add one new step to the "challenge a friend" flow**: before
sending the challenge, the challenger picks a specific game from the pool,
or "Surprise me" for a random pick (still server-authoritative, same
mechanism as 3.5). This is the only Friends-feature change.

### 4.2 Profile — stats need a per-game dimension
The stat grid (win streak, total matches, friends, win rate) currently
implies one flat number per stat. Change the underlying data model to store
**per-game stats plus an aggregate**, e.g.:

```
stats: {
  aggregate: { totalMatches, winRate, winStreak },
  faceOff:   { totalMatches, winRate, winStreak },
  bowDraw:   { totalMatches, winRate, winStreak },
  freeze:    { totalMatches, winRate, winStreak },
}
```

For v1, the Profile screen's main stat grid still shows the **aggregate**
numbers (no UI redesign needed there) — per-game breakdown is a detail view
reachable from the stat grid (tap through), not a new top-level screen. Keep
this simple; don't design a whole per-game stats dashboard now.

### 4.3 Leaderboard — aggregate only for v1
Keep the leaderboard ranked by aggregate score (e.g., total round wins
across all games), matching the original blueprint's podium component
as-is. Per-game leaderboards are a v2 nice-to-have, not a v1 requirement —
don't build the tab/filter UI for it now.

### 4.4 Firestore/Realtime DB schema additions
- `matches/{matchId}` documents need a new `gameId` field recording which
  game was played (set by the server-authoritative pick in 3.5).
- User profile documents need the nested per-game stats shape from 4.2
  instead of a flat stats object.
- No changes needed to the friend-request, block, or report schemas.

### 4.5 Auth — no changes
Google/Apple sign-in, Firebase Auth wiring, and the account creation flow
are entirely unaffected by this expansion. Do not touch `features/auth/`
for this work.

### 4.6 Onboarding — one message added, not a redesign
Don't attempt to teach all three games' rules during first-launch
onboarding — that's tutorial overload before a player has even played once.
Add a single showcase step (or a line of copy on the Play tab) communicating
"every match is a surprise — a new game each time," and let each
**individual match's own pre-round moment** carry that specific game's
quick rules (a short contextual card shown right after matchmaking confirms,
before the `DuelVsTransition` plays). The original three-step showcaseview
sequence (quick-match button, add-friend, subscription entry) is otherwise
unchanged.

---

## 5. Monetization — this actually gets stronger, not more complicated

The original plan's cosmetic-IAP-plus-optional-subscription model still
holds, with one clarification: split cosmetics into **universal** (profile
avatar skin, victory animation — apply across any game) and **game-specific**
(arrow skins only meaningful in Bow & Draw, face filters only in Face Off).
Both are one-time purchases, same as before, just tagged with an optional
`applicableGameId` field instead of always being global.

More importantly: "Face Off Plus" subscription's existing "early access to
new cosmetics/modes" benefit now has real teeth, because there's an actual
expanding game library to be early-access to — this is a stronger, more
literal HAMM pitch than the single-game version ever was. No structural
change needed, just note this in the submission writeup later.

---

## 6. What does NOT change

- The Face Off round state machine's internal rules (false start, crack
  override, dodge window, simultaneous-crack draw handling) — untouched.
- The signaling approach (event-sourced Realtime DB log, server timestamps
  for all authoritative timing) — untouched, and now reused for Bow & Draw
  and Freeze's own round resolution.
- Auth, onboarding's core shell, offline handling, and the app's 3-tab shell
  — untouched.
- Feature-First Clean Architecture, the 300-line file cap, 120-column
  format, const/isolate discipline — all still apply to every new file
  written for this expansion, no exceptions.

---

## 7. Tests to add (extends, doesn't replace, the original Section 8.7 tests)

- `GameModule` contract compliance tests for all three games (each responds
  correctly to `startRound`/`resetRound`, emits well-formed events).
- `MatchController` tests using a fake `GameModule` to confirm it's truly
  game-agnostic (best-of-5 scoring works identically regardless of which
  game is plugged in).
- Server-authoritative random game selection: test that both simulated
  clients receive the identical game ID for a given match.
- Bow & Draw round-logic unit tests (draw-power mapping, release detection,
  hit resolution) — same rigor as the original Face Off test list, adapted.
- Freeze motion-delta threshold tests, including a boundary test at the
  threshold edge (same spirit as the original crack-detection jitter-window
  boundary test).

---

## 8. Build order, given the calendar

1. `GameModule`/`MatchController` refactor first — migrate Face Off into
   the new shape before writing a single line of a new game. This is cheap
   now and expensive later; do not skip or reorder this.
2. Bow & Draw second — most differentiated from Face Off, closest to the
   original standout pitch.
3. Freeze third, only if time remains after Bow & Draw is solid and tested.
   If the calendar is tight when you get here, shipping two well-built games
   beats shipping three rough ones — say so explicitly if this tradeoff
   point is reached, don't silently cut corners on Bow & Draw to force
   Freeze in.
