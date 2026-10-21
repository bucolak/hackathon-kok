import 'package:flutter_test/flutter_test.dart';
import 'package:hackathon_kok/services/nearby_discovery_service.dart';

// Yalnızca matematik testlerine ait sentetik noktalar; gerçek eser verisi değil.
const center = DiscoveryLocation(id: 'center', latitude: 0, longitude: 0);
DiscoveryLocation point(String id, double longitude) =>
    DiscoveryLocation(id: id, latitude: 0, longitude: longitude);

void main() {
  const service = NearbyDiscoveryService();
  List<NearbySuggestion> suggest(
    List<DiscoveryLocation> sites, {
    Set<String> stamped = const {},
    double radius = 500,
    int limit = 3,
    DiscoveryLocation origin = center,
  }) => service.suggest(
    verifiedSite: origin,
    candidates: sites,
    stampedSiteIds: stamped,
    radiusMeters: radius,
    maxSuggestions: limit,
  );

  test('En yakından uzağa sıralanır ve mesafe metre cinsindendir', () {
    final result = suggest([
      point('far', .003),
      point('near', .001),
      point('middle', .002),
    ]);
    expect(result.map((s) => s.site.id), ['near', 'middle', 'far']);
    expect(result.first.straightLineMeters, inInclusiveRange(110, 112));
  });
  test('Varsayılan 500 metre sınırının içi ve dışı', () {
    expect(center.distanceTo(point('in', .00449)), lessThan(500));
    expect(center.distanceTo(point('out', .00450)), greaterThan(500));
    expect(
      suggest([point('out', .00450), point('in', .00449)])
          .map((s) => s.site.id),
      ['in'],
    );
  });
  test('Yapılandırılan sınır dahil edilir; dışı dışlanır', () {
    final site = point('edge', .001);
    final distance = center.distanceTo(site);
    expect(suggest([site], radius: distance), hasLength(1));
    expect(suggest([site], radius: distance - .001), isEmpty);
  });
  test('Merkez eser ve mühür kazanılmış eserler dışlanır', () {
    expect(
      suggest(
        [center, point('stamped', .001), point('new', .002)],
        stamped: {'stamped'},
      ).map((s) => s.site.id),
      ['new'],
    );
  });
  test('Eksik ve geçersiz koordinatlar atlanır', () {
    expect(
      suggest([
        const DiscoveryLocation(id: 'missing'),
        const DiscoveryLocation(id: 'partial', latitude: 0),
        const DiscoveryLocation(id: 'lat', latitude: 91, longitude: 0),
        const DiscoveryLocation(id: 'lon', latitude: 0, longitude: -181),
        const DiscoveryLocation(id: 'nan', latitude: double.nan, longitude: 0),
        const DiscoveryLocation(
          id: 'inf',
          latitude: 0,
          longitude: double.infinity,
        ),
        point('valid', .001),
      ]).map((s) => s.site.id),
      ['valid'],
    );
  });
  test('Merkez koordinatı geçersizse tahmin yapılmaz', () {
    expect(
      suggest([
        point('a', .001),
      ], origin: const DiscoveryLocation(id: 'missing')),
      isEmpty,
    );
  });
  test('Uygun eser yoksa boş sonuç', () {
    expect(suggest([]), isEmpty);
    expect(suggest([point('outside', .01)]), isEmpty);
  });
  test('Varsayılan en fazla 3; sayı yapılandırılabilir', () {
    final sites = [for (var i = 1; i <= 5; i++) point('p$i', i * .0001)];
    expect(suggest(sites), hasLength(3));
    expect(suggest(sites, limit: 4), hasLength(4));
    expect(suggest(sites, limit: 0), isEmpty);
  });
  test('Tekrarlanan eser kimlikleri bir kez önerilir', () {
    expect(suggest([point('a', .001), point('a', .001)]), hasLength(1));
  });
  test('Eşit mesafede kimlikle deterministik sıralama', () {
    expect(
      suggest([point('b', .001), point('a', .001)]).map((s) => s.site.id),
      ['a', 'b'],
    );
  });
  test('Hatalı ayarlar açıkça reddedilir', () {
    expect(() => suggest([], radius: -1), throwsArgumentError);
    expect(() => suggest([], radius: double.nan), throwsArgumentError);
    expect(() => suggest([], radius: double.infinity), throwsArgumentError);
    expect(() => suggest([], limit: -1), throwsArgumentError);
  });
}
