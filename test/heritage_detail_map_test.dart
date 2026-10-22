import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackathon_kok/data/models/heritage_site.dart';
import 'package:hackathon_kok/features/heritage_detail/screens/heritage_detail_screen.dart';
import 'package:hackathon_kok/widgets/heritage_map.dart';

import 'heritage_map_test.dart' as existing;

class _MemoryTiles extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
        ),
      );
}

// Mevcut harita testinin sentetik noktası yeniden kullanılır; eser verisi üretilmez.
HeritageSite fixture({double? latitude, double? longitude}) => HeritageSite(
  id: existing.site.id,
  name: existing.site.name,
  displayName: existing.site.name,
  district: '',
  type: '',
  source: '',
  latitude: latitude ?? existing.site.latitude!,
  longitude: longitude ?? existing.site.longitude!,
);

Future<void> showDetail(WidgetTester tester, HeritageSite site) async {
  await tester.pumpWidget(
    MaterialApp(
      home: HeritageDetailScreen(site: site, mapTileProvider: _MemoryTiles()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Seçili model koordinatları ve kimliği tek işaretçiye aktarılır',
    (tester) async {
      final site = fixture();
      await showDetail(tester, site);
      final map = tester.widget<HeritageMap>(find.byType(HeritageMap));
      expect(map.sites, hasLength(1));
      expect(map.sites.single.id, site.id);
      expect(map.sites.single.name, site.displayName);
      expect(map.sites.single.latitude, site.latitude);
      expect(map.sites.single.longitude, site.longitude);
      expect(map.userLocation, isNull);
      expect(map.interactive, isFalse);
      expect(
        tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers,
        hasLength(1),
      );
      expect(
        tester
            .widget<FlutterMap>(find.byType(FlutterMap))
            .options
            .interactionOptions
            .flags,
        InteractiveFlag.none,
      );
      expect(tester.takeException(), isNull);
    },
  );
  for (final invalid in [double.nan, double.infinity, 91.0]) {
    testWidgets('Geçersiz enlemde harita yerine bilgi verilir: $invalid', (
      tester,
    ) async {
      await showDetail(tester, fixture(latitude: invalid));
      expect(find.byType(HeritageMap), findsNothing);
      expect(
        find.text(
          'Bu eserin haritada gösterilebilecek geçerli konum bilgisi bulunmuyor.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Geçersiz boylamda harita oluşturulmaz', (tester) async {
    await showDetail(tester, fixture(longitude: double.infinity));
    expect(find.byType(FlutterMap), findsNothing);
  });
  testWidgets('280px önizleme, atıf ve harita üzerinde sayfa kaydırma', (
    tester,
  ) async {
    await showDetail(tester, fixture());
    final box = find.byKey(const ValueKey('heritage-detail-map'));
    await tester.ensureVisible(box);
    await tester.pumpAndSettle();
    expect(tester.getSize(box).height, 280);
    expect(find.text('Haritadaki Konumu'), findsOneWidget);
    expect(
      find.text('© OpenStreetMap contributors').hitTestable(),
      findsOneWidget,
    );
    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    final before = scrollable.position.pixels;
    await tester.drag(find.byType(FlutterMap), const Offset(0, 150));
    await tester.pumpAndSettle();
    expect(scrollable.position.pixels, lessThan(before));
    expect(tester.takeException(), isNull);
  });
}
