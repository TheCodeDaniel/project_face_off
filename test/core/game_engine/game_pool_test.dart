import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:project_face_off/core/game_engine/game_pool.dart';

void main() {
  test('gamePool lists all three v1 games (multi-game plan Section 1/2)', () {
    expect(gamePool.map((g) => g.id), containsAll(GameId.values));
  });

  test('pickRandomGameId only ever returns a game with a real module built', () {
    final random = Random(42);
    for (var i = 0; i < 20; i++) {
      expect(implementedGameIds.contains(pickRandomGameId(random)), isTrue);
    }
  });
}
