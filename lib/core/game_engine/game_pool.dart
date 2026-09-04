import 'dart:math';

import 'landmarker_type.dart';

/// The full v1 game pool (multi-game plan Section 1/2) — a **local, compiled
/// list**, deliberately not a remote-fetched catalog; that's an explicit v2
/// deferral, not an oversight (see the plan's "Decisions made" section).
enum GameId { faceOff, bowDraw, freeze }

/// Catalog entry for one game — id, display copy, and which gesture
/// pipeline(s) it needs. Purely descriptive data; a [GameModule] instance is
/// a separate, stateful thing created per-match by `createGameModule`.
class GameDefinition {
  const GameDefinition({
    required this.id,
    required this.displayName,
    required this.requiredLandmarkers,
    required this.quickRules,
  });

  final GameId id;
  final String displayName;
  final Set<LandmarkerType> requiredLandmarkers;

  /// One-line rules blurb shown on the pre-round rules card (multi-game plan
  /// Section 4.6) — "let each individual match's own pre-round moment carry
  /// that specific game's quick rules," rather than teaching every game
  /// during onboarding before a player has played once.
  final String quickRules;
}

const gamePool = [
  GameDefinition(
    id: GameId.faceOff,
    displayName: 'Face Off',
    requiredLandmarkers: {LandmarkerType.face},
    quickRules: 'Fire first, dodge their attack, and never crack a smile.',
  ),
  GameDefinition(
    id: GameId.bowDraw,
    displayName: 'Bow & Draw',
    requiredLandmarkers: {LandmarkerType.hand},
    quickRules: 'Pull back, judge the distance, and land a clean hit on the target.',
  ),
  GameDefinition(
    id: GameId.freeze,
    displayName: 'Freeze',
    // Reuses whichever landmarker(s) are already active for the match's
    // other detection needs (multi-game plan Section 2.3) rather than
    // declaring its own — left empty rather than guessing one.
    requiredLandmarkers: {},
    quickRules: "When the freeze hits, don't move a muscle.",
  ),
];

/// Games with a real [GameModule] wired up via `createGameModule` today.
const implementedGameIds = {GameId.faceOff, GameId.bowDraw, GameId.freeze};

/// Picks one game at random from [implementedGameIds]. Quick Match stays
/// fully random-game (multi-game plan Section 1) to keep one unified
/// matchmaking queue rather than fragmenting it per game.
///
/// This is a client-local pick for now, same documented-stand-in status as
/// every other pre-Firebase system in this app (`FakeMatchmakingRepository`,
/// etc.) — the plan's Section 3.5 requires the real pick be
/// server-authoritative once a backend exists, so both clients agree on
/// which game they're playing rather than each independently randomizing.
GameId pickRandomGameId([Random? random]) {
  final ids = implementedGameIds.toList(growable: false);
  return ids[(random ?? Random()).nextInt(ids.length)];
}

GameDefinition gameDefinitionFor(GameId id) => gamePool.firstWhere((g) => g.id == id);
