import 'package:flutter/material.dart';
import 'package:qr_scanner/core/l10n/app_strings.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  const ShareService();

  Future<bool> shareText(String value, {String? subject}) async {
    try {
      await Share.share(value, subject: subject);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> shareFiles(List<XFile> files, {String? text}) async {
    try {
      await Share.shareXFiles(files, text: text);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> shareTextWithFeedback(BuildContext context, String value) async {
    final s = AppStrings.ofLocale(
      LocaleLike(Localizations.localeOf(context).languageCode),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.shareOpening)));
    }
    final ok = await shareText(value);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.shareFailed)));
    }
  }
}
