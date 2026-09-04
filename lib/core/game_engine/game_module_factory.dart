import '../../features/games/face_off/domain/face_off_game_module.dart';
import 'game_module.dart';
import 'game_pool.dart';

/// Builds the concrete [GameModule] for a given [GameId]. Deliberately the
/// one place in `core/` that imports a game feature's own domain class —
/// `core/game_engine/` acts as the composition point for "which concrete
/// module backs which pool entry," the same role `main.dart` already plays
/// wiring concrete feature screens into the generic app shell. No other file
/// in `core/` reaches into a game feature's internals.
GameModule createGameModule(GameId id, {required String playerAId, required String playerBId}) {
  return switch (id) {
    GameId.faceOff => FaceOffGameModule(playerAId: playerAId, playerBId: playerBId),
    // Build order (multi-game plan Section 8): Bow & Draw and Freeze ship
    // after this refactor lands. gamePool already carries their catalog
    // entries; pickRandomGameId only draws from implementedGameIds, so
    // Quick Match can never route here for an unbuilt game.
    GameId.bowDraw => throw UnimplementedError('Bow & Draw is not built yet — see CLAUDE.md build order.'),
    GameId.freeze => throw UnimplementedError('Freeze is not built yet — see CLAUDE.md build order.'),
  };
}
