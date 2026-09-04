import 'dart:async';

import 'hand_gesture_engine.dart';
import 'hand_landmark_frame.dart';

/// Test/dev double for [HandGestureEngine]. Lets domain tests and UI
/// previews feed synthetic hand-landmark frames with no camera or platform
/// channel — same role [FakeGestureEngine] plays for the face pipeline.
class FakeHandGestureEngine implements HandGestureEngine {
  final _controller = StreamController<HandLandmarkFrame>.broadcast();

  @override
  Stream<HandLandmarkFrame> get frames => _controller.stream;

  /// Push a synthetic frame — used directly by tests instead of `start()`.
  void emit(HandLandmarkFrame frame) => _controller.add(frame);

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}

  Future<void> dispose() => _controller.close();
}
