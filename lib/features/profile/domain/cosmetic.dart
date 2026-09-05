import 'package:flutter/foundation.dart';

import '../../../core/game_engine/game_pool.dart';

@immutable
class Cosmetic {
  const Cosmetic({
    required this.id,
    required this.name,
    required this.icon,
    required this.owned,
    required this.equipped,
    this.applicableGameId,
  });

  final String id;
  final String name;
  final List<List<dynamic>> icon;
  final bool owned;
  final bool equipped;

  /// `null` = universal (profile avatar skin, victory animation — applies
  /// across any game); non-null = only meaningful in that one game (e.g. an
  /// arrow skin for Bow & Draw) (multi-game plan Section 5). Both are still
  /// one-time purchases either way — this only tags which context a
  /// cosmetic actually shows up in, no structural change to how it's
  /// bought/equipped.
  final GameId? applicableGameId;

  Cosmetic copyWith({bool? equipped}) {
    return Cosmetic(
      id: id,
      name: name,
      icon: icon,
      owned: owned,
      equipped: equipped ?? this.equipped,
      applicableGameId: applicableGameId,
    );
  }
}
