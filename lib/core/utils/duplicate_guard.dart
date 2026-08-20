import 'package:qr_scanner/core/constants/app_constants.dart';

/// Aynı QR'ın kısa sürede tekrar işlenmesini engeller.
class DuplicateScanGuard {
  DuplicateScanGuard({this.cooldown = AppConstants.duplicateScanCooldown});

  final Duration cooldown;
  String? _last;
  DateTime? _at;

  /// `true` ise tarama işlenebilir.
  bool allow(String value) {
    final now = DateTime.now();
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    if (_last == trimmed && _at != null && now.difference(_at!) < cooldown) {
      return false;
    }
    _last = trimmed;
    _at = now;
    return true;
  }

  void reset() {
    _last = null;
    _at = null;
  }
}
