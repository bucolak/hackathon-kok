import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:hackathon_kok/services/discovery_location.dart';
import 'package:hackathon_kok/widgets/heritage_map.dart';

// Gerçek eser verisi değildir: yalnızca widget testi için sentetik noktalar.
const site = HeritageMapSite(
  id: 'test-a',
  name: 'Test A',
  latitude: 0,
  longitude: 0,
);
const other = HeritageMapSite(
  id: 'test-b',
  name: 'Test B',
  latitude: .01,
  longitude: .01,
);

class _MemoryTiles extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
        ),
      );
}

Future<void> showMap(
  WidgetTester tester, {
  List<HeritageMapSite> sites = const [site],
  DiscoveryLocation? user,
  ValueChanged<String>? onTap,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 600,
            height: 400,
            child: HeritageMap(
              sites: sites,
              userLocation: user,
              onSiteTap: onTap ?? (_) {},
              tileProvider: _MemoryTiles(),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Eser adı erişilebilirdir; dokunma eser kimliğini döndürür', (
    tester,
  ) async {
    String? selected;
    await showMap(tester, onTap: (id) => selected = id);
    expect(find.byTooltip('Test A'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('heritage-marker-test-a')));
    expect(selected, 'test-a');
    expect(tester.takeException(), isNull);
  });
  testWidgets('Kullanıcı konumu farklı simgeyle gösterilir', (tester) async {
    await showMap(
      tester,
      user: const DiscoveryLocation(
        id: 'user',
        latitude: .001,
        longitude: .001,
      ),
    );
    expect(find.byKey(const ValueKey('heritage-user-marker')), findsOneWidget);
    expect(find.byIcon(Icons.my_location), findsOneWidget);
    expect(find.byIcon(Icons.account_balance), findsOneWidget);
  });
  testWidgets('Eksik, sonsuz ve aralık dışı koordinatlar atlanır', (
    tester,
  ) async {
    await showMap(
      tester,
      sites: [
        site,
        const HeritageMapSite(id: 'missing', name: 'Missing'),
        const HeritageMapSite(
          id: 'nan',
          name: 'NaN',
          latitude: double.nan,
          longitude: 0,
        ),
        const HeritageMapSite(
          id: 'inf',
          name: 'Infinity',
          latitude: 0,
          longitude: double.infinity,
        ),
        const HeritageMapSite(
          id: 'bad',
          name: 'Bad',
          latitude: 91,
          longitude: 181,
        ),
        const HeritageMapSite(
          id: 'pole',
          name: 'Pole',
          latitude: 90,
          longitude: 0,
        ),
      ],
      user: const DiscoveryLocation(id: 'user'),
    );
    final layer = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
    expect(layer.markers, hasLength(1));
    expect(find.byKey(const ValueKey('heritage-user-marker')), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Geçerli konum yoksa boş durum gösterilir', (tester) async {
    await showMap(tester, sites: const []);
    expect(
      find.text('Haritada gösterilecek geçerli konum yok.'),
      findsOneWidget,
    );
    expect(find.byType(FlutterMap), findsNothing);
  });
  testWidgets('Tek konumda kamera o konuma odaklanır', (tester) async {
    await showMap(tester);
    final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
    expect(map.options.initialCenter, const LatLng(0, 0));
    expect(map.options.initialCameraFit, isNull);
    expect(map.options.initialZoom, 16);
  });
  testWidgets('Tüm eserler ve kullanıcı kameranın sınırları içindedir', (
    tester,
  ) async {
    await showMap(
      tester,
      sites: const [site, other],
      user: const DiscoveryLocation(
        id: 'user',
        latitude: -.01,
        longitude: -.01,
      ),
    );
    final camera = MapCamera.of(tester.element(find.byType(MarkerLayer)));
    for (final point in [
      const LatLng(0, 0),
      const LatLng(.01, .01),
      const LatLng(-.01, -.01),
    ]) {
      expect(camera.visibleBounds.contains(point), isTrue);
    }
  });
  testWidgets('Yalnızca kullanıcı varsa harita gösterilir', (tester) async {
    await showMap(
      tester,
      sites: const [],
      user: const DiscoveryLocation(id: 'user', latitude: 0, longitude: 0),
    );
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byIcon(Icons.account_balance), findsNothing);
    expect(find.byIcon(Icons.my_location), findsOneWidget);
  });
  testWidgets(
    'OSM atfı, HTTPS URL ve uygulama kimliği tanımlıdır; rota yoktur',
    (tester) async {
      await showMap(tester);
      expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
      final attribution = tester.widget<TextButton>(
        find.byKey(const ValueKey('map-attribution')),
      );
      expect(attribution.onPressed, isNotNull);
      final layer = tester.widget<TileLayer>(find.byType(TileLayer));
      expect(
        layer.urlTemplate,
        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      );
      expect(
        layer.tileProvider.headers['User-Agent'],
        contains('com.hackathon.hackathon_kok'),
      );
      expect(layer.panBuffer, 0);
      expect(find.byType(PolylineLayer), findsNothing);
    },
  );
  testWidgets('Sonradan gelen eserler kamerayı yeniden oluşturur', (
    tester,
  ) async {
    await showMap(tester);
    await showMap(tester, sites: const [other]);
    final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
    expect(map.options.initialCenter, const LatLng(.01, .01));
    expect(
      find.byKey(const ValueKey('heritage-marker-test-b')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('heritage-marker-test-a')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
