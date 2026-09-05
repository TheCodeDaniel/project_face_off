# Target Pop Duel — Master Build Prompt for Claude Code (native 3D, single game)

Read this fully before writing any code. This supersedes all prior game-scope
docs: **Face Off is shelved, not deleted** — park its existing code clearly
(a separate branch or a clearly-marked `_archived/` note, not stripped out
destructively) in case it's revisited later as a different concept. **The
only game being built now is Target Pop Duel**, using native 3D via
`flutter_scene`. Simplify the multi-game `GameModule`/pool abstraction back
down to a single, direct game flow — don't maintain plugin architecture for
one game, that's cost with no current benefit. It can be re-generalized
later if a second game actually gets built.

---

## 1. The game

Two players, matched as before (Quick Match or friend challenge, same
matchmaking/queue system already built). Each plays on their own device, in
their own **fully independent, non-shared 3D scene** — Player A never sees
Player B's targets or camera, and vice versa.

- Each round spawns a fixed list of targets (start with 6) in the player's
  own scene, at varying depth/position, colored by player-slot identity
  (Player A's targets one color, Player B's the other — reuse the existing
  match-palette accent colors already established, `#8B5CF6` violet /
  `#4CD9E8` cyan, rather than introducing new red/blue if a simpler path is
  preferred; either is fine, pick one and be consistent).
- Targets move independently and locally — no networking needed for this,
  since neither player ever sees the other's targets. A simple per-target
  motion (gentle sine-wave bob plus a slow randomized waypoint drift within
  a bounded volume) is enough; don't over-engineer movement AI for v1.
