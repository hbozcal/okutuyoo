/// Merkezi kullanıcı metinleri (TR varsayılan, EN hazır).
/// İleride gen-l10n / ARB'ye taşınabilir.
class AppStrings {
  const AppStrings._(this.localeCode);

  final String localeCode;

  static const tr = AppStrings._('tr');
  static const en = AppStrings._('en');

  static AppStrings ofLocale(LocaleLike locale) {
    if (locale.languageCode.toLowerCase().startsWith('en')) return en;
    return tr;
  }

  bool get isTr => localeCode == 'tr';

  String get appName => 'Okutuyo';
  String get tabScan => isTr ? 'Tara' : 'Scan';
  String get tabCreate => isTr ? 'Oluştur' : 'Create';
  String get tabHistory => isTr ? 'Geçmiş' : 'History';

  String get scanHint =>
      isTr ? 'QR kodu çerçeveye hizalayın' : 'Align the QR code in the frame';
  String get flash => isTr ? 'Flaş' : 'Flash';
  String get switchCamera => isTr ? 'Kamerayı çevir' : 'Switch camera';
  String get rescan => isTr ? 'Yeniden tara' : 'Scan again';
  String get scanning => isTr ? 'Taranıyor…' : 'Scanning…';
  String get scanSuccess => isTr ? 'Kod okundu' : 'Code scanned';

  String get cameraNeededTitle =>
      isTr ? 'Kamera erişimi gerekli' : 'Camera access required';
  String get cameraNeededBody => isTr
      ? 'QR kodları okumak için kamera iznine ihtiyacımız var. İzniniz yalnızca tarama için kullanılır.'
      : 'We need camera access to scan QR codes. Permission is used only for scanning.';
  String get grantPermission => isTr ? 'İzin ver' : 'Allow access';
  String get openSettings => isTr ? 'Ayarları aç' : 'Open settings';
  String get cameraUnavailable =>
      isTr ? 'Kamera kullanılamıyor' : 'Camera unavailable';
  String get cameraRetry => isTr ? 'Yeniden dene' : 'Try again';
  String get permissionDeniedBody => isTr
      ? 'Kamera izni olmadan tarama yapılamaz. Ayarlardan izin verebilirsiniz.'
      : 'Scanning requires camera permission. You can enable it in Settings.';

  String get createTitle => isTr ? 'QR Oluştur' : 'Create QR';
  String get createHint => isTr
      ? 'Metin, URL, e-posta, telefon veya Wi‑Fi bilgisi girin.'
      : 'Enter text, URL, email, phone, or Wi‑Fi details.';
  String get previewEmpty =>
      isTr ? 'Önizleme burada görünecek' : 'Preview will appear here';
  String get saveToHistory => isTr ? 'Geçmişe kaydet' : 'Save to history';
  String get savedToHistory => isTr ? 'Geçmişe kaydedildi' : 'Saved to history';
  String get invalidUrl => isTr ? 'Geçerli bir URL girin' : 'Enter a valid URL';
  String get emptyInput => isTr ? 'Önce içerik girin' : 'Enter content first';
  String get shareQr => isTr ? 'QR paylaş' : 'Share QR';

  String get historyTitle => isTr ? 'Geçmiş' : 'History';
  String get historyEmptyTitle => isTr ? 'Henüz kayıt yok' : 'No history yet';
  String get historyEmptyBody => isTr
      ? 'Taradığınız veya oluşturduğunuz kodlar burada listelenir.'
      : 'Scanned and created codes will appear here.';
  String get searchHint => isTr ? 'Geçmişte ara' : 'Search history';
  String get clearHistory => isTr ? 'Geçmişi temizle' : 'Clear history';
  String get clearHistoryConfirm => isTr
      ? 'Tüm tarama ve oluşturma kayıtları silinir.'
      : 'All scan and create records will be deleted.';
  String get cancel => isTr ? 'Vazgeç' : 'Cancel';
  String get delete => isTr ? 'Sil' : 'Delete';
  String get undo => isTr ? 'Geri al' : 'Undo';
  String get deleted => isTr ? 'Kayıt silindi' : 'Item deleted';
  String get filterAll => isTr ? 'Tümü' : 'All';
  String get filterScan => isTr ? 'Tarama' : 'Scans';
  String get filterCreate => isTr ? 'Oluşturma' : 'Created';
  String get today => isTr ? 'Bugün' : 'Today';
  String get yesterday => isTr ? 'Dün' : 'Yesterday';
  String get thisWeek => isTr ? 'Bu hafta' : 'This week';
  String get older => isTr ? 'Daha eski' : 'Older';

  String get resultTitle => isTr ? 'Tarama sonucu' : 'Scan result';
  String get copy => isTr ? 'Kopyala' : 'Copy';
  String get share => isTr ? 'Paylaş' : 'Share';
  String get open => isTr ? 'Aç' : 'Open';
  String get call => isTr ? 'Ara' : 'Call';
  String get sendEmail => isTr ? 'Mail gönder' : 'Send email';
  String get sendSms => isTr ? 'SMS gönder' : 'Send SMS';
  String get showDetails => isTr ? 'Detaylar' : 'Details';
  String get copied => isTr ? 'Panoya kopyalandı' : 'Copied to clipboard';
  String get shareOpening => isTr ? 'Paylaşım açılıyor…' : 'Opening share…';
  String get copyFailed => isTr ? 'Kopyalanamadı' : 'Could not copy';
  String get shareFailed => isTr ? 'Paylaşılamadı' : 'Could not share';
  String get openFailed => isTr ? 'Açılamadı' : 'Could not open';
  String get unsafeUrl => isTr
      ? 'Bu bağlantı güvenlik nedeniyle açılamaz'
      : 'This link cannot be opened for safety reasons';
  String get confirmOpenTitle => isTr ? 'Bağlantıyı aç?' : 'Open link?';
  String get confirmOpenBody => isTr
      ? 'Aşağıdaki siteye yönlendirileceksiniz:'
      : 'You will be redirected to:';
  String get continueAction => isTr ? 'Devam et' : 'Continue';

  String get typeUrl => 'URL';
  String get typeText => isTr ? 'Metin' : 'Text';
  String get typeEmail => isTr ? 'E-posta' : 'Email';
  String get typePhone => isTr ? 'Telefon' : 'Phone';
  String get typeSms => 'SMS';
  String get typeWifi => 'Wi‑Fi';
  String get typeGeo => isTr ? 'Konum' : 'Location';
  String get typeContact => isTr ? 'Kişi' : 'Contact';
  String get typeUnknown => isTr ? 'Diğer' : 'Other';

  String get modeText => isTr ? 'Metin' : 'Text';
  String get modeUrl => 'URL';
  String get modeEmail => isTr ? 'E-posta' : 'Email';
  String get modePhone => isTr ? 'Telefon' : 'Phone';
  String get modeWifi => 'Wi‑Fi';

  String get justNow => isTr ? 'Az önce' : 'Just now';
  String minutesAgo(int n) => isTr ? '$n dk önce' : '${n}m ago';
  String hoursAgo(int n) => isTr ? '$n sa önce' : '${n}h ago';
  String daysAgo(int n) => isTr ? '$n gün önce' : '${n}d ago';
}

/// Minimal locale surface to avoid importing Material in pure helpers.
class LocaleLike {
  const LocaleLike(this.languageCode);
  final String languageCode;
}
