import 'discovery_location.dart';

export 'discovery_location.dart';

enum DiscoveryRouteOrder { nearestNeighbor, fixedStory }

class DiscoveryRoute {
  DiscoveryRoute({
    required Iterable<DiscoveryLocation> stops,
    required Iterable<String> skippedInvalidSiteIds,
    required this.estimatedStraightLineMeters,
  }) : stops = List.unmodifiable(stops),
       skippedInvalidSiteIds = List.unmodifiable(skippedInvalidSiteIds);

  final List<DiscoveryLocation> stops;
  final List<String> skippedInvalidSiteIds;

  /// Kullanıcıdan ilk durağa ve duraklar arasındaki kuş uçuşu toplam.
  /// Başlangıca dönüş içermez; gerçek yürüyüş mesafesi değildir.
  final double estimatedStraightLineMeters;
}

/// İsteğe bağlı zincirler için yaklaşık sıralama; yürüyüş rotası üretmez.
class DiscoveryRouteService {
  const DiscoveryRouteService();

  /// Geçersiz duraklar atlanır ve sonuçta ayrıca bildirilir. Sabit hikâye
  /// sırasında kalan durakların göreli sırası değişmez. Geçersiz kullanıcı
  /// konumu ArgumentError üretir; tahmini başlangıç koordinatı kullanılmaz.
  DiscoveryRoute buildRoute({
    required Iterable<DiscoveryLocation> chainSites,
    required DiscoveryLocation userLocation,
    DiscoveryRouteOrder order = DiscoveryRouteOrder.nearestNeighbor,
    Set<String> visitedSiteIds = const {},
    bool excludeVisited = true,
  }) {
    if (!userLocation.hasValidCoordinates) {
      throw ArgumentError('Geçerli kullanıcı konumu gerekiyor.');
    }
    final remaining = <DiscoveryLocation>[];
    final invalid = <String>[];
    for (final site in chainSites) {
      if (excludeVisited && visitedSiteIds.contains(site.id)) continue;
      if (!site.hasValidCoordinates) {
        invalid.add(site.id);
      } else {
        remaining.add(site);
      }
    }
    final stops = <DiscoveryLocation>[];
    var current = userLocation;
    var total = 0.0;
    while (remaining.isNotEmpty) {
      var nextIndex = 0;
      var nextDistance = current.distanceTo(remaining.first);
      if (order == DiscoveryRouteOrder.nearestNeighbor) {
        for (var i = 1; i < remaining.length; i++) {
          final distance = current.distanceTo(remaining[i]);
          // Eşit mesafelerde özgün sıra korunur.
          if (distance < nextDistance) {
            nextIndex = i;
            nextDistance = distance;
          }
        }
      }
      current = remaining.removeAt(nextIndex);
      stops.add(current);
      total += nextDistance;
    }
    return DiscoveryRoute(
      stops: stops,
      skippedInvalidSiteIds: invalid,
      estimatedStraightLineMeters: total,
    );
  }
}
