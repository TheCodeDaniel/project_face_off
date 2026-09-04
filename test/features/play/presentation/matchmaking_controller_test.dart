import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_face_off/features/play/domain/matchmaking_repository.dart';
import 'package:project_face_off/features/play/domain/matchmaking_state.dart';
import 'package:project_face_off/features/play/presentation/matchmaking_controller.dart';

class _ScriptedMatchmakingRepository implements MatchmakingRepository {
  _ScriptedMatchmakingRepository(this._controller);

  final StreamController<MatchmakingState> _controller;

  @override
  Stream<MatchmakingState> joinQueue() => _controller.stream;
}

void main() {
  group('MatchmakingController', () {
    test('startQueue relays Searching then Found from the repository', () async {
      final source = StreamController<MatchmakingState>();
      final container = ProviderContainer(
        overrides: [matchmakingRepositoryProvider.overrideWithValue(_ScriptedMatchmakingRepository(source))],
      );
      addTearDown(container.dispose);

      expect(container.read(matchmakingControllerProvider), isA<MatchmakingIdle>());

      container.read(matchmakingControllerProvider.notifier).startQueue();
      source.add(const MatchmakingSearching());
      await Future<void>.delayed(Duration.zero);
      expect(container.read(matchmakingControllerProvider), isA<MatchmakingSearching>());

      const found = MatchmakingFound(matchId: 'm1', opponentId: 'bot-ama', opponentName: 'Ama');
      source.add(found);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(matchmakingControllerProvider), same(found));
    });

    test('startQueue relays a timeout', () async {
      final source = StreamController<MatchmakingState>();
      final container = ProviderContainer(
        overrides: [matchmakingRepositoryProvider.overrideWithValue(_ScriptedMatchmakingRepository(source))],
      );
      addTearDown(container.dispose);

      container.read(matchmakingControllerProvider.notifier).startQueue();
      source.add(const MatchmakingTimedOut());
      await Future<void>.delayed(Duration.zero);

      expect(container.read(matchmakingControllerProvider), isA<MatchmakingTimedOut>());
    });

    test('cancelQueue resets to Idle and ignores further events from the old stream', () async {
      final source = StreamController<MatchmakingState>();
      final container = ProviderContainer(
        overrides: [matchmakingRepositoryProvider.overrideWithValue(_ScriptedMatchmakingRepository(source))],
      );
      addTearDown(container.dispose);

      container.read(matchmakingControllerProvider.notifier).startQueue();
      source.add(const MatchmakingSearching());
      await Future<void>.delayed(Duration.zero);

      container.read(matchmakingControllerProvider.notifier).cancelQueue();
      expect(container.read(matchmakingControllerProvider), isA<MatchmakingIdle>());

      source.add(const MatchmakingFound(matchId: 'late', opponentId: 'bot-zara', opponentName: 'Zara'));
      await Future<void>.delayed(Duration.zero);
      expect(container.read(matchmakingControllerProvider), isA<MatchmakingIdle>());
    });
  });
}
