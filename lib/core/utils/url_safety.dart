/// URL / URI güvenlik analizi.
class UrlSafetyResult {
  const UrlSafetyResult({
    required this.isWebUrl,
    required this.isSafeToOpen,
    this.uri,
    this.displayHost,
    this.reason,
  });

  final bool isWebUrl;
  final bool isSafeToOpen;
  final Uri? uri;
  final String? displayHost;
  final String? reason;
}

abstract final class UrlSafety {
  static const allowedSchemes = {
    'https',
    'http',
    'mailto',
    'tel',
    'sms',
    'smsto',
    'geo',
  };

  static const blockedSchemes = {
    'javascript',
    'file',
    'data',
    'blob',
    'intent',
    'content',
    'about',
    'vbscript',
  };

  static bool isAllowedScheme(String? scheme) {
    if (scheme == null || scheme.isEmpty) return false;
    final s = scheme.toLowerCase();
    if (blockedSchemes.contains(s)) return false;
    return allowedSchemes.contains(s);
  }

  /// Web URL'leri için parse + güvenlik.
  static UrlSafetyResult analyzeWebUrl(String input) {
    final raw = input.trim();
    if (raw.isEmpty) {
      return const UrlSafetyResult(isWebUrl: false, isSafeToOpen: false);
    }

    final lower = raw.toLowerCase();
    for (final bad in blockedSchemes) {
      if (lower.startsWith('$bad:')) {
        return const UrlSafetyResult(
          isWebUrl: false,
          isSafeToOpen: false,
          reason: 'blocked_scheme',
        );
      }
    }

    String candidate = raw;
    if (raw.startsWith('www.')) {
      candidate = 'https://$raw';
    }

    final uri = Uri.tryParse(candidate);
    if (uri == null) {
      return const UrlSafetyResult(isWebUrl: false, isSafeToOpen: false);
    }

    final scheme = uri.scheme.toLowerCase();
    final isHttp = scheme == 'http' || scheme == 'https';
    if (!isHttp) {
      return const UrlSafetyResult(isWebUrl: false, isSafeToOpen: false);
    }

    if (uri.host.isEmpty || !uri.host.contains('.')) {
      return UrlSafetyResult(
        isWebUrl: true,
        isSafeToOpen: false,
        uri: uri,
        reason: 'invalid_host',
      );
    }

    // Prefer https display; still allow http open with caution.
    return UrlSafetyResult(
      isWebUrl: true,
      isSafeToOpen: true,
      uri: uri,
      displayHost: uri.host,
    );
  }

  /// Genel launch URI üretimi (güvenli şemalar).
  static Uri? toSafeLaunchUri(String input) {
    final raw = input.trim();
    if (raw.isEmpty) return null;

    final lower = raw.toLowerCase();
    for (final bad in blockedSchemes) {
      if (lower.startsWith('$bad:')) return null;
    }

    if (raw.startsWith('www.')) {
      return Uri.tryParse('https://$raw');
    }

    final uri = Uri.tryParse(raw);
    if (uri == null) return null;
    if (!isAllowedScheme(uri.scheme)) return null;
    if ((uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isEmpty) {
      return null;
    }
    return uri;
  }
}
