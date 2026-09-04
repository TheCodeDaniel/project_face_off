# Face Off — Game UI, Gesture Tracking & Backend Guideline

This covers the two remaining pieces: the visual/UI layer for all three games,
and the backend, which is now a **hybrid** (Firebase Realtime DB + Postgres/
Supabase) rather than the original all-Firebase plan. Read fully before
touching either — this section corrects the data layer, so getting it wrong
here is expensive to unwind later.

---

## 1. Visual style direction — priorities, in order

**Shape and tracking correctness first. Art polish last, and is explicitly
optional for v1.** A game that looks plain but tracks the hand accurately and
reads clearly beats a pretty one that misfires. Do not spend time on texture
detail, lighting polish, or asset variety before the underlying tracking and
silhouette legibility are solid.

**Reference points, and what to actually take from each:**

- **HD-2D layering (flat character/prop sprites inside a real-feeling 3D
  environment, with proper cast shadows and depth-sorted layers)** — this is
  the core visual technique for Bow & Draw's range and Freeze's stage. Build
  it as: a far background layer (slow parallax), a mid layer (target/props,
  normal parallax), a near layer (foreground elements, fast parallax), each
  a flat 2D sprite positioned and scaled via `Transform`/`Matrix4`, not
  actual 3D geometry. Depth is sold by parallax speed + scale + a simple
  drop shadow under each sprite, not by real perspective projection.
- **First-person archery framing (forearm + bow in the lower frame, target
  in the distance)** — this is the camera framing for Bow & Draw specifically.
  The player's own drawing hand does not need to be rendered (it's real,
  off-screen, doing the gesture) — render a stylized bow-and-arrow rig in
  the same first-person position instead, whose draw-back animation is
  driven directly by the live gesture data (draw distance = bow-pull
  animation amount). This is the single most important visual feedback
  loop in the game — the player must see their real pull gesture reflected
  instantly in the bow's draw animation, or the controls will feel broken
  even if tracking is technically accurate.
- **Floating hit/score numbers and rarity-style callout labels (looter-shooter
  HUD language)** — reuse this pattern for hit feedback: a number or short
  label (`+120`, `Bullseye!`) that spawns at the hit point and floats
  upward while fading, matching the existing `ActivityToast` pattern's
  energy but as a world-space floating element rather than a fixed toast.
- **Simple capsule HUD with a portrait + bar (top-left corner)** — reuse the
  existing lobby HUD language (`CoinBadge`-style capsule) for score/health
  displays inside a match, rather than inventing a new HUD shape per game.
  Consistency across the three games' HUDs matters more than any one of
  them looking distinct.

**Explicitly do not attempt:** real 3D asset rendering, dynamic lighting,
particle-heavy effects, or any WebView/engine-based rendering. If a screen
is taking real effort to make "look 3D," that's a sign to fall back to a
flatter, simpler layered composition instead — flat-but-clear beats
technically-ambitious-but-broken every time here.

---

## 2. Gesture tracking setup — Hand Landmarker (new, alongside existing Face Landmarker)

Follow the same integration pattern already working for the Face Landmarker
— platform-channel wrapper per platform, not a shaky third-party Flutter
package, for consistency with what's already built and tested.

**Model:** MediaPipe Tasks Vision `hand_landmarker.task`. Confirm the current
download URL and model variant (full vs. lite) against MediaPipe's live
docs before hardcoding a version — model file names/versions do change.

**Configuration:**
- `numHands: 1` — only the drawing hand needs tracking; the other hand is
  assumed to be holding the phone. Do not track both hands for v1, it adds
  cost for no gameplay benefit here.
- `runningMode: LIVE_STREAM` (not `VIDEO` or `IMAGE`) — this is the mode
  built for continuous camera-feed input with a result callback, matching
  how the Face Landmarker is already wired.
- Set `minHandDetectionConfidence`, `minHandPresenceConfidence`, and
  `minTrackingConfidence` conservatively (e.g., starting around 0.5-0.6) and
  tune upward only if false-positive gesture triggers show up in testing —
  don't guess a final value before real-device testing exists.
- Delegate to GPU if the platform/device supports it, falling back to CPU —
  same tiering logic already specified for device-capability handling in
  the original performance section.

**Semantic event mapping (domain layer, same separation rule as Face Off):**
- Establish an **anchor point** the moment the hand is first detected at
  rest (before any draw begins) — this is the zero-power reference, not a
  fixed screen coordinate, since phone angle/hold position varies per
  player.
- `drawUpdate(power: 0.0-1.0)` — continuous event as the hand's distance
  from the anchor increases, clamped and normalized against a calibrated
  max-draw distance (a reasonable default, tunable, not something to derive
  from a single guess).
