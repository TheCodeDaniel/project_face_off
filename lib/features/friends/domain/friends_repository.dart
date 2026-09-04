import 'friend.dart';
import 'friend_request.dart';
import 'report_reason.dart';

/// Friends contract (master prompt Section 9). The real implementation is
/// Firestore-backed — needs a real Firebase project first; see CLAUDE.md.
/// [FakeFriendsRepository] backs this today so the list/requests/add/block/
/// report UI is fully buildable and testable without one.
///
/// Blocking must be enforced both client-side (immediate UX — hide the user,
/// stop future requests) and server-side (a security rule / Cloud Function
/// check at matchmaking time, so a block can't be bypassed by a modified
/// client) — the server half is naturally out of scope until Firebase exists.
abstract class FriendsRepository {
  Stream<List<Friend>> watchFriends();

  Stream<List<FriendRequest>> watchIncomingRequests();

  /// The local player's own shareable invite code.
  String get myInviteCode;

  /// Sends a friend request using another player's invite code. Throws if
  /// the code doesn't resolve to anyone.
  Future<void> sendRequestByCode(String code);

  /// Sends a friend request directly to a known player id — the results
  /// screen's "Add Friend" action (post-match flow plan Section 2) reuses
  /// this rather than [sendRequestByCode] since the opponent's identity is
  /// already known from the match, with no code exchange needed. Writes to
  /// the exact same pending-request record either way — this is a second
  /// entry point, not a parallel implementation.
  Future<void> sendRequestToPlayer(String playerId, String displayName);

  Future<void> acceptRequest(String requestId);

  Future<void> declineRequest(String requestId);

  Future<void> unfriend(String friendId);

  Future<void> blockUser(String userId);

  Future<void> reportUser(String userId, ReportReason reason, String? details);
}
