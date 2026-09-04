import 'package:flutter/widgets.dart';

import '../../features/games/bow_draw/presentation/bow_draw_screen.dart';
import '../../features/games/face_off/presentation/face_off_screen.dart';
import '../../features/games/freeze/presentation/freeze_screen.dart';
import 'game_pool.dart';

/// Builds the screen for whichever game was picked for a match — same
/// deliberate composition-root exception as `createGameModule` (`core/`
/// importing a game feature's own presentation class). `MatchFoundScreen`
/// and the Friends challenge flow both call this instead of hardcoding a
/// single game's screen, so neither needs updating when a new game ships.
Widget buildGameScreen(GameId gameId, {required String opponentName}) {
  return switch (gameId) {
    GameId.faceOff => FaceOffScreen(opponentName: opponentName, gameId: gameId),
    GameId.bowDraw => BowDrawScreen(opponentName: opponentName, gameId: gameId),
    GameId.freeze => FreezeScreen(opponentName: opponentName, gameId: gameId),
  };
}
