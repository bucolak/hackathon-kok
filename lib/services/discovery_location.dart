import 'location_service.dart';

/// Supabase'den bağımsız, eser kimliği ve isteğe bağlı koordinatları.
class DiscoveryLocation {
  const DiscoveryLocation({required this.id, this.latitude, this.longitude});

  final String id;
  final double? latitude;
  final double? longitude;

  bool get hasValidCoordinates {
    final lat = latitude;
    final lon = longitude;
    return lat != null &&
        lon != null &&
        lat.isFinite &&
        lon.isFinite &&
        lat.abs() <= 90 &&
        lon.abs() <= 180;
  }

  double distanceTo(DiscoveryLocation other) {
    if (!hasValidCoordinates || !other.hasValidCoordinates) {
      throw ArgumentError('Mesafe için iki geçerli koordinat gerekiyor.');
    }
    return LocationService.distanceInMeters(
      startLatitude: latitude!,
      startLongitude: longitude!,
      endLatitude: other.latitude!,
      endLongitude: other.longitude!,
    );
  }
}
