import 'dart:async';

import '../domain/friend.dart';
import '../domain/friend_request.dart';
import '../domain/friends_repository.dart';
import '../domain/report_reason.dart';

/// In-memory [FriendsRepository] used until a real Firebase project exists
/// (see CLAUDE.md). Seeded with a couple of friends and one incoming request
/// so the UI has something to show in dev builds; any 6-digit code sent via
/// [sendRequestByCode] succeeds and adds a fake friend, since there's no
/// real backend to resolve a code against yet.
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
    _requests.add(FriendRequest(id: 'r${_nextId++}', fromDisplayName: 'Zara'));
    _emit();
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
