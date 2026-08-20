import 'package:flutter/foundation.dart';
import 'package:qr_scanner/core/constants/app_constants.dart';
import 'package:qr_scanner/core/utils/qr_content_parser.dart';
import 'package:qr_scanner/features/history/data/history_repository.dart';
import 'package:qr_scanner/features/history/models/qr_content_type.dart';
import 'package:qr_scanner/features/history/models/qr_history_item.dart';

class HistoryController extends ChangeNotifier {
  HistoryController({HistoryRepository? repository})
    : _repository = repository ?? HistoryRepository();

  final HistoryRepository _repository;
  final List<QrHistoryItem> _items = [];
  bool _ready = false;
  String _query = '';
  HistoryFilter _filter = HistoryFilter.all;

  bool get ready => _ready;
  String get query => _query;
  HistoryFilter get filter => _filter;
  List<QrHistoryItem> get items => List.unmodifiable(_items);

  List<QrHistoryItem> get visibleItems {
    Iterable<QrHistoryItem> list = _items;
    switch (_filter) {
      case HistoryFilter.all:
        break;
      case HistoryFilter.scans:
        list = list.where((e) => e.source == HistorySource.scan);
      case HistoryFilter.created:
        list = list.where((e) => e.source == HistorySource.create);
    }
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((e) {
        return e.content.toLowerCase().contains(q) ||
            e.title.toLowerCase().contains(q) ||
            e.type.name.toLowerCase().contains(q);
      });
    }
    return List.unmodifiable(list);
  }

  Future<void> load() async {
    final loaded = await _repository.load();
    _items
      ..clear()
      ..addAll(loaded);
    _ready = true;
    notifyListeners();
  }

  void setQuery(String value) {
    if (_query == value) return;
    _query = value;
    notifyListeners();
  }

  void setFilter(HistoryFilter filter) {
    if (_filter == filter) return;
    _filter = filter;
    notifyListeners();
  }

  Future<QrHistoryItem?> add({
    required String content,
    required HistorySource source,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return null;

    final parsed = QrContentParser.parse(trimmed);

    // Aynı içerik + kaynak varsa üste taşı (duplicate spam yok).
    _items.removeWhere((e) => e.content == trimmed && e.source == source);

    final item = QrHistoryItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      content: trimmed,
      type: parsed.type,
      source: source,
      createdAt: DateTime.now(),
      title: parsed.title,
      metadata: parsed.metadata,
    );
    _items.insert(0, item);
    if (_items.length > AppConstants.maxHistoryItems) {
      _items.removeRange(AppConstants.maxHistoryItems, _items.length);
    }
    notifyListeners();
    await _persist();
    return item;
  }

  Future<QrHistoryItem?> remove(String id) async {
    final index = _items.indexWhere((e) => e.id == id);
    if (index < 0) return null;
    final removed = _items.removeAt(index);
    notifyListeners();
    await _persist();
    return removed;
  }

  Future<void> restore(QrHistoryItem item, {int? index}) async {
    final i = (index ?? 0).clamp(0, _items.length);
    _items.insert(i, item);
    notifyListeners();
    await _persist();
  }

  Future<void> clear() async {
    _items.clear();
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      await _repository.save(_items);
    } catch (_) {
      // Storage hatası kullanıcıya crash olarak yansımaz.
    }
  }
}

enum HistoryFilter { all, scans, created }
