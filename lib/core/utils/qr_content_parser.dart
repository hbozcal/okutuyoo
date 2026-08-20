import 'package:qr_scanner/core/l10n/app_strings.dart';
import 'package:qr_scanner/core/utils/url_safety.dart';
import 'package:qr_scanner/features/history/models/qr_content_type.dart';

/// Ayrıştırılmış QR içeriği.
class ParsedQrContent {
  const ParsedQrContent({
    required this.raw,
    required this.type,
    required this.title,
    required this.displayValue,
    this.launchUri,
    this.metadata = const {},
    this.isSafeToOpen = false,
  });

  final String raw;
  final QrContentType type;
  final String title;
  final String displayValue;
  final Uri? launchUri;
  final Map<String, String> metadata;
  final bool isSafeToOpen;
}

abstract final class QrContentParser {
  static ParsedQrContent parse(String input, {AppStrings? strings}) {
    final s = strings ?? AppStrings.tr;
    final raw = input.trim();
    if (raw.isEmpty) {
      return ParsedQrContent(
        raw: raw,
        type: QrContentType.text,
        title: s.typeText,
        displayValue: raw,
      );
    }

    final upper = raw.toUpperCase();

    // WIFI:S:ssid;T:WPA;P:pass;;
    if (upper.startsWith('WIFI:')) {
      final meta = _parseWifi(raw);
      return ParsedQrContent(
        raw: raw,
        type: QrContentType.wifi,
        title: s.typeWifi,
        displayValue: meta['ssid']?.isNotEmpty == true ? meta['ssid']! : raw,
        metadata: meta,
        isSafeToOpen: false,
      );
    }

    // BEGIN:VCARD
    if (upper.startsWith('BEGIN:VCARD')) {
      final meta = _parseVCard(raw);
      return ParsedQrContent(
        raw: raw,
        type: QrContentType.contact,
        title: s.typeContact,
        displayValue: meta['name']?.isNotEmpty == true ? meta['name']! : raw,
        metadata: meta,
      );
    }

    // GEO
    if (upper.startsWith('GEO:')) {
      final uri = Uri.tryParse(raw);
      return ParsedQrContent(
        raw: raw,
        type: QrContentType.geo,
        title: s.typeGeo,
        displayValue: raw.substring(4),
        launchUri: uri,
        isSafeToOpen: uri != null && UrlSafety.isAllowedScheme(uri.scheme),
      );
    }

    // SMS / SMSTO
    if (upper.startsWith('SMS:') ||
        upper.startsWith('SMSTO:') ||
        upper.startsWith('MMS:') ||
        upper.startsWith('MMSTO:')) {
      final uri = Uri.tryParse(raw);
      return ParsedQrContent(
        raw: raw,
        type: QrContentType.sms,
        title: s.typeSms,
        displayValue: raw,
        launchUri: uri,
        isSafeToOpen: uri != null && UrlSafety.isAllowedScheme(uri.scheme),
      );
    }

    // Mailto
    if (upper.startsWith('MAILTO:')) {
      final uri = Uri.tryParse(raw);
      final email = uri?.path.isNotEmpty == true ? uri!.path : raw.substring(7);
      return ParsedQrContent(
        raw: raw,
        type: QrContentType.email,
        title: s.typeEmail,
        displayValue: email,
        launchUri: uri,
        metadata: {
          if (uri?.queryParameters['subject'] != null)
            'subject': uri!.queryParameters['subject']!,
        },
        isSafeToOpen: uri != null && UrlSafety.isAllowedScheme(uri.scheme),
      );
    }

    // Tel
    if (upper.startsWith('TEL:')) {
      final number = raw.substring(4);
      final uri = Uri.tryParse(raw);
      return ParsedQrContent(
        raw: raw,
        type: QrContentType.phone,
        title: s.typePhone,
        displayValue: number,
        launchUri: uri,
        isSafeToOpen: uri != null && UrlSafety.isAllowedScheme(uri.scheme),
      );
    }

    // Bare email
    if (_emailRegex.hasMatch(raw) && !raw.contains(' ')) {
      final uri = Uri(scheme: 'mailto', path: raw);
      return ParsedQrContent(
        raw: raw,
        type: QrContentType.email,
        title: s.typeEmail,
        displayValue: raw,
        launchUri: uri,
        isSafeToOpen: true,
      );
    }

    // Bare phone-ish
    if (_phoneRegex.hasMatch(raw)) {
      final uri = Uri(scheme: 'tel', path: raw.replaceAll(' ', ''));
      return ParsedQrContent(
        raw: raw,
        type: QrContentType.phone,
        title: s.typePhone,
        displayValue: raw,
        launchUri: uri,
        isSafeToOpen: true,
      );
    }

    // URL (http/https/www)
    final urlCheck = UrlSafety.analyzeWebUrl(raw);
    if (urlCheck.isWebUrl) {
      return ParsedQrContent(
        raw: raw,
        type: QrContentType.url,
        title: s.typeUrl,
        displayValue: urlCheck.displayHost ?? raw,
        launchUri: urlCheck.uri,
        metadata: {
          if (urlCheck.displayHost != null) 'host': urlCheck.displayHost!,
        },
        isSafeToOpen: urlCheck.isSafeToOpen,
      );
    }

    return ParsedQrContent(
      raw: raw,
      type: QrContentType.text,
      title: s.typeText,
      displayValue: raw,
    );
  }

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _phoneRegex = RegExp(r'^\+?[\d\s\-()]{7,20}$');

  static Map<String, String> _parseWifi(String raw) {
    // WIFI:S:name;T:WPA;P:pass;H:false;;
    final body = raw.substring(5);
    final map = <String, String>{};
    for (final part in body.split(';')) {
      if (part.isEmpty) continue;
      final idx = part.indexOf(':');
      if (idx <= 0) continue;
      final key = part.substring(0, idx).toUpperCase();
      final value = part.substring(idx + 1);
      switch (key) {
        case 'S':
          map['ssid'] = value;
        case 'T':
          map['security'] = value;
        case 'P':
          map['password'] = value;
        case 'H':
          map['hidden'] = value;
      }
    }
    return map;
  }

  static Map<String, String> _parseVCard(String raw) {
    final map = <String, String>{};
    for (final line in raw.split(RegExp(r'\r?\n'))) {
      final upper = line.toUpperCase();
      if (upper.startsWith('FN:')) {
        map['name'] = line.substring(3).trim();
      } else if (upper.startsWith('TEL')) {
        final idx = line.indexOf(':');
        if (idx > 0) map['phone'] = line.substring(idx + 1).trim();
      } else if (upper.startsWith('EMAIL')) {
        final idx = line.indexOf(':');
        if (idx > 0) map['email'] = line.substring(idx + 1).trim();
      } else if (upper.startsWith('ORG:')) {
        map['org'] = line.substring(4).trim();
      }
    }
    return map;
  }
}
