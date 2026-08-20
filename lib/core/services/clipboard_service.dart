import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_scanner/core/l10n/app_strings.dart';

class ClipboardService {
  const ClipboardService();

  Future<bool> copy(String value) async {
    try {
      await Clipboard.setData(ClipboardData(text: value));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> copyWithFeedback(BuildContext context, String value) async {
    final s = AppStrings.ofLocale(
      LocaleLike(Localizations.localeOf(context).languageCode),
    );
    final ok = await copy(value);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(ok ? s.copied : s.copyFailed)));
  }
}
