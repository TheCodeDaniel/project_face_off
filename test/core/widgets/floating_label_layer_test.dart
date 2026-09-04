import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_face_off/core/widgets/floating_label_layer.dart';

/// Regression test for a real bug: `Positioned` was nested inside
/// `RepaintBoundary`/`AnimatedBuilder` instead of the other way around,
/// which throws "Incorrect use of ParentDataWidget" the moment a label is
/// actually spawned — Positioned's StackParentData landed on Text's render
/// object while RepaintBoundary's render object is what Stack actually saw
/// as its child. A smoke test that never calls `spawn()` never builds a
/// `_FloatingLabel` at all, so it can't catch this — this test spawns one
/// for real, inside a real `Stack`, and pumps through the animation.
void main() {
  testWidgets('spawning a label inside a real Stack does not throw', (tester) async {
    final controller = FloatingLabelController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(children: [FloatingLabelLayer(controller: controller)]),
        ),
      ),
    );

    controller.spawn(text: 'HIT!', position: const Offset(40, 60), color: Colors.cyan);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('HIT!'), findsOneWidget);

    // Pump through the full 1100ms fade/drift so the label's own
    // self-removal (whenComplete(onDone)) also runs without throwing.
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);
    expect(find.text('HIT!'), findsNothing);
  });
}
