import 'discovery_location.dart';

export 'discovery_location.dart';

class NearbySuggestion {
  const NearbySuggestion({
    required this.site,
    required this.straightLineMeters,
  });

  final DiscoveryLocation site;

  /// Merkez eserden kuş uçuşu mesafe; yürüyüş mesafesi değildir.
  final double straightLineMeters;
}

/// Zincire katılım gerektirmez. Ziyaret/mühür doğrulaması çağıranın görevidir.
class NearbyDiscoveryService {
  const NearbyDiscoveryService();

  List<NearbySuggestion> suggest({
    required DiscoveryLocation verifiedSite,
    required Iterable<DiscoveryLocation> candidates,
    required Set<String> stampedSiteIds,
    double radiusMeters = 500,
    int maxSuggestions = 3,
  }) {
    if (!radiusMeters.isFinite || radiusMeters < 0) {
      throw ArgumentError.value(radiusMeters, 'radiusMeters');
    }
    if (maxSuggestions < 0) {
      throw ArgumentError.value(maxSuggestions, 'maxSuggestions');
    }
    if (!verifiedSite.hasValidCoordinates || maxSuggestions == 0) {
      return const [];
    }
    final seen = <String>{verifiedSite.id, ...stampedSiteIds};
    final suggestions = <NearbySuggestion>[];
    for (final site in candidates) {
      if (!site.hasValidCoordinates || !seen.add(site.id)) continue;
      final distance = verifiedSite.distanceTo(site);
      if (distance <= radiusMeters) {
        suggestions.add(
          NearbySuggestion(site: site, straightLineMeters: distance),
        );
      }
    }
    suggestions.sort((a, b) {
      final distance = a.straightLineMeters.compareTo(b.straightLineMeters);
      return distance != 0 ? distance : a.site.id.compareTo(b.site.id);
    });
    return List.unmodifiable(suggestions.take(maxSuggestions));
  }
}
