/// Okutuyo uygulama sabitleri.
abstract final class AppConstants {
  static const appName = 'Okutuyo';
  static const historyStorageKeyV1 = 'okutuyo_history_v1';
  static const historyStorageKeyV2 = 'okutuyo_history_v2';
  static const maxHistoryItems = 200;
  static const duplicateScanCooldown = Duration(seconds: 4);
  static const qrQuietZoneModules = 2;
  static const qrExportSize = 1024.0;
}
