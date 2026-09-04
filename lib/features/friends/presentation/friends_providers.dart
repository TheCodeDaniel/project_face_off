import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/fake_friends_repository.dart';
import '../domain/friend.dart';
import '../domain/friend_request.dart';
import '../domain/friends_repository.dart';

/// Overridden with a real Firebase-backed implementation once a Firestore
/// project exists — see CLAUDE.md.
final friendsRepositoryProvider = Provider<FriendsRepository>((ref) => FakeFriendsRepository());

final friendsListProvider = StreamProvider<List<Friend>>((ref) {
  return ref.watch(friendsRepositoryProvider).watchFriends();
});

final incomingRequestsProvider = StreamProvider<List<FriendRequest>>((ref) {
  return ref.watch(friendsRepositoryProvider).watchIncomingRequests();
});

/// Badge count for the Friends nav item — 0 while the stream is still
/// loading rather than showing a stale/missing badge.
final incomingRequestsCountProvider = Provider<int>((ref) {
  return ref.watch(incomingRequestsProvider).valueOrNull?.length ?? 0;
});
