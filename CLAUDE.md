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
`DuelVsTransition`, `PrimaryPillButton`, `SecondaryPillButton`, `ShimmerCard`,
`LobbyConfirmationDialog`.

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

**`ShimmerCard`** (`lib/core/widgets/shimmer_card.dart`) is the drop-in replacement for a plain
`Container(decoration: BoxDecoration(color: palette.cardBackground, ...))` — every cream
tile/card/pill/dialog in the lobby register goes through it now (`StatTile`, `RoomCard`,
`CoinBadge`, `PodiumLeaderboard`'s rank rows, `LobbyConfirmationDialog`, the cosmetics tiles,
settings card, subscription card, friend list tile, FAQ tiles) instead of each one repainting a
flat cream box. It adds a rare diagonal silver-white sheen that sweeps across the surface (every
5-9s, randomized per instance so tiles on the same screen don't glow in lockstep) — a deliberate
"occasional," not constant, animation so the cream surfaces read as glossy rather than flat without
becoming a distraction. Uses a cancelable `Timer` (not `Future.delayed`, which can't be aborted in
`dispose()` and left a pending timer past teardown, failing `flutter_test`'s
"no pending timers" invariant on any screen using it) and wraps its own `RepaintBoundary` per
engineering rule 6. The large full-bleed bottom sheets (`HowToPlaySheet`, `AddFriendSheet`,
`FriendActionsSheet`, `ReportUserSheet`) deliberately keep their plain cream background rather than
adopting the sweep — a moving highlight across an entire modal's background, behind live form
controls, read as more distracting than glossy at that scale; the effect is reserved for bounded
tile/card/pill surfaces.

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
- **Launch splash**: `AnimatedSplashScreen` (`lib/core/widgets/`) is what `AppRoot` shows while
  `authStateProvider`/`hasSeenOnboardingProvider` are loading — a Netflix-style logo sting: near-black
  cinematic background (`MatchPalette.backgroundGradient`, reused here rather than the warm lobby
  gradient, for a more dramatic "studio ident" register), the app icon punches in with a bouncy
  scale-and-settle (`Curves.easeOutBack`), the "FACE OFF" wordmark fades up beneath it, then a single
  diagonal shine sweeps across the whole lockup once. Runs on one `AnimationController` (2.4s) inside
  a single `RepaintBoundary`/`AnimatedBuilder`. Deliberately **no `Opacity` widgets** except one
  (fading in the rasterized icon PNG, where there's no "color" to bake alpha into) — every other fade
  is baked directly into a color's alpha instead (`color.withValues(alpha: ...)`), and the shine sweep
  reuses the same translucent-gradient-overlay technique as `ShimmerCard` rather than a
  `CustomPainter`. `AppRoot` holds the splash for a **minimum** 2.4s via its own `Timer` regardless of
  how fast the providers actually resolve (against `FakeAuthRepository`'s near-instant resolve, the
  animation would otherwise get cut off mid-play on almost every launch), then `AnimatedSwitcher`
  crossfades into whichever screen comes next.
  - **Gotcha**: the splash's root widget must be a `Scaffold` (not bare `Material`/`DecoratedBox`) —
    two independent reasons. First, `Text` with no `Material` ancestor falls back to `WidgetsApp`'s
    debug default style (a loud yellow double-underline under every word) — easy to miss since it
    only shows up once you actually run the widget, not in `flutter analyze`. Second, and more
    subtly: `AppRoot`'s outer `AnimatedSwitcher` lays its child out via a `Stack` whose non-positioned
    children get *loose* constraints — a bare `Material`/`DecoratedBox` root shrink-wraps to its
    content's width (roughly the title text) instead of filling the screen, while `Scaffold`
    explicitly takes `constraints.biggest`, sidestepping that regardless of what its parent does.
  - **History**: the first version was a spiral-particles reveal; the second was a three-beat "glove
    clash" (two boxing gloves throwing jabs that bounce off each other before a final clash cracked
    the screen open, `SplashCrackPainter` drawing jagged fractures from the impact point, a nod to the
    Gogeta/Broly movie finale). Replaced at the user's request ("delete it, it's not good") with the
    current, simpler Netflix-style design. While building the glove-clash version, the iOS Simulator
    repeatedly rendered the right half of the screen solid black once the animation finished —
    reproduced after removing every candidate cause one at a time (`MaskFilter.blur`, every `Opacity`
    widget, a `Transform.translate` wrapping the scene, the `CustomPaint` entirely, `StrokeCap.round`),
    after a full `simctl shutdown`/`boot`, after fully quitting/relaunching `Simulator.app`, and on a
    completely fresh never-before-run simulator device — but rendered perfectly clean on `flutter run
    -d chrome` and, later the same session, on the iOS Simulator again via an independent debug
    session, suggesting a transient host GPU/WindowServer issue for that session rather than a code
    bug. If a similar full-screen visual corruption shows up again: try `-d chrome` first to rule out
    the widget tree before spending time bisecting widget code — it's a fast, independent renderer.
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
- **`showcaseview` upgraded 3.0.0 → 5.1.0** and migrated off the now-deprecated context-dependent
  `ShowCaseWidget` onto `ShowcaseView.register()`/`.get()`: `AppShellScreen` registers once in
  `initState` and starts the tour once via a single `initState`-scoped `addPostFrameCallback`,
  unregistering in `dispose` — no context threading, no re-triggering on tab-switch/rebuild the way
  the old `ShowCaseWidget.builder`-scoped trigger did. Worthwhile on its own, but **this was not
  what fixed the actual bug** — see below.
- **The real "tour flashes on screen for a frame then vanishes on every single launch" bug** lived
  in `AppRoot`'s `AnimatedSwitcher.layoutBuilder` (`lib/main.dart`), not in the tour code at all.
  That `layoutBuilder` exists to fix a *different*, earlier bug (screens shrinking to a fraction of
  the device width — see the splash section above) by wrapping each child in `Positioned.fill`. The
  first version of that fix didn't give those `Positioned.fill` wrappers a `key`. Mid-crossfade,
  `AnimatedSwitcher`'s Stack has two children (`[previous, current]`); once the ~400ms fade
  finishes and `previous` drops out, the list shrinks to `[current]` alone — at index 0 that's a
  *different* widget than what was there a frame earlier, and with no key on the `Positioned`
  wrapper to prove they're unrelated, Flutter's positional reconciliation tries to update the old
  element in place, finds the inner child's key doesn't match, and tears the whole subtree down and
  rebuilds it from scratch instead of reusing the element already mounted at the other index. For
  `AppShellScreen` that meant `initState()` — and everything it kicks off, including
  `ShowcaseView.register()` and the tour trigger — ran a **second time**, a beat after the first
  run had already started the tour successfully. The second `ShowcaseView.register()` silently
  replaced the first registration for that scope, orphaning the overlay the first instance had just
  shown. Confirmed by temporarily instrumenting `AppShellScreen` with `debugPrint`s and watching its
  tour-trigger method fire twice on a single fresh-install launch, and by stepping through a
  fresh-install run screenshot-by-screenshot to catch the exact frame it happened on (right at the
  crossfade's end, matching the theory exactly). **Fix**: give each `Positioned.fill` the wrapped
  child's own `key` (`previous.key` / `currentChild.key`) so Stack reconciles by identity instead of
  position — see the comment on that `layoutBuilder` for the full writeup.
  - **This is why `_maybeStartTour` still polls `ShowcaseView.isTargetRendered`** before calling
    `startShowCase`, even after the real fix above: that's a real, separate, minor race (the Play
    tab's nested `Navigator` can register its `Showcase` controller a beat after `AppShellScreen`'s
    own build), just not the one causing the dramatic flash-then-vanish symptom.
  - **Lesson for next time a screen's whole `State` seems to silently reset**: don't assume the bug
    is in the screen itself — check what's re-parenting it first. An unkeyed widget swapped into a
    list-based layout (`Stack`, `Column`, `Row`, `AnimatedSwitcher`'s own default `layoutBuilder`,
    any custom one) that changes length across rebuilds is a classic way to lose element identity
    silently, with no error, no warning, just a rebuilt subtree.
  - **`test/app_root_test.dart`'s existing test is the regression coverage** — it now asserts
    `find.text('Quick Match')` returns *exactly* 2 matches (the button's own label plus the tour
    tooltip's title) rather than the previous `findsWidgets`, which would have silently passed even
    with only the button's label left (i.e. even with the tour already dead) and so never actually
    proved the tour was still showing. Confirmed this catches the regression by reverting the `key:`
    fix locally and re-running the test — it failed with exactly 1 match, as expected.
- **Tour redesigned to look intentional, not like a bolted-on library default** — `tourShowcase()`
  and `tourActions()` (`lib/core/onboarding_tour/tour_style.dart`) give every `Showcase` a shared,
  on-brand look: frosted deep-violet tooltip (`LobbyPalette.gradientStart`), white
  title/description in `AppTextStyles`, backdrop blur, and global "Skip"/"Next"/"Got it" actions
  (frosted white / coin-gold) instead of the package's plain default white card with text-only
  buttons. "Skip" hides itself on the last step (`hideActionWidgetForShowcase: [TourKeys.profileNav]`)
  since there's nothing left to skip; "Next" swaps for "Got it" there — both are still just the
  `.next` action, since `ShowcaseView.next()` finishes the whole tour automatically once there's no
  step left, so no special-casing was needed for the last step's button behavior, only its label.
  - **Test gotcha**: same as the existing `app_root_test.dart` note on this tour — don't
    `pumpAndSettle()` once a showcase step is on screen; it runs a continuous highlight animation
    that never settles, so `pumpAndSettle()` times out. Use fixed-duration `pump()`s instead (see
    `test/features/app_shell/product_tour_test.dart`, which also needed several small pumps before
    the first step's fixed-duration one — the post-frame callback's `await hasSeenTour()` plus the
    target's own layout need more than one frame to resolve in a test environment).

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
- **Explicit exit control, not just `PopScope`**: iOS has no system back button, and the edge-swipe
  gesture that would normally trigger a `PopScope` pop isn't an obviously discoverable affordance
  mid-match — a player could get stuck on `DuelScreen` with no visible way out. `DuelMatchHeader`
  carries an always-visible exit button (top-left) wired to the exact same `_handlePopAttempt` flow
  as the gesture, not a silent bypass — still shows `QuitMatchDialog` while a round is live. Any
  full-screen route that blocks a system back gesture this way needs the same explicit affordance;
  don't rely on `PopScope` alone being discoverable.
- **`DuelMatchHeader`** (replacing the original `DuelScoreboardPanel`) is a from-scratch redesign
  based on a user-supplied reference: "Round N" + running score in a slim top row, two minimal
  ring-and-dot "face" avatars either side of "vs" below it — no camera-driven expressions exist yet,
  so this is a deliberately abstract placeholder rather than trying to fake a real face. Needed a
  new `roundNumber` counter on `DuelRoundEngine` (1-indexed, increments in `advanceAfterRecap`) since
  draws consume a round without moving `scores`, so round number can't be inferred from score sums.
- **Verification technique for a screen buried behind gameplay** (matchmaking → transition → duel):
  same throwaway-entry-point approach documented in the Profile section below —
  `lib/_debug_..._preview.dart` + `flutter run -t <file>` straight to the widget, deleted after.
  Confirmed the header/exit-button design this way in under a minute instead of fighting simulator
  coordinate-tap automation through three prior screens.

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

## Profile sub-screen fixes (post-Section-10 review pass)

Real bugs found from screenshots after Section 10 shipped, all fixed in one pass:

- **`GradientScaffold` only wrapped `body`, not the whole `Scaffold`.** With a transparent `AppBar`
  (every sub-screen that has one), the app bar area fell through to the plain theme background
  instead of the gradient — white `AppBar` title text on a near-white background is effectively
  invisible. Fixed by moving the gradient `DecoratedBox` to wrap the entire `Scaffold`, not just
  `body` — see the widget's doc comment. The `extendBodyBehindAppBar` param is gone; the fix makes
  it unconditionally correct instead of something callers had to remember to opt into.
- **`PodiumLeaderboard` had a hardcoded `SizedBox(height: 180)`** around the podium `Row` that was
  never actually tall enough for the content (crown + avatar + name + score + up to a 130px block) —
  silently clipped with a `BOTTOM OVERFLOWED BY 68 PIXELS` banner the whole time this component
  existed, just never rendered on a real screen until `LeaderboardScreen` (Section 10) actually used
  it. Fixed by removing the fixed height and letting the `Row` size to its own intrinsic content.
- **`LeaderboardScreen`/`FaqSupportScreen`/`PaywallScreen` pushed on the tab's nested Navigator**,
  same bug class as engineering rule 9 — `FloatingNavBar` bled through on top of all three. All
  three pushes now use `Navigator.of(context, rootNavigator: true)`.
- **`PaywallScreen` was redesigned** — the original used two `Spacer()`s to center a thin perk list,
  which read as mostly-empty gradient on any real screen size. Replaced with a `ListView` (icon
  badge, title/subtitle, perk rows as frosted icon-in-circle cards matching `FaqSupportScreen`'s
  card language, CTA, fine print) — no more Spacer-driven empty space.
- **Sign out had no confirmation** — an easy accidental tap with no undo. Added `SignOutDialog`,
  and factored the shared visual shell both it and `DeleteAccountDialog` use into
  `LobbyConfirmationDialog` (`lib/core/widgets/`) rather than duplicating the icon/title/body/button
  structure a third time.
- **Verification method for a screen buried behind on-screen navigation**: simulator coordinate-tap
  automation (AppleScript `click at`) is fragile for anything nested a few screens deep — window
  geometry drift, scroll-position drift across app restarts, and small tap targets all compound.
  When a screen is hard to reach that way (as `PaywallScreen` was here), write a throwaway entry
  point (`lib/_debug_..._preview.dart`, `runApp` straight to the target widget) and
  `flutter run -t <that file>` — renders the real widget with real data instantly, no navigation
  needed. Delete the file after. Don't burn excessive tap-and-guess cycles trying to brute-force a
  path through the UI when this is available.

## Rest of Profile tab (Section 10)

- `ProfileRepository` (`lib/features/profile/domain/`) + `FakeProfileRepository` cover profile
  stats, leaderboard, cosmetics, and subscription tier — same fake-backend pattern as every other
  feature. Seeded with the **signed-in player's own display name** (read from `authStateProvider`
  in `profile_providers.dart`), not a hardcoded string, so the whole demo reads coherently —
  Profile shows whoever you actually signed in as.
- `friendsCount` on the seeded profile is a static demo number, not derived from
  `FriendsRepository` — features never reach into each other's internals (engineering rule 1); a
  real implementation would read this off the player's own Firestore document, which the friends
  feature keeps in sync, not off `FriendsRepository` directly.
- Leaderboard ranking metric is **total round wins**, documented explicitly on `ProfileRepository`
  per the master prompt's own instruction not to leave the scoring metric implicit.
- `equipCosmetic` is a genuine no-op when given an unowned/unknown cosmetic id — worth calling out
  because the first version of this method had a real bug: it looped over *owned* cosmetics setting
  `equipped: c.id == cosmeticId`, which for an unowned target id meant **every** owned cosmetic
  failed that check and got unequipped, silently clearing the equipped slot instead of doing
  nothing. Caught by a test asserting the previously-equipped item stayed equipped after trying to
  equip a locked one — worth remembering as a shape of bug: a "set the matching one true, others
  false" loop is only a no-op for a not-found id if you check for that case *before* the loop.
- Notifications toggle (`NotificationSettingsController` + `LocalNotificationSettings`) is a
  device-local `shared_preferences` setting, deliberately not folded into `ProfileRepository` — same
  reasoning as onboarding-seen being separate from auth state. No push-notification wiring exists
  yet; this only persists the toggle itself.
- Sign out / delete account reuse `AuthRepository.signOut()`/`.deleteAccount()` from Section 6
  directly — `DeleteAccountDialog` only confirms intent, matching `QuitMatchDialog`'s pattern.
- `FaqSupportScreen`'s support contact is a real `mailto:` intent via `url_launcher`, with a
  fallback snackbar if no mail client is configured — per the master prompt's instruction to
  "pick one and implement it fully, don't leave a dead-end button."
- **Widget-test gotcha**: a `ProfileScreen`-sized scrollable is taller than the test binding's
  default surface, so most of its content is genuinely below the fold — `find.text`'s default
  `skipOffstage: true` then reports "0 widgets found" for content that actually rendered fine.
  Fix is `tester.view.physicalSize` set tall enough before pumping (see
  `test/features/profile/presentation/profile_screen_test.dart`), not `skipOffstage: false`
  scattered across assertions.

## Monetization (Section 11)

The full RevenueCat package-picker → purchase UI flow is built and real, running against
`FakeProfileRepository` — only the RevenueCat API keys + a dashboard Offerings catalog are pending
(see "What's stubbed" below). Swapping those in is a data-mapping change under
`fetchOfferings`/`purchasePackage`/`restorePurchases`, not a UI rewrite.

- `ProfileRepository` gained `fetchOfferings()`, `purchasePackage(id)`, and a `restorePurchases()`
  that now returns a `PurchaseResult` (was bare `Future<void>`) instead of a silent success —
  `PurchaseResultStatus` distinguishes `purchased`/`restored`/`nothingToRestore`/`failed`, so the UI
  can tell "you're already subscribed, nothing to restore" apart from an actual failure. Kept on
  `ProfileRepository` rather than split into its own feature — the subscription tier it manages was
  already there, and the paywall/subscription UI are Profile sub-screens, not a separate feature.
- `SubscriptionPackage` (`lib/features/profile/domain/`) mirrors the shape of a RevenueCat
  `Package` closely enough that the real swap stays a mapping exercise. `FakeProfileRepository`
  seeds two: `plus_monthly` ($4.99/mo) and `plus_annual` ($39.99/yr, badged "Save 33%"); purchasing
  either sets the in-memory tier to `plus` and emits it on `watchSubscriptionTier` so every screen
  watching that provider (`SubscriptionSection`, cosmetics gating, etc.) updates itself — no manual
  refresh wiring needed anywhere.
- `PaywallScreen` is now a `ConsumerStatefulWidget`: a `SubscriptionPackageCard` picker (radio-style
  selection, coin-gold border + badge when selected) feeds a `PrimaryPillButton` whose label always
  shows the selected package's live price. Tapping it shows the button's new `loading` state
  (spinner, disabled) while `purchasePackage` resolves, then `AnimatedSwitcher` crossfades to
  `PurchaseSuccessView` (same crossfade-confirmation language as `AddFriendSheet`'s success state),
  which auto-closes the paywall after ~1.4s. A failed/unknown purchase shows a `SnackBar` and stays
  on the picker instead. `SubscriptionSection`'s "Restore Purchases" reads `PurchaseResult.isSuccess`
  for a real "Face Off Plus restored!" vs. "No previous purchases found." message rather than a
  hardcoded string either way.
- **`PrimaryPillButton` gained an optional `loading` bool** (spinner in place of icon/label, taps
  disabled) — the one new capability added to the shared button rather than duplicated inline, since
  an async CTA that shows its own pending state is a pattern other flows (sign-in, purchases) will
  keep needing.
- **Test gotcha (same shape as the Friends one)**: a test asserting `purchasePackage` emits the new
  tier on `watchSubscriptionTier` has to call `.skip(1).first` *before* triggering the purchase, not
  after — `watchSubscriptionTier`'s `async*` generator forwards to a broadcast `StreamController`,
  which drops events with no listener, and `purchasePackage`'s emission would otherwise already have
  fired and been lost by the time a late `.first` subscribes. See
  `test/features/profile/data/fake_profile_repository_test.dart`.

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
camera + networking)** → **Friends (done, against a fake friends repo)** →
**Profile (done, against a fake profile repo)** → **monetization (done — full RevenueCat
package-picker/purchase UI flow built against the fake repo, pending real API keys)** → offline
handling → performance pass.
