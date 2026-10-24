import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackathon_kok/data/models/heritage_site.dart';
import 'package:hackathon_kok/features/discover/screens/discover_screen.dart';
import 'package:hackathon_kok/features/heritage_detail/screens/heritage_detail_screen.dart';
import 'package:hackathon_kok/widgets/heritage_map.dart';

class _Tiles extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
        ),
      );
}

// Sentetik test girdileri; gerçek eser bilgisi değildir.
HeritageSite site(String id, {double? lat = 0, double? lon = 0}) =>
    HeritageSite(
      id: id,
      name: id,
      displayName: id,
      type: 'Test türü',
      district: 'Test ilçesi',
      source: '',
      latitude: lat,
      longitude: lon,
    );
Future<void> show(
  WidgetTester tester,
  Future<List<HeritageSite>> Function() load,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DiscoverScreen(loadSites: load, mapTileProvider: _Tiles()),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets(
    'Liste/Harita aynı veriyi kullanır, tüm geçerli işaretçiler sığar',
    (tester) async {
      var calls = 0;
      await show(tester, () async {
        calls++;
        return [site('a'), site('b', lat: .01, lon: .01)];
      });
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsNWidgets(2));
      await tester.tap(find.text('Harita'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers,
        hasLength(2),
      );
      expect(
        tester
            .widget<FlutterMap>(find.byType(FlutterMap))
            .options
            .initialCameraFit,
        isNotNull,
      );
      await tester.tap(find.text('Liste'));
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsNWidgets(2));
      expect(calls, 1);
    },
  );
  testWidgets('İşaretçi bilgisi ve doğru detay ekranına geçiş', (tester) async {
    final selected = site('seçilen');
    await show(
      tester,
      () async => [selected, site('diğer', lat: .01, lon: .01)],
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Harita'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('heritage-marker-seçilen')));
    await tester.pumpAndSettle();
    expect(find.text('seçilen'), findsOneWidget);
    expect(find.text('Test türü · Test ilçesi'), findsOneWidget);
    await tester.tap(find.text('Detayları gör'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<HeritageDetailScreen>(find.byType(HeritageDetailScreen))
          .site,
      same(selected),
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(HeritageMap), findsOneWidget);
  });
  testWidgets('Eksik ve geçersiz konum listede kalır, haritadan elenir', (
    tester,
  ) async {
    await show(
      tester,
      () async => [
        site('valid'),
        site('missing', lat: null),
        site('invalid', lat: double.nan),
      ],
    );
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsNWidgets(3));
    await tester.tap(find.text('Harita'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers,
      hasLength(1),
    );
    expect(find.textContaining('2 eser konum bilgisi'), findsOneWidget);
    await tester.tap(find.text('Liste'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('missing'));
    await tester.pumpAndSettle();
    expect(find.byType(HeritageDetailScreen), findsOneWidget);
  });
  testWidgets('Tümü geçersizse anlaşılır mesaj ve listeye dönüş', (
    tester,
  ) async {
    await show(tester, () async => [site('missing', lat: null)]);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Harita'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Eserlere Liste görünümünden'), findsOneWidget);
    expect(find.byType(FlutterMap), findsNothing);
  });
  testWidgets('Yükleniyor, ağ hatası, tekrar deneme ve boş veri', (
    tester,
  ) async {
    final pending = Completer<List<HeritageSite>>();
    var calls = 0;
    await show(tester, () {
      calls++;
      return calls == 1 ? pending.future : Future.value([]);
    });
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.completeError(Exception('network'));
    await tester.pumpAndSettle();
    expect(find.text('Eserler yüklenemedi.'), findsOneWidget);
    await tester.tap(find.text('Tekrar dene'));
    await tester.pumpAndSettle();
    expect(find.text('Henüz eser yok.'), findsOneWidget);
    expect(calls, 2);
  });
  testWidgets('Dar mobil ekranda taşma olmaz', (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await show(tester, () async => [site('a'), site('missing', lat: null)]);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Harita'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('Harita karosu hatası kullanıcıya bildirilir', (tester) async {
    await show(tester, () async => [site('a')]);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Harita'));
    await tester.pumpAndSettle();
    tester.widget<HeritageMap>(find.byType(HeritageMap)).onTileError!();
    await tester.pumpAndSettle();
    expect(find.textContaining('Harita zemini yüklenemedi.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  test('Eksik koordinatlı Supabase satırı eser olarak korunur', () {
    final parsed = HeritageSite.fromMap({
      'id': 'missing',
      'ilce': '',
      'ad': '',
      'guncel_ad': '',
      'eser_turu': '',
      'kaynak': '',
      'enlem': null,
      'boylam': 'invalid',
    });
    expect(parsed.latitude, isNull);
    expect(parsed.longitude, isNull);
  });
}
