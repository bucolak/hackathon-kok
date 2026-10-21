import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hackathon_kok/services/location_service.dart';

// Koordinat üretmeyen platform taklidi. Başarılı ölçüm aynen iletilir.
class _Measurement implements Position {
  @override
  final accuracy = 8.0;
  @override
  final timestamp = DateTime.utc(2026, 10, 21);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Platform extends GeolocatorPlatform {
  bool enabled = true;
  LocationPermission permission = LocationPermission.whileInUse;
  LocationPermission requestedPermission = LocationPermission.whileInUse;
  int requests = 0;
  int measurements = 0;
  Object? failure;
  bool pending = false;
  final Position measurement = _Measurement();
  LocationSettings? settings;

  @override
  Future<bool> isLocationServiceEnabled() async => enabled;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async {
    requests++;
    return requestedPermission;
  }

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    measurements++;
    settings = locationSettings;
    if (failure != null) throw failure!;
    if (pending) return Completer<Position>().future;
    return measurement;
  }
}

Matcher failsWith(LocationFailure failure) => throwsA(
  isA<LocationServiceException>().having((e) => e.failure, 'failure', failure),
);

void main() {
  late _Platform platform;
  late LocationService service;
  setUp(() {
    platform = _Platform();
    service = LocationService(platform: platform);
  });

  test('Servis oluşturulması izin istemez', () {
    expect(platform.requests, 0);
    expect(platform.measurements, 0);
  });

  test('GPS kapalıyken izin ve ölçüm çağrılmaz', () async {
    platform.enabled = false;
    expect(await service.isServiceEnabled(), isFalse);
    await expectLater(
      service.getCurrentLocation(),
      failsWith(LocationFailure.serviceDisabled),
    );
    expect(platform.requests, 0);
    expect(platform.measurements, 0);
  });

  for (final permission in [
    LocationPermission.whileInUse,
    LocationPermission.always,
  ]) {
    test('Verilmiş $permission izni yeniden istenmez; ölçüm korunur', () async {
      platform.permission = permission;
      final result = await service.getCurrentLocation();
      expect(result, same(platform.measurement));
      expect(result.accuracy, platform.measurement.accuracy);
      expect(result.timestamp, platform.measurement.timestamp);
      expect(platform.requests, 0);
      expect(platform.settings!.accuracy, LocationAccuracy.high);
      expect(platform.settings!.timeLimit, const Duration(seconds: 20));
    });
  }

  test(
    'İlk izin reddinde izin istenir ve kabul edilirse ölçüm yapılır',
    () async {
      platform.permission = LocationPermission.denied;
      expect(await service.getCurrentLocation(), same(platform.measurement));
      expect(platform.requests, 1);
    },
  );

  for (final entry in {
    LocationPermission.denied: LocationFailure.permissionDenied,
    LocationPermission.deniedForever: LocationFailure.permissionDeniedForever,
  }.entries) {
    test('İzin isteği sonucu ${entry.key} ayrı bildirilir', () async {
      platform.permission = LocationPermission.denied;
      platform.requestedPermission = entry.key;
      await expectLater(service.getCurrentLocation(), failsWith(entry.value));
      expect(platform.measurements, 0);
    });
  }

  test('Kalıcı reddedilmiş izin tekrar istenmez', () async {
    platform.permission = LocationPermission.deniedForever;
    await expectLater(
      service.getCurrentLocation(),
      failsWith(LocationFailure.permissionDeniedForever),
    );
    expect(platform.requests, 0);
  });

  test('Belirlenemeyen izin ölçüm başlatmaz', () async {
    platform.permission = LocationPermission.unableToDetermine;
    await expectLater(
      service.getCurrentLocation(),
      failsWith(LocationFailure.permissionDenied),
    );
    expect(platform.measurements, 0);
  });

  test('Ölçüm beklemesi zaman aşımına uğrar', () async {
    platform.pending = true;
    await expectLater(
      service.getCurrentLocation(timeout: const Duration(milliseconds: 1)),
      failsWith(LocationFailure.timeout),
    );
  });

  test('Geçersiz zaman aşımı reddedilir', () async {
    await expectLater(
      service.getCurrentLocation(timeout: Duration.zero),
      throwsArgumentError,
    );
    expect(platform.measurements, 0);
  });

  for (final entry in <Object, LocationFailure>{
    TimeoutException(''): LocationFailure.timeout,
    LocationServiceDisabledException(): LocationFailure.serviceDisabled,
    PermissionDeniedException(''): LocationFailure.permissionDenied,
    StateError('platform'): LocationFailure.unavailable,
  }.entries) {
    test('Platform hatası ${entry.value} olarak iletilir', () async {
      platform.failure = entry.key;
      await expectLater(service.getCurrentLocation(), failsWith(entry.value));
    });
  }

  test('Doğruluk sınırı ve geçersiz ölçümler', () {
    for (final accuracy in [double.nan, double.infinity, -1.0, 21.0]) {
      expect(
        LocationService.isAccuracySufficient(
          accuracyMeters: accuracy,
          maxAccuracyMeters: 20,
        ),
        isFalse,
      );
    }
    expect(
      LocationService.isAccuracySufficient(
        accuracyMeters: 20,
        maxAccuracyMeters: 20,
      ),
      isTrue,
    );
    expect(
      () => LocationService.isAccuracySufficient(
        accuracyMeters: 1,
        maxAccuracyMeters: 0,
      ),
      throwsArgumentError,
    );
  });

  final now = DateTime.utc(2026, 10, 21);
  bool verify({
    double accuracy = 8,
    double distance = 10,
    DateTime? measuredAt,
  }) => LocationService.canAutomaticallyVerifyVisit(
    distanceMeters: distance,
    radiusMeters: 30,
    accuracyMeters: accuracy,
    maxAccuracyMeters: 15,
    measuredAt: measuredAt ?? now,
    maxAge: const Duration(seconds: 30),
    now: now,
  );

  test('Yeterli doğruluk ve güncel yakın ölçüm doğrulamaya uygundur', () {
    expect(verify(), isTrue);
  });
  test('Yakın olsa bile yetersiz doğruluk doğrulanmaz', () {
    expect(verify(accuracy: 16), isFalse);
  });
  test('Doğruluk belirsizliği yarıçapı aşıyorsa doğrulanmaz', () {
    expect(verify(distance: 25), isFalse);
  });
  test('Eski, gelecekte veya geçersiz mesafeli ölçüm doğrulanmaz', () {
    expect(
      verify(measuredAt: now.subtract(const Duration(seconds: 31))),
      isFalse,
    );
    expect(verify(measuredAt: now.add(const Duration(seconds: 1))), isFalse);
    expect(verify(distance: double.nan), isFalse);
    expect(verify(distance: -1), isFalse);
  });
  test(
    'Mesafe hesabı geçersiz koordinatları reddeder; koordinat üretilmez',
    () {
      expect(
        () => LocationService.distanceInMeters(
          startLatitude: double.nan,
          startLongitude: double.nan,
          endLatitude: double.nan,
          endLongitude: double.nan,
        ),
        throwsArgumentError,
      );
    },
  );
}
