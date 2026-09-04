import 'dart:async';

import '../domain/friend.dart';
import '../domain/friend_request.dart';
import '../domain/friends_repository.dart';
import '../domain/report_reason.dart';

/// In-memory [FriendsRepository] used until a real Firebase project exists
/// (see CLAUDE.md). Seeded with a couple of friends and one incoming request
/// so the UI has something to show in dev builds; any 6-digit code sent via
/// [sendRequestByCode] succeeds, since there's no real backend to resolve a
/// code against yet — it just completes without mutating local state.
/// **Not** the local player's own incoming-requests list: a real outgoing
/// request lands in the *other* person's inbox, not yours, and with only one
/// simulated user there's no second inbox to add it to. An earlier version
/// of this fake incorrectly added a bogus incoming request as a side effect
/// of sending one — that's backwards and confusing (it made a stray "Zara
/// wants to be friends" appear right after you sent a request), so it's
/// gone.
class FakeFriendsRepository implements FriendsRepository {
  FakeFriendsRepository() {
    _friends.addAll(const [
      Friend(id: 'f1', displayName: 'Kwesi', online: true),
      Friend(id: 'f2', displayName: 'Naledi', online: false),
    ]);
    _requests.add(const FriendRequest(id: 'r1', fromDisplayName: 'Tunde'));
  }

  final _friends = <Friend>[];
  final _requests = <FriendRequest>[];
  final _friendsController = StreamController<List<Friend>>.broadcast();
  final _requestsController = StreamController<List<FriendRequest>>.broadcast();
  var _nextId = 100;

  void _emit() {
    _friendsController.add(List.unmodifiable(_friends));
    _requestsController.add(List.unmodifiable(_requests));
  }

  @override
  Stream<List<Friend>> watchFriends() async* {
    yield List.unmodifiable(_friends);
    yield* _friendsController.stream;
  }

  @override
  Stream<List<FriendRequest>> watchIncomingRequests() async* {
    yield List.unmodifiable(_requests);
    yield* _requestsController.stream;
  }

  @override
  String get myInviteCode => '482913';

  @override
  Future<void> sendRequestByCode(String code) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (code.trim().length != 6) {
      throw ArgumentError('Invite codes are 6 digits.');
    }
  }

  @override
  Future<void> acceptRequest(String requestId) async {
    final request = _requests.firstWhere((r) => r.id == requestId);
    _requests.removeWhere((r) => r.id == requestId);
    _friends.add(Friend(id: 'f${_nextId++}', displayName: request.fromDisplayName, online: true));
    _emit();
  }

  @override
  Future<void> declineRequest(String requestId) async {
    _requests.removeWhere((r) => r.id == requestId);
    _emit();
  }

  @override
  Future<void> unfriend(String friendId) async {
    _friends.removeWhere((f) => f.id == friendId);
    _emit();
  }

  @override
  Future<void> blockUser(String userId) async {
    _friends.removeWhere((f) => f.id == userId);
    _requests.removeWhere((r) => r.id == userId);
    _emit();
  }

  @override
  Future<void> reportUser(String userId, ReportReason reason, String? details) async {
    // No moderation backend for v1 (master prompt Section 9) — a real
    // implementation writes to a Firestore `reports` collection.
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }
}
