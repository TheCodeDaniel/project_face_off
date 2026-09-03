# Face Off — build reference

Flutter party game: two players duel via real-time face-gesture tracking (no video sent, only
semantic gesture events). Source specs: `docs/face-off-01-design-blueprint.pdf` (design/IA) and
`docs/face-off-02-claude-code-master-prompt.pdf` (engineering build order). This file is the
running source of truth for decisions made while building — read it before touching architecture,
theming, or the duel state machine.

**App identity**: display name "Face Off", package ID `com.faceoffgame.mobile` (Android
`applicationId`/`namespace`, iOS `PRODUCT_BUNDLE_IDENTIFIER` — set on both `Runner` and
`RunnerTests`). The Dart package name (`pubspec.yaml`'s `name:`, used in every
`package:project_face_off/...` import) is a separate, unrelated thing and stays as-is — renaming it
would mean touching every import in the project for no real benefit. App icon source lives at
`assets/images/face-off-icon-1024.png` (1024×1024, no alpha — required for iOS); regenerate all
platform icon sets with `dart run flutter_launcher_icons` after changing it.

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
9. **`Navigator.of(context, rootNavigator: true)` for anything that must cover the whole shell** —
   modals (`showModalBottomSheet`) and full-screen routes pushed from inside a tab. Each tab has its
   own nested `Navigator` (rule 1 of Section 5 below), which `AppShellScreen` paints as a Stack
   sibling *before* `FloatingNavBar`; a sheet or route pushed on that nested Navigator renders
   underneath the nav bar instead of covering it. Hit this bug twice already (`HowToPlaySheet`, then
   the whole matchmaking→duel push chain) — check this first if something renders behind the nav bar.
   Only the *first* push in a chain needs `rootNavigator: true` explicitly; everything pushed from
   inside a screen that's already on the root Navigator inherits it via plain `Navigator.of(context)`.
10. **Timer-driven Riverpod controllers use `clock.now()` (package:clock), never raw
    `DateTime.now()`** — `package:fake_async`'s `fakeAsync()` fakes `package:clock`'s ambient clock
    automatically (`withClock` under the hood), which is what makes `DuelController`'s cue/dodge/
    round-timeout `Timer`s deterministically testable in virtual time. Raw `DateTime.now()` would
    still return real wall-clock time inside a `fakeAsync` zone and silently break the test's timing
    assumptions. Pure domain logic (`DuelRoundEngine`) stays timestamp-agnostic regardless — it only
    ever receives `DateTime`s as parameters, never reads the clock itself.

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

## Onboarding & Auth (Section 6)

- `AuthRepository` (`lib/features/auth/domain/`) is the contract the whole app depends on;
  `FakeAuthRepository` (`lib/features/auth/data/`) backs it until Firebase exists — sign-in always
  succeeds after a simulated delay, so the full onboarding → sign-in → shell flow is exercisable
  today (see `test/app_root_test.dart`). Swap the `authRepositoryProvider` override for a
  Firebase-backed implementation once `flutterfire configure` has been run; `AppUser`'s field set
  deliberately mirrors Firebase Auth's `User` so that swap is a data-mapping change, not an API one.
- `AppRoot` (`lib/main.dart`) gates the shell on `authStateProvider`: signed in → `AppShellScreen`;
  signed out + never onboarded → `OnboardingScreen` (full welcome sequence ending in sign-in);
  signed out + already onboarded → the compact `SignInScreen`. "Onboarding seen" and "tour seen"
  are both persisted locally via `shared_preferences` (`LocalOnboardingRepository`), independent of
  auth state, so neither replays after the first session even offline.
- **No Lottie assets exist yet** (no design files were provided) — `OnboardingIllustration`
  (`lib/features/onboarding/presentation/widgets/`) renders an animated icon-on-glass illustration
  instead and is the single documented drop-in point: swap its body for `Lottie.asset(...)` once
  real `assets/lottie/*.json` files exist, no other file needs to change.
- **Product tour simplification**: the master prompt asks for a `showcaseview` tour highlighting
  the Play tab's quick-match button, the Friends tab's add-friend action, and the Profile tab's
  subscription entry point — three targets on three different tabs. Cross-tab showcasing would
  require the shell to programmatically switch tabs mid-tour, which added real complexity for a
  polish feature, so the shipped version showcases three targets all reachable from the Play tab:
  the Quick Match button plus the Friends and Profile nav items themselves (as the discoverable
  entry points into those sections). `TourKeys` (`lib/core/onboarding_tour/`) holds the shared
  `GlobalKey`s so `app_shell` and `play` don't reach into each other's internals to wire it up.

