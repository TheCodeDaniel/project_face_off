import 'package:flutter_test/flutter_test.dart';
import 'package:project_face_off/core/performance/device_tier.dart';
import 'package:project_face_off/core/performance/device_tier_service.dart';

void main() {
  group('classifyByRamMb on Android', () {
    test('3GB or less is low tier', () {
      expect(classifyByRamMb(2048, isIOS: false), DeviceTier.low);
      expect(classifyByRamMb(3072, isIOS: false), DeviceTier.low);
    });

    test('above 3GB up to 6GB is mid tier — e.g. a 6GB Samsung A53', () {
      expect(classifyByRamMb(4096, isIOS: false), DeviceTier.mid);
      expect(classifyByRamMb(6144, isIOS: false), DeviceTier.mid);
    });

    test('above 6GB is high tier', () {
      expect(classifyByRamMb(8192, isIOS: false), DeviceTier.high);
    });
  });

  group('classifyByRamMb on iOS — lower thresholds than Android', () {
    test('2GB or less is low tier', () {
      expect(classifyByRamMb(2048, isIOS: true), DeviceTier.low);
    });

    test('a 4GB iPhone 12 lands in mid, not low, despite fewer cores than an 8-core Android', () {
      expect(classifyByRamMb(4096, isIOS: true), DeviceTier.mid);
    });

    test('above 4GB is high tier', () {
      expect(classifyByRamMb(6144, isIOS: true), DeviceTier.high);
      expect(classifyByRamMb(8192, isIOS: true), DeviceTier.high);
    });
  });
}
