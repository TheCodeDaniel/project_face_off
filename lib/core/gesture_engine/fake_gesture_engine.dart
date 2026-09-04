import 'dart:async';

import 'blendshape_frame.dart';
import 'gesture_engine.dart';

/// Test/dev double for [GestureEngine]. Lets domain tests and UI previews
/// feed synthetic blendshape frames with no camera or platform channel.
class FakeGestureEngine implements GestureEngine {
  final _controller = StreamController<BlendshapeFrame>.broadcast();

  @override
  Stream<BlendshapeFrame> get frames => _controller.stream;

  /// Push a synthetic frame — used directly by tests instead of `start()`.
  void emit(BlendshapeFrame frame) => _controller.add(frame);

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}

  Future<void> dispose() => _controller.close();
}
