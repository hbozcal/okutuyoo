import 'dart:convert';

import 'package:qr_scanner/core/constants/app_constants.dart';
import 'package:qr_scanner/core/utils/qr_content_parser.dart';
import 'package:qr_scanner/features/history/models/qr_content_type.dart';
import 'package:qr_scanner/features/history/models/qr_history_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kalıcı geçmiş deposu — v1 → v2 migration destekli.
class HistoryRepository {
  HistoryRepository({SharedPreferences? prefs}) : _prefsOverride = prefs;

  final SharedPreferences? _prefsOverride;

  Future<SharedPreferences> get _prefs async =>
      _prefsOverride ?? SharedPreferences.getInstance();

  Future<List<QrHistoryItem>> load() async {
    final prefs = await _prefs;
    final v2 = prefs.getString(AppConstants.historyStorageKeyV2);
    if (v2 != null && v2.isNotEmpty) {
      return _decodeList(v2);
    }

    // Migration from v1
    final v1 = prefs.getString(AppConstants.historyStorageKeyV1);
    if (v1 != null && v1.isNotEmpty) {
      final migrated = _decodeList(v1).map((item) {
        if (item.title.isNotEmpty && item.type != QrContentType.text) {
          return item;
        }
        final parsed = QrContentParser.parse(item.content);
        return item.copyWith(type: parsed.type, title: parsed.title);
      }).toList();
      await save(migrated);
      return migrated;
    }
    return [];
  }

  Future<void> save(List<QrHistoryItem> items) async {
    final prefs = await _prefs;
    final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(AppConstants.historyStorageKeyV2, encoded);
  }

  List<QrHistoryItem> _decodeList(String raw) {
    try {
      final list = jsonDecode(raw);
      if (list is! List) return [];
      final items = <QrHistoryItem>[];
      for (final e in list) {
        if (e is! Map) continue;
        try {
          items.add(QrHistoryItem.fromJson(Map<String, dynamic>.from(e)));
        } catch (_) {
          // Bozuk kayıt atlanır — crash yok.
        }
      }
      return items;
    } catch (_) {
      return [];
    }
  }
}
