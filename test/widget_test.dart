import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qr_scanner/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Okutuyo ana kabuk sekmeleri görünür', (tester) async {
    await tester.pumpWidget(const OkutuyoApp());
    await tester.pump(); // first frame
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Okutuyo'), findsOneWidget);
    expect(find.text('Tara'), findsWidgets);
    expect(find.text('Oluştur'), findsOneWidget);
    expect(find.text('Geçmiş'), findsOneWidget);
  });

  testWidgets('Oluştur sekmesinde metin girilince QR önizleme gelir',
      (tester) async {
    await tester.pumpWidget(const OkutuyoApp());
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Oluştur'));
    await tester.pumpAndSettle();

    expect(find.text('QR Oluştur'), findsOneWidget);
    expect(find.text('Önizleme burada görünecek'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'https://okutuyo.app');
    await tester.pumpAndSettle();

    expect(find.text('Önizleme burada görünecek'), findsNothing);
    expect(find.byType(QrImageView), findsOneWidget);
  });

  testWidgets('Geçmiş boş durumu gösterir', (tester) async {
    await tester.pumpWidget(const OkutuyoApp());
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Geçmiş'));
    await tester.pumpAndSettle();

    expect(find.text('Henüz kayıt yok'), findsOneWidget);
  });

  test('looksLikeUrl yardımcıları', () {
    expect(looksLikeUrl('https://example.com'), isTrue);
    expect(looksLikeUrl('www.example.com'), isTrue);
    expect(looksLikeUrl('sadece metin'), isFalse);
    expect(toLaunchUri('https://example.com')?.host, 'example.com');
  });
}
