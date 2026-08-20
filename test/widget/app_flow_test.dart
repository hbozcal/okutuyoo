import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qr_scanner/app/app.dart';
import 'package:qr_scanner/features/history/data/history_controller.dart';
import 'package:qr_scanner/features/history/models/qr_content_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(const OkutuyoApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('ana sekmeler görünür', (tester) async {
    await pumpApp(tester);

    expect(find.text('Okutuyo'), findsWidgets);
    expect(find.text('Tara'), findsWidgets);
    expect(find.text('Oluştur'), findsOneWidget);
    expect(find.text('Geçmiş'), findsOneWidget);
  });

  testWidgets('oluştur ekranı QR üretir', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Oluştur'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('QR Oluştur'), findsOneWidget);
    expect(find.text('Önizleme burada görünecek'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'merhaba-okutuyo');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(QrImageView), findsOneWidget);
  });

  testWidgets('geçmiş boş state', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Geçmiş'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Henüz kayıt yok'), findsOneWidget);
  });

  test('history controller add/remove', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = HistoryController();
    await controller.load();
    expect(controller.items, isEmpty);

    final item = await controller.add(
      content: 'https://example.com',
      source: HistorySource.scan,
    );
    expect(item, isNotNull);
    expect(controller.items, hasLength(1));
    expect(controller.items.first.type, QrContentType.url);

    await controller.remove(item!.id);
    expect(controller.items, isEmpty);
  });
}
