# Okutuyo

Production-ready QR tarayıcı ve oluşturucu (Flutter).

## Özellikler

- Canlı QR tarama (`mobile_scanner`) — flaş, kamera çevirme, animasyonlu çerçeve
- Duplicate scan koruması
- Profesyonel kamera izin akışı
- QR oluşturma (metin, URL, e-posta, telefon, Wi‑Fi)
- Tip analizi (URL, tel, mail, SMS, Wi‑Fi, vCard, geo…)
- Güvenli URL açma (javascript/file engeli + domain onayı)
- Kalıcı geçmiş (arama, filtre, swipe-to-delete + undo)
- Dark / Light tema (sistem)
- TR/EN hazır string katmanı

## Mimari

```
lib/
  main.dart
  app/
  core/
  features/scanner|generator|history
  shared/
```

## Çalıştırma

```bash
flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk --release
```

## Android

- `applicationId`: `app.okutuyo`
- `minSdk`: Flutter default (24)
- Release: R8/ProGuard açık (debug keystore ile imzalı — Play için kendi keystore’unuzu bağlayın)