- **Win condition: first player to pop every target in their list wins the
  round.** The only data that crosses the network per round is each
  player's "all targets cleared" completion event with a server timestamp
  (Realtime DB, same authority principle as everything else already built)
  — the server/backend compares the two completion timestamps to
  determine the round winner. If a player hasn't finished when the other
  does, the round ends immediately for both (don't make the trailing
  player keep playing a round that's already decided).
- Best-of-X match wrapper stays exactly as already built (best of 5, first
  to 3 round wins) — this part doesn't change.
- Round timeout: if neither player finishes within a reasonable window
  (e.g., 45-60s — longer than Face Off's 8s round timeout since this is a
  multi-target task, not a single reflex moment), resolve as a draw and
  add this to the existing consolidated timeout table from the post-match
  flow doc.

---

## 2. Package setup — flutter_scene

```
flutter pub add flutter_scene
dart run flutter_scene:init
dart run flutter_scene:skills
```

`init` sets up the asset pipeline (drop `.glb`/images under `assets/`, load
by source path — prefer this over runtime `.glb` parsing for anything
shipping with the app). `skills` installs the package's official agent
skills — **read and follow these once installed**, they exist specifically
so a coding assistant writes idiomatic Scene code instead of guessing, and
include a "run-settle-capture" verification loop methodology. Use that
loop for the spike test in Section 3 and for ongoing verification through
this build, rather than inventing a separate verification approach.

**Enable Flutter GPU** (required on every native platform, since Impeller
itself is already the default but Flutter GPU needs an explicit flag):
- iOS: `ios/Runner/Info.plist` → `<key>FLTEnableFlutterGPU</key><true/>`
- Android: `android/app/src/main/AndroidManifest.xml`, inside
  `<application>` → `<meta-data android:name="io.flutter.embedding.android.EnableFlutterGPU" android:value="true" />`

Confirm the Flutter SDK constraint is 3.47+ stable — this is a real,
current requirement, not a nice-to-have; verify the project's Flutter
version before adding the dependency.

---

## 3. Mandatory spike test — unchanged in spirit, now more concrete

Before building the real bow rig or targets: render a single primitive
(e.g., `CuboidGeometry` or `SphereGeometry` with `PhysicallyBasedMaterial`
— the package's default studio environment lights it with zero setup) and
drive its `position`/`rotation` from a fake, rapidly-changing input value
on a real cheap Android device. Confirm frame rate holds at the existing
30fps floor (60fps aspirational) and the motion tracks the fake input with
no perceptible lag, using the package's own run-settle-capture skill
methodology to verify rather than eyeballing it. Do not proceed to Section
4 until this passes on real Android hardware, not just iOS or a simulator/
emulator.

---

## 4. Input architecture — two independent channels

**Aim direction: device tilt/orientation (gyroscope), not touch.** As the
player physically tilts the phone, the in-scene camera (a
`PerspectiveCamera`) rotates to match, so tilting left pans the view/aim
left, as originally envisioned. Use a device-orientation/motion package
(verify current recommended package against pub.dev — `sensors_plus` or
similar, confirm it's actively maintained before adding it) feeding
filtered orientation deltas into the camera's rotation. Smooth/dampen the
raw sensor input (a simple low-pass filter) so the aim doesn't feel jittery
— raw gyroscope data is noisy and unfiltered values will feel worse than
the underlying tracking actually is.

**Draw power and release: Hand Landmarker via front camera, exactly as
already specified** in the gesture-tracking section of the prior guideline
— anchor point on first rest detection, continuous `drawUpdate(power)`,
`released` on rapid distance-drop plus hand-openness change, `drawCancelled`
on occlusion beyond a grace window. This is unchanged; it's a separate
input channel from the tilt-based aim, running concurrently.

**Hit resolution: hitscan raycast, not simulated arrow physics, for v1.**
On `released`, cast a ray from the camera's forward direction (screen
center) into the scene and test intersection against live target bounding
volumes — `flutter_scene` already supports pointer raycasting into the
scene, repurpose that same mechanism for a camera-forward raycast instead
of a screen-tap origin. This is simpler and more reliable than full
projectile physics with travel time and gravity, and keeps the two real
uncertainties (gesture tracking, tilt-based aim) from compounding with a
third (simulated arrow flight). Real physics-based arrow flight (via
`flutter_scene_rapier`) is a legitimate v2 enhancement, not a v1
requirement — note it as such in a code comment, don't build it now.

---

## 5. Scene content — keep it primitive-shape-based for v1

Use `flutter_scene`'s built-in geometry (`SphereGeometry` for
balloon-style targets, `BillboardGeometry` if a camera-facing flat sprite
reads better than a full sphere) with `PhysicallyBasedMaterial` — the
default procedural studio environment lighting means targets look
reasonable with zero custom lighting setup. Do not author custom 3D
assets or complex materials for v1; this is consistent with the
shape-and-tracking-correctness-over-art-polish priority already
established. Use the package's particle system for a pop effect on a
successful hit, and the existing floating-score-number/callout pattern
(as a Flutter widget overlay, or embedded on a 3D surface using the
package's Flutter-widgets-on-3D-surfaces feature if that reads better)
for hit feedback.

---

## 6. What stays exactly as already built

- Matchmaking, friend-challenge, rematch-request, add-friend, and
  report/block flows from the post-match flow doc — all game-agnostic,
  unaffected by this change.
- The hybrid backend (Firebase Realtime DB for ephemeral signaling,
  Postgres/Supabase for durable data) — unaffected, except `matches.gameId`
  now only ever records this one game.
- Firebase Auth, onboarding, offline handling, 3-tab shell — untouched.
- 300-line file cap, 120-column format, Feature-First structure, const/
  isolate discipline — apply throughout.

## 7. What to remove or simplify

- Collapse the `GameModule`/game-pool abstraction back to a single, direct
  match flow — remove the now-unnecessary game-selection/random-pick logic
  entirely (there's nothing to randomly select between anymore).
- Park Face Off's code clearly rather than deleting it outright.
- Drop any Freeze scaffolding if it exists — already cut previously.

---

## 8. Build order

1. Spike test (Section 3) — hard go/no-go gate, real Android hardware.
2. Gyroscope-driven camera aim, tested standalone for feel/smoothness
   before anything else depends on it.
3. Hand Landmarker draw/release pipeline, validated standalone (already
   mostly specified from the prior guideline — carry it over).
4. Per-player local target spawn/movement + raycast hit resolution,
   single-player feel first, no networking yet.
5. Networked completion-timestamp comparison for round-winner
   determination, layered on top of the working single-player loop.
6. HUD, particle pop feedback, and floating score numbers.
7. Full best-of-5 match wrapper + backend wiring (largely already built,
   just needs this game's data plugged in instead of Face Off's).

Report back after each numbered step, not just at the end — given how much
has shifted in this plan already, confirm each layer works before building
the next one on top of it.