## Play tab & matchmaking (Section 7)

- `MatchmakingRepository` (`lib/features/play/domain/`) + `FakeMatchmakingRepository` follow the
  same pattern as auth: a queue stream that starts `MatchmakingSearching` and resolves to exactly
  one of `MatchmakingFound`/`MatchmakingTimedOut`. `MatchmakingController` is a `Notifier` (not
  `AsyncNotifier` — the state is a plain sealed class, no async-value wrapping needed) that owns
  the subscription and exposes `startQueue()`/`cancelQueue()`.
- `MatchmakingScreen` is pushed onto the Play tab's own nested `Navigator` (per Section 5's
  per-tab-back-stack rule), starts the queue on `initState`, and switches on `MatchmakingState` —
  cancel is always reachable, timeout gets a friendly retry/cancel prompt, never a bare spinner.
- On `MatchmakingFound`, `MatchFoundScreen` plays the already-built `DuelVsTransition` (Section 4)
  then hands off to `DuelScreen` (rest of Section 8, now built — see below).
- `onlineCountProvider` and `MatchHistoryTeaser` are placeholders (fluctuating fake count / empty
  state) until Firebase presence tracking and match-history write-back exist — both documented
  inline. Note the online-count `Timer.periodic` is cancelled explicitly via `ref.onDispose`; an
  `async*` generator looping on `Future.delayed` instead leaves a dangling platform timer behind on
  provider disposal (surfaced as a failed widget-test assertion — worth remembering for any other
  "tick forever" provider added later).

## Live duel screen (rest of Section 8)

- `DuelController` (`lib/features/duel/presentation/`) is the Riverpod `Notifier` that drives one
  live match against `DuelRoundEngine`: arms/fires the cue on a real `Timer`, schedules the
  dodge-window/round-timeout/simultaneous-crack-window checks (`checkDodgeWindowElapsed` etc. from
  the engine), and auto-advances through the 2.5s recap pause between rounds. Uses `clock.now()`
  throughout, never `DateTime.now()` — see engineering rule 10 above.
- **No camera or opponent networking exists yet** (needs the real MediaPipe gesture engine and
  Firebase Realtime DB signaling — see "What's stubbed" below). Both players auto-confirm "neutral"
  immediately for the same reason. In their place, `DevGestureControls`
  (`lib/features/duel/presentation/widgets/`) is a **temporary local test harness**: Fire/Dodge/
  Crack buttons for *both* "You" and the opponent, so one device can drive a full, real playthrough
  of the round state machine — false starts, dodges, cracks, timeouts, best-of-5 — without a second
  device or a camera. Delete this widget once the real gesture engine and signaling replace
  `DuelController`'s manual triggers and local timers.
- `duelOutcomeMessage()` turns a resolved `RoundOutcome` into the `ActivityToast` recap text the
  spec calls for ("You dodged in time!" etc.), phrased from the local player's perspective.
- Tested with `package:fake_async` (`test/features/duel/presentation/duel_controller_test.dart`) —
  covers cue-arm→fire, a resolved fire-with-no-dodge, a same-instant dodge reset, round timeout, and
  auto-advance to the next round. One gotcha hit while writing these: the cue delay is *randomized*
  (1-4s), so asserting on the state at one fixed total-elapsed duration is flaky — the random draw
  plus the fixed 2.5s recap can land the check either mid-recap or already advanced to round 2
  depending on the draw. Fixed by observing the state transition via `container.listen` instead of
  snapshotting a timing-dependent instant; keep that pattern for any similarly randomized-delay test.
- **Quit-mid-match confirmation**: `DuelScreen` wraps its body in a `PopScope(canPop: false, ...)` —
  any attempt to leave (system back gesture/button, or an in-app pop) while a round is still live
  shows `QuitMatchDialog` ("You'll forfeit this duel if you leave now.") instead of exiting
  immediately; once the match has reached `MatchResultRoundState`, leaving is free. `duelControllerProvider`
  is `NotifierProvider.autoDispose` specifically so that actually leaving (confirmed quit, or a
  normal match-end exit) tears down `DuelController`'s cue/round-timeout `Timer`s — otherwise an
  abandoned match's timers would keep firing into a screen nobody's watching.
  - **Test gotcha**: `container.read(provider.notifier)` does *not* keep an `autoDispose` provider
    alive — with nothing holding a listener, Riverpod disposes it almost immediately, so a second
    `container.read` sees a freshly-rebuilt (reset) state. The real `DuelScreen` is fine because its
    `ref.watch` in `build()` is a live listener for as long as the screen is mounted. Tests need an
    explicit `container.listen(provider, (_, _) {})` to reproduce that — see
    `test/features/duel/presentation/duel_controller_test.dart`.
  - **Widget-test gotcha**: verifying `PopScope` behavior against a screen mounted under its own
    nested `Navigator` (as in `test/features/duel/presentation/duel_screen_quit_test.dart`) needs
    `find.byType(Navigator).last`, not `.first` — `MaterialApp` builds its own outer `Navigator`
    around `home`, so `.first` grabs that one instead of the inner one actually hosting the screen
    under test, and `maybePop()` on the wrong Navigator is a silent no-op.

