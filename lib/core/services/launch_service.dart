import 'package:flutter/material.dart';
import 'package:qr_scanner/core/l10n/app_strings.dart';
import 'package:qr_scanner/core/utils/qr_content_parser.dart';
import 'package:qr_scanner/core/utils/url_safety.dart';
import 'package:qr_scanner/features/history/models/qr_content_type.dart';
import 'package:url_launcher/url_launcher.dart';

class LaunchService {
  const LaunchService();

  Future<bool> launchUri(Uri uri) async {
    try {
      if (!UrlSafety.isAllowedScheme(uri.scheme)) return false;
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  Future<void> openParsed(
    BuildContext context,
    ParsedQrContent parsed, {
    bool confirmWeb = true,
  }) async {
    final s = AppStrings.ofLocale(
      LocaleLike(Localizations.localeOf(context).languageCode),
    );

    if (!parsed.isSafeToOpen || parsed.launchUri == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(s.unsafeUrl)));
      }
      return;
    }

    final uri = parsed.launchUri!;

    if (confirmWeb && parsed.type == QrContentType.url) {
      final host = uri.host;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(s.confirmOpenTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.confirmOpenBody),
              const SizedBox(height: 12),
              SelectableText(
                host,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(s.continueAction),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    final ok = await launchUri(uri);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.openFailed)));
    }
  }
}
