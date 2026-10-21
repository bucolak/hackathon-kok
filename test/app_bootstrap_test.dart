import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackathon_kok/main.dart';

void main() {
  testWidgets('Başlangıç beklenirken yükleme durumu gösterilir', (
    tester,
  ) async {
    final pending = Completer<void>();
    await tester.pumpWidget(AppBootstrap(connect: () => pending.future));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Bağlantı kuruluyor…'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Giriş hatası yakalanır ve tekrar denenebilir', (tester) async {
    var attempts = 0;
    final pending = Completer<void>();
    await tester.pumpWidget(
      AppBootstrap(
        connect: () async {
          attempts++;
          if (attempts == 1) throw StateError('Giriş başarısız');
          await pending.future;
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('misafir oturumu açılamadı'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Tekrar dene'));
    await tester.pump();

    expect(attempts, 2);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