## Friends tab (Section 9)

- `FriendsRepository` (`lib/features/friends/domain/`) + `FakeFriendsRepository` follow the same
  pattern as auth/matchmaking: seeded with a couple of friends and one incoming request so the UI
  has something to show in dev builds. Real blocking needs enforcement on *both* sides — client-side
  (immediate UX, already implemented) and server-side (a security rule / Cloud Function check at
  matchmaking time so a block can't be bypassed by a modified client) — the server half is naturally
  out of scope until Firebase exists.
- Add-friend reuses `PinCodeEntry` (Section 4) for entering a friend's code; any 6-digit code
  succeeds against the fake repo since there's no real backend to resolve one against yet.
  `sendRequestByCode` deliberately does **not** mutate the local player's own incoming-requests
  list on success — a real outgoing request lands in the *other* person's inbox, not yours, and
  with only one simulated user there's no second inbox to add it to. An earlier version got this
  backwards (added a bogus request from a hardcoded "Zara" as a side effect of sending one), which
  made a stray incoming request appear right after tapping "send" — caught from a screenshot, fixed,
  and pinned down with a regression test. `AddFriendSheet`'s success state is a proper icon+text
  confirmation (`AnimatedSwitcher` crossfade, auto-dismiss after ~1.3s) rather than a bare line of
  green text swapped in for the PIN boxes — the first version left an ugly abrupt layout jump.
- `FloatingNavBar`'s Friends icon carries a live badge from `incomingRequestsCountProvider` — this
  is why it had to become a `ConsumerStatefulWidget`.
- Report flow requires picking one of a fixed `ReportReason` (master prompt Section 9 — not just
  free text) plus an optional detail field; `FakeFriendsRepository.reportUser` is a no-op stand-in
  for the real Firestore `reports` collection write. No automated moderation pipeline for v1 either
  way — just reliable capture.
- **Test gotcha**: don't subscribe to an `async*`-backed repository stream (`friendsStream.skip(1)
  .first`) immediately before triggering a synchronous mutation and expect to catch the resulting
  event — the generator's body doesn't start running until a microtask turn *after* something
  listens, so a mutation that fires synchronously in between can be added to the broadcast
  controller before the generator has subscribed to it, and a broadcast controller drops events with
  no listener. Simplest fix: `await` the mutation, then take a fresh `.first` off a new subscription
  — the generator always yields the current snapshot immediately, so no race. See
  `test/features/friends/data/fake_friends_repository_test.dart`.

## What's stubbed pending your credentials

These need accounts/config only you can provide — implemented behind clean interfaces so the rest
of the app builds and runs today, but not live-wired:

- **Firebase** (`firebase_auth`, `cloud_firestore`, `firebase_database`) — needs
  `flutterfire configure` run against your Firebase project. Auth/profile/matchmaking/signaling
  code is written against repository interfaces in each feature's `data/`; swap in real
  implementations once `firebase_options.dart` exists. `AuthRepository`/`FakeAuthRepository` above
  is the auth half of this.
- **RevenueCat** (`purchases_flutter` + RevenueCat Ads) — needs your API keys and an Offerings
  catalog configured in the RevenueCat dashboard before the store/paywall can fetch real products.
- **MediaPipe Face Landmarker** — `lib/core/gesture_engine/` defines the blendshape stream
  interface and a fake generator for tests/dev; the real platform-channel implementation needs
  on-device validation of blendshape output (`browInnerUp`, `jawOpen`, mouth-curvature) before
  committing to a package vs. hand-rolled channel, per the master prompt's own instruction not to
  assume.
- **Lottie onboarding illustrations** — no design assets provided; see `OnboardingIllustration`
  above for the drop-in point once real `.json` files exist.

## Build order (from master prompt, keep committing per section)

Scaffold → design system → app shell → **auth/onboarding (done, against a fake auth repo)** →
**Play/matchmaking (done, against a fake matchmaking repo)** →
**duel engine (done — playable end-to-end via the dev gesture-controls harness, pending real
camera + networking)** → **Friends (done, against a fake friends repo)** → Profile → monetization →
offline handling → performance pass.
