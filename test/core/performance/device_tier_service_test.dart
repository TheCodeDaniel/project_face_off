import 'package:flutter_test/flutter_test.dart';
import 'package:project_face_off/core/performance/device_tier.dart';
import 'package:project_face_off/core/performance/device_tier_service.dart';

void main() {
  group('classifyByCoreCount', () {
    test('4 or fewer cores is low tier', () {
      expect(classifyByCoreCount(1), DeviceTier.low);
      expect(classifyByCoreCount(4), DeviceTier.low);
    });

    test('5 to 7 cores is mid tier', () {
      expect(classifyByCoreCount(5), DeviceTier.mid);
      expect(classifyByCoreCount(7), DeviceTier.mid);
    });

    test('8 or more cores is high tier', () {
      expect(classifyByCoreCount(8), DeviceTier.high);
      expect(classifyByCoreCount(16), DeviceTier.high);
    });
  });
}
