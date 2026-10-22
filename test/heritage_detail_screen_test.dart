import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackathon_kok/core/theme/app_theme.dart';
import 'package:hackathon_kok/data/models/heritage_site.dart';
import 'package:hackathon_kok/features/discover/screens/discover_screen.dart';
import 'package:hackathon_kok/features/heritage_detail/screens/heritage_detail_screen.dart';

// Yalnızca test girdisi; gerçek eser veya tarih bilgisi değildir.
HeritageSite fixture({String? summary, String? history}) => HeritageSite(
  id: 'test-site',
  district: 'Test ilçesi',
  name: 'Test eser adı',
  displayName: 'Test eser başlığı',
  type: 'Test türü',
  source: 'Test kaynağı',
  latitude: double.nan,
  longitude: double.nan,
  summary: summary,
  history: history,
);

Future<void> showDetail(WidgetTester tester, HeritageSite site) =>
    tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: HeritageDetailScreen(site: site),
      ),
    );

void main() {
  testWidgets('Modeldeki eser bilgileri ve mevcut tema gösterilir', (
    tester,
  ) async {
    await showDetail(
      tester,
      fixture(summary: 'Test açıklaması', history: 'Test tarihçe metni'),
    );
    expect(find.text('Test eser başlığı'), findsNWidgets(2));
    for (final value in [
      'Test türü',
      'Test ilçesi',
      'Test açıklaması',
      'Test tarihçe metni',
      'Test kaynağı',
    ]) {
      expect(find.text(value), findsOneWidget);
    }
    final context = tester.element(find.byType(HeritageDetailScreen));
    expect(
      Theme.of(context).colorScheme.primary,
      AppTheme.light.colorScheme.primary,
    );
    expect(tester.takeException(), isNull);
  });

  for (final blank in <String?>[null, '', '  \n ']) {
    testWidgets('Boş açıklama ve tarihçe için bilgilendirme: $blank', (
      tester,
    ) async {
      await showDetail(tester, fixture(summary: blank, history: blank));
      expect(
        find.text('Bu eser için kısa açıklama henüz eklenmemiş.'),
        findsOneWidget,
      );
      expect(
        find.text('Bu eserin tarihçesi henüz eklenmemiş.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Uzun tarihçe kaydırılır ve alttaki kaynak erişilebilirdir', (
    tester,
  ) async {
    await showDetail(
      tester,
      fixture(history: List.filled(200, 'Uzun test metni.').join(' ')),
    );
    final source = find.text('Test kaynağı');
    expect(source.hitTestable(), findsNothing);
    await tester.scrollUntilVisible(
      source,
      400,
      scrollable: find.byType(Scrollable),
    );
    expect(source.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Keşfet listesinden seçilen eser açılır ve geri listeye dönülür',
    (tester) async {
      final site = fixture(
        summary: 'Test açıklaması',
        history: 'Test tarihçe metni',
      );
      var loads = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            appBar: AppBar(title: const Text('Keşfet')),
            body: DiscoverScreen(
              loadSites: () async {
                loads++;
                return [site];
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();
      expect(find.byType(HeritageDetailScreen), findsOneWidget);
      expect(
        tester
            .widget<HeritageDetailScreen>(find.byType(HeritageDetailScreen))
            .site,
        same(site),
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(HeritageDetailScreen), findsNothing);
      expect(find.byType(ListTile), findsOneWidget);
      expect(find.text('Keşfet'), findsOneWidget);
      expect(loads, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
