import 'package:flutter/foundation.dart';

@immutable
class Cosmetic {
  const Cosmetic({
    required this.id,
    required this.name,
    required this.icon,
    required this.owned,
    required this.equipped,
  });

  final String id;
  final String name;
  final List<List<dynamic>> icon;
  final bool owned;
  final bool equipped;

  Cosmetic copyWith({bool? equipped}) {
    return Cosmetic(id: id, name: name, icon: icon, owned: owned, equipped: equipped ?? this.equipped);
  }
}
