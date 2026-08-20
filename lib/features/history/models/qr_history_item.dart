import 'package:qr_scanner/core/utils/qr_content_parser.dart';
import 'package:qr_scanner/features/history/models/qr_content_type.dart';

class QrHistoryItem {
  QrHistoryItem({
    required this.id,
    required this.content,
    required this.type,
    required this.source,
    required this.createdAt,
    required this.title,
    this.metadata = const {},
  });

  final String id;
  final String content;
  final QrContentType type;
  final HistorySource source;
  final DateTime createdAt;
  final String title;
  final Map<String, String> metadata;

  QrHistoryItem copyWith({
    String? id,
    String? content,
    QrContentType? type,
    HistorySource? source,
    DateTime? createdAt,
    String? title,
    Map<String, String>? metadata,
  }) {
    return QrHistoryItem(
      id: id ?? this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      title: title ?? this.title,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'type': type.name,
    'source': source.name,
    'createdAt': createdAt.toIso8601String(),
    'title': title,
    'metadata': metadata,
    // v1 uyumluluk alanları
    'value': content,
    'kind': source.name,
    'at': createdAt.toIso8601String(),
  };

  factory QrHistoryItem.fromJson(Map<String, dynamic> json) {
    final content = (json['content'] ?? json['value'] ?? '') as String;
    final sourceName = (json['source'] ?? json['kind'] ?? 'scan') as String;
    final typeName =
        (json['type'] as String?) ?? QrContentParser.parse(content).type.name;
    final createdRaw = (json['createdAt'] ?? json['at'] ?? '') as String;

    return QrHistoryItem(
      id:
          (json['id'] as String?) ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      content: content,
      type: QrContentType.values.firstWhere(
        (e) => e.name == typeName,
        orElse: () => QrContentType.text,
      ),
      source: HistorySource.values.firstWhere(
        (e) => e.name == sourceName,
        orElse: () => HistorySource.scan,
      ),
      createdAt: DateTime.tryParse(createdRaw) ?? DateTime.now(),
      title: (json['title'] as String?) ?? QrContentParser.parse(content).title,
      metadata: _stringMap(json['metadata']),
    );
  }

  static Map<String, String> _stringMap(dynamic raw) {
    if (raw is! Map) return {};
    return raw.map((k, v) => MapEntry(k.toString(), v.toString()));
  }
}