- `released` — fires on a rapid drop in draw distance combined with a
  hand-openness change (finger landmark spread increasing sharply), not on
  distance alone, to avoid false releases from small hand jitter.
- `drawCancelled` — if the hand is lost/occluded mid-draw for more than a
  short grace window, cancel the draw cleanly rather than leaving the state
  machine stuck waiting for a release that may never come.
- As with Face Off, the round state machine and UI never touch raw hand
  landmarks directly — only these semantic events, computed on the isolate,
  exactly as the isolation rule already requires.

**Freeze reuses whatever landmarker(s) are already active for that match**
(face and/or hand, whichever the paired game needs) and simply measures
frame-to-frame landmark position delta — no new model, no new semantic
event contract beyond `motionExceeded`, as already specified in the
multi-game plan.

---

## 3. Backend architecture — the hybrid split (read carefully, this replaces the original single-Firebase plan)

**Firebase Realtime Database keeps everything ephemeral and latency-
sensitive, unchanged from what's already built:**
- Matchmaking queue
- In-match event log (the append-only event-sourced approach already
  working for Face Off's round state machine)
- Rematch request nodes
- Presence/online-status signaling

**Do not move any of the above to Postgres.** They're ephemeral,
high-frequency, small-payload, and Realtime DB is the right tool for them —
this part of the original plan was correct and stays exactly as built.

**Postgres (via Supabase) takes over everything durable and relational:**
- `users` — profile data (display name, avatar, tier/level)
- `user_game_stats` — the per-game-plus-aggregate stats shape from the
  multi-game plan (one row per user per game, plus an aggregate view/query
  rather than a duplicated aggregate row, if that's a cleaner fit for a
  relational schema — use your judgment on view vs. stored aggregate, just
  keep the two in sync)
- `friendships`, `friend_requests`, `blocks`, `reports` — relational data
  with real query needs (has this user blocked that user, list pending
  requests) that Postgres handles more naturally than Firestore's
  document model does
- `matches` — durable match history/results (final score, winner, gameId,
  timestamp) written once a match concludes — this is the durable record;
  the live event-by-event data stays in Realtime DB and is not migrated
  here
- `cosmetics_owned`, `subscriptions_cache` — entitlement records, kept in
  sync with RevenueCat via webhook rather than trusting client-reported
  purchase state

**Auth stays exactly as built — Firebase Auth (Google/Apple), untouched.**
Supabase's row-level security should key off the Firebase UID (passed
through as a custom claim or a synced foreign key), not a second parallel
identity system. Do not introduce Supabase Auth alongside Firebase Auth —
that would mean two identity systems for one user, which is unnecessary
complexity and a real bug surface (token mismatches, sync drift). If
wiring Firebase UID → Postgres row-level security needs a specific
Supabase pattern (custom JWT, external auth integration), verify the
current recommended approach against Supabase's live docs rather than
assuming — their auth integration docs change.

**Migration note:** if any Firestore code already exists for the data now
listed under Postgres above (profiles, friends, stats), that code needs to
be replaced, not layered on top of — don't end up with the same data
half-written to both Firestore and Postgres. Confirm what already exists
before writing new data-layer code, and remove the Firestore version
cleanly as part of this change rather than leaving dead code behind.

---

## 4. Guardrails — what NOT to touch while doing this work

- The Face Off round state machine's internal rules (false start, crack
  override, dodge window, simultaneous-crack draw handling) — no changes.
- The Realtime DB signaling approach and server-timestamp-authority
  principle — no changes, and the same authority principle now applies to
  Bow & Draw's draw/release timing and Freeze's stop-cue timing.
- Firebase Auth and the onboarding flow — no changes.
- The 300-line file cap, 120-column format, Feature-First folder structure,
  const/isolate discipline — apply to every new file in this section, same
  as everything before it.

## 5. Suggested order for this section

1. Stand up the Postgres schema and data-access layer first, migrating any
   conflicting Firestore code as you go — get the data layer solid before
   building UI on top of it.
2. Hand Landmarker integration and semantic event pipeline for Bow & Draw,
   validated standalone (no UI yet) the same way Face Landmarker was
   validated in the original Day 1-2 checkpoint — confirm tracking quality
   on a real mid-range device before building the visual layer on top of
   possibly-unreliable input.
3. Bow & Draw's layered 2.5D visual layer, once gesture input is confirmed
   solid.
4. Freeze's UI (simpler, reuses existing tracking, no new model).
5. Pass over all three games' HUDs for the shared capsule/floating-number
   visual consistency described in Section 1.
