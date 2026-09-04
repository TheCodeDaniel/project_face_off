import 'dart:async';

import 'connectivity_service.dart';

/// In-memory [ConnectivityService] for tests/dev — starts online, and lets
/// tests flip [setOnline] to drive [ConnectivityGate]/the duel feature's
/// offline handling without a real network or platform channel.
class FakeConnectivityService implements ConnectivityService {
  FakeConnectivityService({bool initiallyOnline = true}) : _online = initiallyOnline;

  bool _online;
  final _controller = StreamController<bool>.broadcast();

  @override
  Stream<bool> get isOnline async* {
    yield _online;
    yield* _controller.stream;
  }

  void setOnline(bool value) {
    _online = value;
    _controller.add(value);
  }
}
