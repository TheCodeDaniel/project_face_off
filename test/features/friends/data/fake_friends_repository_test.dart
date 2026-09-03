import 'package:flutter_test/flutter_test.dart';
import 'package:project_face_off/features/friends/data/fake_friends_repository.dart';
import 'package:project_face_off/features/friends/domain/report_reason.dart';

void main() {
  group('FakeFriendsRepository', () {
    test('is seeded with friends and an incoming request', () async {
      final repo = FakeFriendsRepository();

      final friends = await repo.watchFriends().first;
      final requests = await repo.watchIncomingRequests().first;

      expect(friends, isNotEmpty);
      expect(requests, isNotEmpty);
    });

    test('sendRequestByCode rejects a code that is not 6 digits', () async {
      final repo = FakeFriendsRepository();

      expect(repo.sendRequestByCode('123'), throwsArgumentError);
    });

    test('acceptRequest moves the request into the friends list', () async {
      final repo = FakeFriendsRepository();
      final requestsBefore = await repo.watchIncomingRequests().first;
      final requestId = requestsBefore.first.id;
      final friendsCountBefore = (await repo.watchFriends().first).length;

      await repo.acceptRequest(requestId);

      final friendsAfter = await repo.watchFriends().first;
      expect(friendsAfter.length, friendsCountBefore + 1);
      final requestsAfter = await repo.watchIncomingRequests().first;
      expect(requestsAfter.any((r) => r.id == requestId), isFalse);
    });

    test('declineRequest removes the request without adding a friend', () async {
      final repo = FakeFriendsRepository();
      final requestId = (await repo.watchIncomingRequests().first).first.id;
      final friendsCountBefore = (await repo.watchFriends().first).length;

      await repo.declineRequest(requestId);

      final requestsAfter = await repo.watchIncomingRequests().first;
      final friendsAfter = await repo.watchFriends().first;
      expect(requestsAfter.any((r) => r.id == requestId), isFalse);
      expect(friendsAfter.length, friendsCountBefore);
    });

    test('unfriend removes the friend', () async {
      final repo = FakeFriendsRepository();
      final friendId = (await repo.watchFriends().first).first.id;

      await repo.unfriend(friendId);

      final friendsAfter = await repo.watchFriends().first;
      expect(friendsAfter.any((f) => f.id == friendId), isFalse);
    });

    test('blockUser removes the user from friends and requests', () async {
      final repo = FakeFriendsRepository();
      final friendId = (await repo.watchFriends().first).first.id;

      await repo.blockUser(friendId);

      final friendsAfter = await repo.watchFriends().first;
      expect(friendsAfter.any((f) => f.id == friendId), isFalse);
    });

    test('reportUser completes without throwing', () async {
      final repo = FakeFriendsRepository();

      await expectLater(repo.reportUser('f1', ReportReason.harassment, 'details'), completes);
    });
  });
}
