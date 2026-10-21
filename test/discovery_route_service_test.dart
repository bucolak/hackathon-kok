import 'package:flutter_test/flutter_test.dart';
import 'package:hackathon_kok/services/discovery_route_service.dart';

// Sentetik geometri test noktalarıdır; gerçek eser koordinatları değildir.
const user = DiscoveryLocation(id: 'user', latitude: 0, longitude: 0);
const west = DiscoveryLocation(id: 'west', latitude: 0, longitude: -.001);
const east = DiscoveryLocation(id: 'east', latitude: 0, longitude: .002);
const farEast = DiscoveryLocation(id: 'farEast', latitude: 0, longitude: .003);

void main() {
  const service = DiscoveryRouteService();
  test('Serbest zincir her adımda mevcut durağa en yakın komşuyu seçer', () {
    // Başlangıca göre sıralama east, west, farEast olurdu.
    const origin = DiscoveryLocation(id: 'start', latitude: 0, longitude: 0);
    const east = DiscoveryLocation(id: 'east', latitude: 0, longitude: .001);
    const west = DiscoveryLocation(id: 'west', latitude: 0, longitude: -.002);
    final result = service.buildRoute(
      chainSites: [west, farEast, east],
      userLocation: origin,
    );
    expect(result.stops.map((s) => s.id), ['east', 'farEast', 'west']);
    expect(
      result.estimatedStraightLineMeters,
      closeTo(
        origin.distanceTo(east) +
            east.distanceTo(farEast) +
            farEast.distanceTo(west),
        .000001,
      ),
    );
  });
  test('Sabit hikâye sırası korunur; girdi listesi değişmez', () {
    final sites = [farEast, west, east];
    final result = service.buildRoute(
      chainSites: sites,
      userLocation: user,
      order: DiscoveryRouteOrder.fixedStory,
    );
    expect(result.stops, sites);
    expect(sites, [farEast, west, east]);
    expect(
      result.estimatedStraightLineMeters,
      closeTo(
        user.distanceTo(farEast) +
            farEast.distanceTo(west) +
            west.distanceTo(east),
        .000001,
      ),
    );
  });
  for (final order in DiscoveryRouteOrder.values) {
    test('$order ziyaret edilmiş duraklar isteğe bağlı çıkarılır', () {
      final filtered = service.buildRoute(
        chainSites: [west, east],
        userLocation: user,
        order: order,
        visitedSiteIds: {'west'},
      );
      expect(filtered.stops, [east]);
      final all = service.buildRoute(
        chainSites: [west, east],
        userLocation: user,
        order: order,
        visitedSiteIds: {'west'},
        excludeVisited: false,
      );
      expect(all.stops, hasLength(2));
    });
  }
  test('Eksik/geçersiz duraklar bildirilir; kalan hikâye sırası korunur', () {
    final result = service.buildRoute(
      chainSites: [
        farEast,
        const DiscoveryLocation(id: 'missing'),
        west,
        const DiscoveryLocation(
          id: 'invalid',
          latitude: double.infinity,
          longitude: 0,
        ),
        east,
      ],
      userLocation: user,
      order: DiscoveryRouteOrder.fixedStory,
    );
    expect(result.stops, [farEast, west, east]);
    expect(result.skippedInvalidSiteIds, ['missing', 'invalid']);
  });
  test('Boş, tümü ziyaret edilmiş ve tümü geçersiz zincir', () {
    for (final sites in <List<DiscoveryLocation>>[
      [],
      [west],
      [const DiscoveryLocation(id: 'missing')],
    ]) {
      final result = service.buildRoute(
        chainSites: sites,
        userLocation: user,
        visitedSiteIds: {'west'},
      );
      expect(result.stops, isEmpty);
      expect(result.estimatedStraightLineMeters, 0);
    }
  });
  test('Tek durakta kullanıcıdan durağa mesafe hesaplanır', () {
    final result = service.buildRoute(chainSites: [east], userLocation: user);
    expect(result.stops, [east]);
    expect(result.estimatedStraightLineMeters, user.distanceTo(east));
  });
  test('Geçersiz kullanıcı konumunda koordinat tahmin edilmez', () {
    expect(
      () => service.buildRoute(
        chainSites: [east],
        userLocation: const DiscoveryLocation(id: 'missing'),
      ),
      throwsArgumentError,
    );
  });
  test('Eşit mesafede özgün sıra korunur', () {
    const other = DiscoveryLocation(id: 'other', latitude: 0, longitude: .001);
    final result = service.buildRoute(
      chainSites: [west, other],
      userLocation: user,
    );
    expect(result.stops, [west, other]);
  });
}
