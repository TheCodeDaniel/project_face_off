import 'package:flutter/foundation.dart';

@immutable
class Friend {
  const Friend({required this.id, required this.displayName, required this.online});

  final String id;
  final String displayName;
  final bool online;
}
