import 'package:flutter_test/flutter_test.dart';
import 'package:qr_scanner/core/utils/duplicate_guard.dart';
import 'package:qr_scanner/core/utils/qr_content_parser.dart';
import 'package:qr_scanner/core/utils/url_safety.dart';
import 'package:qr_scanner/features/history/models/qr_content_type.dart';
import 'package:qr_scanner/features/history/models/qr_history_item.dart';

void main() {
  group('UrlSafety', () {
    test('https URL güvenli', () {
      final r = UrlSafety.analyzeWebUrl('https://example.com/path');
      expect(r.isWebUrl, isTrue);
      expect(r.isSafeToOpen, isTrue);
      expect(r.displayHost, 'example.com');
    });

    test('www. öneki https olur', () {
      final r = UrlSafety.analyzeWebUrl('www.example.com');
      expect(r.isWebUrl, isTrue);
      expect(r.uri?.scheme, 'https');
    });

    test('javascript: engellenir', () {
      expect(UrlSafety.toSafeLaunchUri('javascript:alert(1)'), isNull);
      final r = UrlSafety.analyzeWebUrl('javascript:alert(1)');
      expect(r.isSafeToOpen, isFalse);
    });

    test('file: engellenir', () {
      expect(UrlSafety.toSafeLaunchUri('file:///etc/passwd'), isNull);
    });
  });

  group('QrContentParser', () {
    test('URL tipi', () {
      final p = QrContentParser.parse('https://okutuyo.app');
      expect(p.type, QrContentType.url);
      expect(p.isSafeToOpen, isTrue);
    });

    test('email tipi', () {
      final p = QrContentParser.parse('mailto:test@example.com');
      expect(p.type, QrContentType.email);
      expect(p.displayValue, 'test@example.com');
    });

    test('telefon tipi', () {
      final p = QrContentParser.parse('tel:+905551112233');
      expect(p.type, QrContentType.phone);
    });

    test('wifi tipi', () {
      final p = QrContentParser.parse('WIFI:S:EvNet;T:WPA;P:gizli;;');
      expect(p.type, QrContentType.wifi);
      expect(p.metadata['ssid'], 'EvNet');
      expect(p.metadata['password'], 'gizli');
    });

    test('düz metin', () {
      final p = QrContentParser.parse('Merhaba dünya');
      expect(p.type, QrContentType.text);
    });
  });

  group('DuplicateScanGuard', () {
    test('aynı kod cooldown içinde engellenir', () {
      final g = DuplicateScanGuard(cooldown: const Duration(seconds: 4));
      expect(g.allow('ABC'), isTrue);
      expect(g.allow('ABC'), isFalse);
      g.reset();
      expect(g.allow('ABC'), isTrue);
    });

    test('farklı kodlara izin verilir', () {
      final g = DuplicateScanGuard(cooldown: const Duration(seconds: 4));
      expect(g.allow('A'), isTrue);
      expect(g.allow('B'), isTrue);
    });
  });

  group('QrHistoryItem serialization', () {
    test('round-trip', () {
      final item = QrHistoryItem(
        id: '1',
        content: 'https://a.com',
        type: QrContentType.url,
        source: HistorySource.scan,
        createdAt: DateTime.utc(2026, 1, 2, 3, 4),
        title: 'URL',
        metadata: {'host': 'a.com'},
      );
      final restored = QrHistoryItem.fromJson(item.toJson());
      expect(restored.id, item.id);
      expect(restored.content, item.content);
      expect(restored.type, QrContentType.url);
      expect(restored.source, HistorySource.scan);
      expect(restored.metadata['host'], 'a.com');
    });

    test('v1 formatından okur', () {
      final restored = QrHistoryItem.fromJson({
        'id': '9',
        'value': 'hello',
        'kind': 'create',
        'at': '2026-01-01T10:00:00.000',
      });
      expect(restored.content, 'hello');
      expect(restored.source, HistorySource.create);
    });

    test('bozuk kayıt fırlatmaz — repository tarafında atlanır', () {
      expect(() => QrHistoryItem.fromJson({'id': 'x'}), returnsNormally);
    });
  });
}
