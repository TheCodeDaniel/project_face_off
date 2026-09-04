import 'package:flutter_test/flutter_test.dart';
import 'package:project_face_off/core/gesture_engine/draw_gesture_detector.dart';
import 'package:project_face_off/core/gesture_engine/draw_gesture_event.dart';
import 'package:project_face_off/core/gesture_engine/draw_gesture_thresholds.dart';
import 'package:project_face_off/core/gesture_engine/fake_hand_gesture_engine.dart';
import 'package:project_face_off/core/gesture_engine/hand_landmark_frame.dart';

void main() {
  final now = DateTime(2026, 1, 1);

  Future<void> lockAnchor(FakeHandGestureEngine engine, {double x = 0.5, double y = 0.5}) async {
    for (var i = 0; i <= DrawGestureThresholds.anchorRestFrameCount; i++) {
      engine.emit(HandLandmarkFrame(timestamp: now, handDetected: true, pinchX: x, pinchY: y));
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }

  test('does not emit anything while the hand is still settling into the rest anchor', () async {
    final engine = FakeHandGestureEngine();
    final detector = DrawGestureDetector(engine);
    addTearDown(detector.dispose);
    await detector.start();

    final events = <DrawGestureEvent>[];
    final sub = detector.events.listen(events.add);
    addTearDown(sub.cancel);

    await lockAnchor(engine);
    expect(events, isEmpty);
  });

  test('emits DrawUpdate with power scaled by distance from the anchor once armed', () async {
    final engine = FakeHandGestureEngine();
    final detector = DrawGestureDetector(engine);
    addTearDown(detector.dispose);
    await detector.start();

    final events = <DrawGestureEvent>[];
    final sub = detector.events.listen(events.add);
    addTearDown(sub.cancel);

    await lockAnchor(engine);
    // Full calibrated draw distance straight down from the anchor.
    engine.emit(HandLandmarkFrame(timestamp: now, handDetected: true, pinchX: 0.5, pinchY: 0.85));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(events, hasLength(1));
    final update = events.single as DrawUpdate;
    expect(update.power, closeTo(1.0, 0.01));
  });

  test('a rapid distance drop combined with a hand-openness spread increase releases the shot', () async {
    final engine = FakeHandGestureEngine();
    final detector = DrawGestureDetector(engine);
    addTearDown(detector.dispose);
    await detector.start();

    final events = <DrawGestureEvent>[];
    final sub = detector.events.listen(events.add);
    addTearDown(sub.cancel);

    await lockAnchor(engine);
    engine.emit(HandLandmarkFrame(timestamp: now, handDetected: true, pinchX: 0.5, pinchY: 0.85));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    // Snaps back toward the anchor while the hand spreads open — a release,
    // not just the hand relaxing.
    engine.emit(HandLandmarkFrame(timestamp: now, handDetected: true, pinchX: 0.5, pinchY: 0.5, handOpenness: 0.4));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(events, hasLength(2));
    expect(events.last, isA<DrawReleased>());
    expect((events.last as DrawReleased).power, closeTo(1.0, 0.01));
  });

  test('losing the hand mid-draw past the grace window cancels rather than releases', () async {
    final engine = FakeHandGestureEngine();
    final detector = DrawGestureDetector(engine);
    addTearDown(detector.dispose);
    await detector.start();

    final events = <DrawGestureEvent>[];
    final sub = detector.events.listen(events.add);
    addTearDown(sub.cancel);

    await lockAnchor(engine);
    engine.emit(HandLandmarkFrame(timestamp: now, handDetected: true, pinchX: 0.5, pinchY: 0.7));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    for (var i = 0; i < DrawGestureThresholds.occlusionGraceFrameCount; i++) {
      engine.emit(HandLandmarkFrame(timestamp: now, handDetected: false));
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }

    expect(events.last, isA<DrawCancelled>());
  });
}
