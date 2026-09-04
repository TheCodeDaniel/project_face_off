import '../../features/games/bow_draw/domain/bow_draw_game_module.dart';
import '../../features/games/face_off/domain/face_off_game_module.dart';
import '../../features/games/freeze/domain/freeze_game_module.dart';
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
    GameId.bowDraw => BowDrawGameModule(playerAId: playerAId, playerBId: playerBId),
    GameId.freeze => FreezeGameModule(playerAId: playerAId, playerBId: playerBId),
  };
}
