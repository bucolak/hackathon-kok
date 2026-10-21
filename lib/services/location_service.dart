import 'dart:async';

import 'package:geolocator/geolocator.dart';

enum LocationFailure {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  unavailable,
}

class LocationServiceException implements Exception {
  const LocationServiceException(this.failure);

  final LocationFailure failure;

  String get message => switch (failure) {
    LocationFailure.serviceDisabled =>
      'Konum servisi kapalı. Cihaz ayarlarından konumu açın.',
    LocationFailure.permissionDenied =>
      'Konum izni reddedildi. Konum almak için izin vermeniz gerekiyor.',
    LocationFailure.permissionDeniedForever =>
      'Konum izni kalıcı olarak reddedildi. Uygulama ayarlarından izin verin.',
    LocationFailure.timeout =>
      'Konum zamanında alınamadı. Açık bir alanda tekrar deneyin.',
    LocationFailure.unavailable =>
      'Konum alınamadı. Cihaz ayarlarını kontrol edip tekrar deneyin.',
  };

  @override
  String toString() => message;
}

/// Ekran veya veritabanına bağlı olmayan, tek ölçümlük konum servisi.
/// Oluşturulması izin istemez; yalnızca [getCurrentLocation] izin isteyebilir.
class LocationService {
  LocationService({GeolocatorPlatform? platform})
    : _platform = platform ?? GeolocatorPlatform.instance;

  final GeolocatorPlatform _platform;

  Future<bool> isServiceEnabled() => _platform.isLocationServiceEnabled();

  /// Position: latitude, longitude, accuracy (metre), timestamp (ölçüm zamanı).
  /// Zaman sınırı ölçüm içindir; kullanıcının izin diyaloğunu sınırlamaz.
  Future<Position> getCurrentLocation({
    Duration timeout = const Duration(seconds: 20),
  }) async {
    if (timeout <= Duration.zero) {
      throw ArgumentError.value(timeout, 'timeout', 'Pozitif olmalı.');
    }
    try {
      if (!await isServiceEnabled()) {
        throw const LocationServiceException(LocationFailure.serviceDisabled);
      }
      var permission = await _platform.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await _platform.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        throw const LocationServiceException(
          LocationFailure.permissionDeniedForever,
        );
      }
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        throw const LocationServiceException(LocationFailure.permissionDenied);
      }
      return await _platform
          .getCurrentPosition(
            locationSettings: LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: timeout,
            ),
          )
          .timeout(timeout);
    } on LocationServiceException {
      rethrow;
    } on TimeoutException {
      throw const LocationServiceException(LocationFailure.timeout);
    } on LocationServiceDisabledException {
      // Servis, ilk kontrolün ardından da kapanmış olabilir.
      throw const LocationServiceException(LocationFailure.serviceDisabled);
    } on PermissionDeniedException {
      throw const LocationServiceException(LocationFailure.permissionDenied);
    } catch (_) {
      throw const LocationServiceException(LocationFailure.unavailable);
    }
  }

  /// Geçersiz koordinatları kabul etmez; sonuç metre cinsindendir.
  static double distanceInMeters({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    _validateCoordinate(startLatitude, startLongitude);
    _validateCoordinate(endLatitude, endLongitude);
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  static void _validateCoordinate(double latitude, double longitude) {
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude.abs() > 90 ||
        longitude.abs() > 180) {
      throw ArgumentError('Geçerli enlem ve boylam gerekiyor.');
    }
  }

  /// Bu yalnızca doğruluk kapısıdır; tek başına ziyaret doğrulamaz.
  /// Eşik ürün kararına göre çağıran tarafından açıkça verilmelidir.
  static bool isAccuracySufficient({
    required double accuracyMeters,
    required double maxAccuracyMeters,
  }) {
    if (!maxAccuracyMeters.isFinite || maxAccuracyMeters <= 0) {
      throw ArgumentError.value(maxAccuracyMeters, 'maxAccuracyMeters');
    }
    return accuracyMeters.isFinite &&
        accuracyMeters >= 0 &&
        accuracyMeters <= maxAccuracyMeters;
  }

  /// Mesafe, doğruluk ve ölçümün güncelliği birlikte değerlendirilir.
  /// Bu kontrol cihaz konumunun gerçekliğini sunucu tarafında kanıtlamaz.
  static bool canAutomaticallyVerifyVisit({
    required double distanceMeters,
    required double radiusMeters,
    required double accuracyMeters,
    required double maxAccuracyMeters,
    required DateTime measuredAt,
    required Duration maxAge,
    DateTime? now,
  }) {
    if (!radiusMeters.isFinite ||
        radiusMeters <= 0 ||
        maxAge <= Duration.zero) {
      throw ArgumentError('Yarıçap ve ölçüm yaşı sınırı pozitif olmalı.');
    }
    final accurate = isAccuracySufficient(
      accuracyMeters: accuracyMeters,
      maxAccuracyMeters: maxAccuracyMeters,
    );
    final age = (now ?? DateTime.now()).difference(measuredAt);
    return accurate &&
        distanceMeters.isFinite &&
        distanceMeters >= 0 &&
        distanceMeters + accuracyMeters <= radiusMeters &&
        !age.isNegative &&
        age <= maxAge;
  }
}
