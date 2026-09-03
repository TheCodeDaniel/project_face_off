# Face Off — build reference

Flutter party game: two players duel via real-time face-gesture tracking (no video sent, only
semantic gesture events). Source specs: `docs/face-off-01-design-blueprint.pdf` (design/IA) and
`docs/face-off-02-claude-code-master-prompt.pdf` (engineering build order). This file is the
running source of truth for decisions made while building — read it before touching architecture,
theming, or the duel state machine.

## Hard engineering rules (apply to every file)

1. **Feature-First Clean Architecture** — each feature under `lib/features/<name>/` with its own
   `data/`, `domain/`, `presentation/`. Shared code only in `lib/core/`. A feature never imports
   another feature's internals — cross-feature comms go through `lib/core/` contracts/providers.
2. **300-line hard cap** per file/class. Extract sub-widgets into `presentation/widgets/` with
   descriptive names (never `part1`/`part2`). Not enforced by tooling — check manually before
   finishing a file.
3. **`dart format --line-length=120`** before every commit (configured in `analysis_options.yaml`
   / `.dart_format`).
4. **State management: Riverpod.** Prefer `AsyncNotifier`/`Notifier` over legacy `StateNotifier`.
   No `setState` outside purely local ephemeral widget state.
5. **`const` everywhere legal.**
6. **Scoped rebuilds** — `Consumer`/`ref.watch` as tight as possible, never a whole-screen
   `Consumer`. Independently-animating subtrees (counters, avatar reactions, timers) wrapped in
   `RepaintBoundary`.
7. **Isolates for heavy per-frame math** (blendshape thresholding, motion deltas) — via
   `compute()` or a long-lived `Isolate`, never on the UI isolate.
8. **Tests are part of "done"** — domain logic (esp. the duel state machine) gets unit tests,
   widgets get at least a smoke test.

## Design system

Two `ThemeExtension`s, no raw hex colors outside `lib/core/theme/`:

- **LobbyPalette** (Play/Friends/Profile): gradient violet `#5B2A9E` → magenta `#C6339E` → orange
  `#F2793E`, cream cards, coin-gold accent `#FFC94A`.
- **MatchPalette** (duel screen only): near-black navy `#0A0E27` → indigo `#1B1F4B`, neon violet
  `#8B5CF6`, neon cyan `#4CD9E8` (dodge/success), hot red `#FF4D6D` (hit/loss).

Core reusable widgets live in `lib/core/widgets/`, one file each: `GradientScaffold`, `CoinBadge`,
`PodiumLeaderboard`, `RoomCard`, `PinCodeEntry`, `ActivityToast`, `CollapsiblePanel`, `StatTile`,
`DuelVsTransition`, `PrimaryPillButton`, `SecondaryPillButton`.

**Typography** (`google_fonts`, via `AppTextStyles`): three fonts, each with a job — Fredoka
(bold/rounded) for display & headline text, Plus Jakarta Sans (clean geometric) for body & label
text, Space Grotesk (tabular figures) for scores/coins/timers. Never reach for `GoogleFonts.*`
directly outside `lib/core/theme/app_text_styles.dart` — always go through `AppTextStyles`.

**Icons** (`hugeicons`, via `AppIcon`): the stroke-rounded hugeicons set is the only icon language
in the app — no `Icons.*` (Material icon font) anywhere outside legacy/system chrome. Use
`AppIcon(HugeIcons.strokeRoundedX, ...)` (a thin wrapper in `lib/core/widgets/app_icon.dart`), not
`HugeIcon` directly, so there's one seam if the icon package ever changes. Widgets that take an
icon parameter type it `List<List<dynamic>>?` (hugeicons' `IconData`-equivalent), not `IconData?`.

**`FloatingNavBar`** is glassmorphic (`BackdropFilter` blur + translucent white) rather than a flat
card, and icon-first: unselected tabs show icon only, the selected tab grows an inline label inside
an accent-colored pill. This was a deliberate revision after the first pass shipped a plain white
bar with icon+label on all three tabs — too text-heavy against the gradient, not "glassy" per
the design ask.

**`SecondaryPillButton`** ("How to Play" etc.) is a translucent white/frosted pill, not an outline
in `LobbyPalette.gradientStart`. The outline version was nearly invisible — a deep-violet border
has too little contrast against the violet→magenta→orange gradient it sits on at almost every use
site. Frosted white reads clearly at any point on the gradient.

## Duel game engine (the core of the app)

- Best of 5 rounds, first to 3 wins.
- Round state machine (`lib/features/duel/domain/round_state.dart`) is a sealed class:
  `Neutral → CueArmed → CueFired → ResolvingRound → RoundResult → (next round | MatchResult)`.
- Crack detection runs continuously across all phases and overrides everything (instant loss);
  simultaneous cracks within 150ms → draw, replay round.
- Cue delay is server/authoritative-seeded, 1000–4000ms. All timing decisions use the
  authoritative fire timestamp, never client `DateTime.now()`.
- False start = instant loss the moment the early input is received.
- Dodge window ≈400ms from attacker's server-timestamped fire event; per the spec, a clean dodge
  resets to an active exchange (NOT an instant round win for the dodger) — this is a documented
  tunable, implemented behind `RoundRules.dodgeEndsRoundOnSuccess` (default `false`) so it's a
  one-line flip during playtesting.
- Round timeout (8s post cue-fire with no fire from either side) → draw.
- State machine only ever consumes semantic events (`fireDetected`, `dodgeDetected`,
  `crackDetected`) — never raw blendshape numbers. That separation is what makes it unit-testable
  without a camera or Firebase (see `test/features/duel/domain/`).

## What's stubbed pending your credentials

These need accounts/config only you can provide — implemented behind clean interfaces so the rest
of the app builds and runs today, but not live-wired:

- **Firebase** (`firebase_auth`, `cloud_firestore`, `firebase_database`) — needs
  `flutterfire configure` run against your Firebase project. Auth/profile/matchmaking/signaling
  code is written against repository interfaces in each feature's `data/`; swap in real
  implementations once `firebase_options.dart` exists.
- **RevenueCat** (`purchases_flutter` + RevenueCat Ads) — needs your API keys and an Offerings
  catalog configured in the RevenueCat dashboard before the store/paywall can fetch real products.
- **MediaPipe Face Landmarker** — `lib/core/gesture_engine/` defines the blendshape stream
  interface and a fake generator for tests/dev; the real platform-channel implementation needs
  on-device validation of blendshape output (`browInnerUp`, `jawOpen`, mouth-curvature) before
  committing to a package vs. hand-rolled channel, per the master prompt's own instruction not to
  assume.

## Build order (from master prompt, keep committing per section)

Scaffold → design system → app shell → auth/onboarding → Play/matchmaking → duel engine → Friends
→ Profile → monetization → offline handling → performance pass.
