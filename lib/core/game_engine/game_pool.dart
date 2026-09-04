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
  const GameDefinition({required this.id, required this.displayName, required this.requiredLandmarkers});

  final GameId id;
  final String displayName;
  final Set<LandmarkerType> requiredLandmarkers;
}

const gamePool = [
  GameDefinition(id: GameId.faceOff, displayName: 'Face Off', requiredLandmarkers: {LandmarkerType.face}),
  GameDefinition(id: GameId.bowDraw, displayName: 'Bow & Draw', requiredLandmarkers: {LandmarkerType.hand}),
  // Freeze reuses whichever landmarker(s) are already active for the match's
  // other detection needs (multi-game plan Section 2.3) rather than
  // declaring its own — left empty rather than guessing one.
  GameDefinition(id: GameId.freeze, displayName: 'Freeze', requiredLandmarkers: {}),
];

/// Games with a real [GameModule] wired up via `createGameModule` today.
/// Grows as Bow & Draw and Freeze are built (build order Section 8) — no
/// other call site needs to change when that happens, since Quick Match
/// already only ever picks from this set.
const implementedGameIds = {GameId.faceOff};

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
