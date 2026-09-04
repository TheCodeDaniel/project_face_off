import 'package:flutter_test/flutter_test.dart';
import 'package:project_face_off/core/performance/device_tier.dart';
import 'package:project_face_off/core/performance/device_tier_repository.dart';
import 'package:project_face_off/core/performance/device_tier_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeDeviceTierService implements DeviceTierService {
  _FakeDeviceTierService(this.tier);

  final DeviceTier tier;
  int resolveCallCount = 0;

  @override
  Future<DeviceTier> resolveTier() async {
    resolveCallCount++;
    return tier;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('resolves via the service and caches the result on first call', () async {
    final service = _FakeDeviceTierService(DeviceTier.low);
    final repository = DeviceTierRepository(service);

    final tier = await repository.resolveTier();

    expect(tier, DeviceTier.low);
    expect(service.resolveCallCount, 1);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('device_tier'), 'low');
  });

  test('reads the cached tier on subsequent calls instead of re-resolving', () async {
    final service = _FakeDeviceTierService(DeviceTier.mid);
    final repository = DeviceTierRepository(service);

    await repository.resolveTier();
    final second = await DeviceTierRepository(service).resolveTier();

    expect(second, DeviceTier.mid);
    // Only the first resolveTier() call above actually hit the service —
    // this second repository instance reads the shared_preferences cache
    // instead, same as a fresh app launch would.
    expect(service.resolveCallCount, 1);
  });
}
