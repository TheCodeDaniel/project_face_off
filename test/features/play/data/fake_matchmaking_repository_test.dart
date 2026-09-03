import 'package:flutter_test/flutter_test.dart';
import 'package:project_face_off/features/play/data/fake_matchmaking_repository.dart';
import 'package:project_face_off/features/play/domain/matchmaking_state.dart';

void main() {
  test('FakeMatchmakingRepository starts Searching and resolves to Found or TimedOut', () async {
    final events = await FakeMatchmakingRepository().joinQueue().toList();

    expect(events.first, isA<MatchmakingSearching>());
    expect(events.length, 2);
    expect(events.last, anyOf(isA<MatchmakingFound>(), isA<MatchmakingTimedOut>()));
  });
}
