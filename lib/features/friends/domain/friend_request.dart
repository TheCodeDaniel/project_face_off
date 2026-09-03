import 'package:flutter/foundation.dart';

@immutable
class FriendRequest {
  const FriendRequest({required this.id, required this.fromDisplayName});

  final String id;
  final String fromDisplayName;
}
