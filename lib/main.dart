import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// =============================================================================
// Okutuyo — Profesyonel QR Tarayıcı & Oluşturucu
// qr_scanner + qr-code-app-main birleşik tek dosya sürümü
// =============================================================================

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0E12),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const OkutuyoApp());
}

// -----------------------------------------------------------------------------
// Theme & brand
// -----------------------------------------------------------------------------

class AppColors {
  static const ink = Color(0xFF0A0E12);
  static const surface = Color(0xFF12181F);
  static const surfaceHigh = Color(0xFF1A222C);
  static const border = Color(0xFF2A3542);
  static const accent = Color(0xFF2DD4BF);
  static const accentDim = Color(0xFF14B8A6);
  static const warn = Color(0xFFFBBF24);
  static const danger = Color(0xFFF87171);
  static const text = Color(0xFFF1F5F9);
  static const muted = Color(0xFF94A3B8);
}

ThemeData buildOkutuyoTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.dark,
      surface: AppColors.surface,
    ),
    scaffoldBackgroundColor: AppColors.ink,
    fontFamily: 'Roboto',
  );

  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      foregroundColor: AppColors.text,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surfaceHigh,
      contentTextStyle: const TextStyle(color: AppColors.text),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceHigh,
      hintStyle: const TextStyle(color: AppColors.muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.ink,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}

// -----------------------------------------------------------------------------
// Models & persistence
// -----------------------------------------------------------------------------

enum HistoryKind { scan, create }

class HistoryItem {
  HistoryItem({
    required this.id,
    required this.value,
    required this.kind,
    required this.at,
  });

  final String id;
  final String value;
  final HistoryKind kind;
  final DateTime at;

  Map<String, dynamic> toJson() => {
        'id': id,
        'value': value,
        'kind': kind.name,
        'at': at.toIso8601String(),
      };

  factory HistoryItem.fromJson(Map<String, dynamic> json) => HistoryItem(
        id: json['id'] as String,
        value: json['value'] as String,
        kind: HistoryKind.values.firstWhere(
          (e) => e.name == json['kind'],
          orElse: () => HistoryKind.scan,
        ),
        at: DateTime.tryParse(json['at'] as String? ?? '') ?? DateTime.now(),
      );
}

class HistoryStore extends ChangeNotifier {
  static const _key = 'okutuyo_history_v1';
  final List<HistoryItem> _items = [];
  bool _ready = false;

  bool get ready => _ready;
  List<HistoryItem> get items => List.unmodifiable(_items);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    _items.clear();
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        for (final e in list) {
          _items.add(HistoryItem.fromJson(e as Map<String, dynamic>));
        }
      } catch (_) {
        // Bozuk veri yok sayılır.
      }
    }
    _ready = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(_items.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> add(String value, HistoryKind kind) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    _items.removeWhere((e) => e.value == trimmed && e.kind == kind);
    _items.insert(
      0,
      HistoryItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        value: trimmed,
        kind: kind,
        at: DateTime.now(),
      ),
    );
    if (_items.length > 100) {
      _items.removeRange(100, _items.length);
    }
    notifyListeners();
    await _persist();
  }

  Future<void> remove(String id) async {
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
    await _persist();
  }

  Future<void> clear() async {
    _items.clear();
    notifyListeners();
    await _persist();
  }
}

// -----------------------------------------------------------------------------
// Helpers
// -----------------------------------------------------------------------------

bool looksLikeUrl(String value) {
  final v = value.trim();
  if (v.startsWith('http://') || v.startsWith('https://')) return true;
  final uri = Uri.tryParse(v.startsWith('www.') ? 'https://$v' : v);
  return uri != null &&
      uri.hasScheme &&
      (uri.scheme == 'http' || uri.scheme == 'https') &&
      uri.host.contains('.');
}

Uri? toLaunchUri(String value) {
  final v = value.trim();
  if (v.isEmpty) return null;
  if (v.startsWith('http://') || v.startsWith('https://')) {
    return Uri.tryParse(v);
  }
  if (v.startsWith('www.')) return Uri.tryParse('https://$v');
  if (v.startsWith('mailto:') ||
      v.startsWith('tel:') ||
      v.startsWith('sms:') ||
      v.startsWith('WIFI:')) {
    return Uri.tryParse(v);
  }
  return null;
}

Future<void> copyText(BuildContext context, String value) async {
  await Clipboard.setData(ClipboardData(text: value));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Panoya kopyalandı')),
  );
}

Future<void> shareText(String value) async {
  await Share.share(value);
}

Future<void> openIfPossible(BuildContext context, String value) async {
  final uri = toLaunchUri(value);
  if (uri == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Açılabilecek bir bağlantı bulunamadı')),
    );
    return;
  }
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bağlantı açılamadı')),
    );
  }
}

String formatTime(DateTime at) {
  final now = DateTime.now();
  final diff = now.difference(at);
  if (diff.inMinutes < 1) return 'Az önce';
  if (diff.inHours < 1) return '${diff.inMinutes} dk önce';
  if (diff.inDays < 1) return '${diff.inHours} sa önce';
  if (diff.inDays < 7) return '${diff.inDays} gün önce';
  final d = at.day.toString().padLeft(2, '0');
  final m = at.month.toString().padLeft(2, '0');
  return '$d.$m.${at.year}';
}

// -----------------------------------------------------------------------------
// App root
// -----------------------------------------------------------------------------

class OkutuyoApp extends StatelessWidget {
  const OkutuyoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Okutuyo',
      debugShowCheckedModeBanner: false,
      theme: buildOkutuyoTheme(),
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final HistoryStore history = HistoryStore();
  int tab = 0;

  @override
  void initState() {
    super.initState();
    history.load();
  }

  @override
  void dispose() {
    history.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: history,
      builder: (context, _) {
        return Scaffold(
          body: IndexedStack(
            index: tab,
            children: [
              ScannerPage(history: history),
              CreatePage(history: history),
              HistoryPage(history: history),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: tab,
            onDestinationSelected: (i) => setState(() => tab = i),
            backgroundColor: AppColors.surface,
            indicatorColor: AppColors.accent.withValues(alpha: 0.2),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.qr_code_scanner_outlined),
                selectedIcon: Icon(Icons.qr_code_scanner),
                label: 'Tara',
              ),
              NavigationDestination(
                icon: Icon(Icons.qr_code_2_outlined),
                selectedIcon: Icon(Icons.qr_code_2),
                label: 'Oluştur',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history),
                label: 'Geçmiş',
              ),
            ],
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Scanner (qr_scanner UI + qr-code-app flash/flip/actions)
// -----------------------------------------------------------------------------

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key, required this.history});

  final HistoryStore history;

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage>
    with WidgetsBindingObserver {
  late final MobileScannerController controller;
  String? lastCode;
  bool handling = false;
  bool torchOn = false;
  CameraFacing facing = CameraFacing.back;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: facing,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!controller.value.hasCameraPermission) return;
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(controller.start());
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        unawaited(controller.stop());
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (handling) return;
    final raw = capture.barcodes
        .map((b) => b.rawValue)
        .whereType<String>()
        .map((s) => s.trim())
        .firstWhere((s) => s.isNotEmpty, orElse: () => '');
    if (raw.isEmpty) return;

    handling = true;
    await HapticFeedback.mediumImpact();
    await controller.stop();
    setState(() => lastCode = raw);
    await widget.history.add(raw, HistoryKind.scan);

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => ResultSheet(
        value: raw,
        onRescan: () => Navigator.pop(ctx),
      ),
    );

    if (!mounted) return;
    setState(() {});
    await controller.start();
    handling = false;
  }

  Future<void> _toggleTorch() async {
    await controller.toggleTorch();
    setState(() => torchOn = !torchOn);
  }

  Future<void> _flipCamera() async {
    await controller.switchCamera();
    setState(() {
      facing =
          facing == CameraFacing.back ? CameraFacing.front : CameraFacing.back;
      torchOn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final cut = (size.shortestSide * 0.72).clamp(220.0, 320.0);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const _BrandTitle(),
        actions: [
          IconButton(
            tooltip: 'Flaş',
            onPressed: _toggleTorch,
            icon: Icon(
              torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: torchOn ? AppColors.warn : AppColors.text,
            ),
          ),
          IconButton(
            tooltip: 'Kamerayı çevir',
            onPressed: _flipCamera,
            icon: const Icon(Icons.cameraswitch_rounded),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) {
              return _CameraError(error: error, onRetry: controller.start);
            },
          ),
          CustomPaint(
            painter: _ScanOverlayPainter(
              cutOutSize: cut,
              borderColor: AppColors.accent,
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 36,
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: const Text(
                    'QR kodu çerçeveye hizalayın',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (lastCode != null) ...[
                  const SizedBox(height: 14),
                  _LastResultChip(
                    value: lastCode!,
                    onTap: () {
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: AppColors.surface,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(22)),
                        ),
                        builder: (_) => ResultSheet(value: lastCode!),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandTitle extends StatelessWidget {
  const _BrandTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.accent, AppColors.accentDim],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.qr_code_2, size: 18, color: AppColors.ink),
        ),
        const SizedBox(width: 10),
        const Text(
          'Okutuyo',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            fontSize: 20,
          ),
        ),
      ],
    );
  }
}

class _LastResultChip extends StatelessWidget {
  const _LastResultChip({required this.value, required this.onTap});

  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceHigh.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.accent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _CameraError extends StatelessWidget {
  const _CameraError({required this.error, required this.onRetry});

  final MobileScannerException error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final message = switch (error.errorCode) {
      MobileScannerErrorCode.permissionDenied =>
        'Kamera izni gerekli. Ayarlardan izin verin.',
      MobileScannerErrorCode.unsupported =>
        'Bu cihazda kamera taraması desteklenmiyor.',
      _ => 'Kamera başlatılamadı. Tekrar deneyin.',
    };

    return Container(
      color: AppColors.ink,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.videocam_off_outlined,
              size: 48, color: AppColors.muted),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, fontSize: 15),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => onRetry(),
            icon: const Icon(Icons.refresh),
            label: const Text('Yeniden dene'),
          ),
        ],
      ),
    );
  }
}

class _ScanOverlayPainter extends CustomPainter {
  _ScanOverlayPainter({required this.cutOutSize, required this.borderColor});

  final double cutOutSize;
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final cut = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 - 24),
      width: cutOutSize,
      height: cutOutSize,
    );
    final overlay = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(cut, const Radius.circular(22)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
      overlay,
      Paint()..color = Colors.black.withValues(alpha: 0.62),
    );

    final cornerPaint = Paint()
      ..color = borderColor
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 28.0;
    final r = cut;

    void corner(Offset a, Offset b, Offset c) {
      canvas.drawLine(a, b, cornerPaint);
      canvas.drawLine(a, c, cornerPaint);
    }

    corner(r.topLeft, r.topLeft.translate(len, 0), r.topLeft.translate(0, len));
    corner(
      r.topRight,
      r.topRight.translate(-len, 0),
      r.topRight.translate(0, len),
    );
    corner(
      r.bottomLeft,
      r.bottomLeft.translate(len, 0),
      r.bottomLeft.translate(0, -len),
    );
    corner(
      r.bottomRight,
      r.bottomRight.translate(-len, 0),
      r.bottomRight.translate(0, -len),
    );
  }

  @override
  bool shouldRepaint(covariant _ScanOverlayPainter oldDelegate) =>
      oldDelegate.cutOutSize != cutOutSize ||
      oldDelegate.borderColor != borderColor;
}

// -----------------------------------------------------------------------------
// Result sheet
// -----------------------------------------------------------------------------

class ResultSheet extends StatelessWidget {
  const ResultSheet({super.key, required this.value, this.onRescan});

  final String value;
  final VoidCallback? onRescan;

  @override
  Widget build(BuildContext context) {
    final isUrl = looksLikeUrl(value);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Tarama sonucu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isUrl ? 'Bağlantı algılandı' : 'Metin / veri',
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: SelectableText(
                value,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 15,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _ActionChip(
                  icon: Icons.copy_rounded,
                  label: 'Kopyala',
                  onTap: () => copyText(context, value),
                ),
                _ActionChip(
                  icon: Icons.share_rounded,
                  label: 'Paylaş',
                  onTap: () => shareText(value),
                ),
                if (isUrl)
                  _ActionChip(
                    icon: Icons.open_in_new_rounded,
                    label: 'Aç',
                    onTap: () => openIfPossible(context, value),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onRescan?.call();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Yeniden tara'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceHigh,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Create / generate (qr-code-app)
// -----------------------------------------------------------------------------

class CreatePage extends StatefulWidget {
  const CreatePage({super.key, required this.history});

  final HistoryStore history;

  @override
  State<CreatePage> createState() => _CreatePageState();
}

class _CreatePageState extends State<CreatePage> {
  final controller = TextEditingController();
  final focus = FocusNode();

  @override
  void dispose() {
    controller.dispose();
    focus.dispose();
    super.dispose();
  }

  String get value => controller.text.trim();

  Future<void> _saveToHistory() async {
    if (value.isEmpty) return;
    await widget.history.add(value, HistoryKind.create);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Geçmişe kaydedildi')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Oluştur')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          const Text(
            'Metninizi yazın, anında QR kod üretin.',
            style: TextStyle(color: AppColors.muted, fontSize: 14),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: controller,
            focusNode: focus,
            minLines: 3,
            maxLines: 6,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'URL, metin, Wi‑Fi, telefon…',
            ),
          ),
          const SizedBox(height: 22),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: value.isEmpty
                ? Container(
                    key: const ValueKey('empty'),
                    height: 240,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.qr_code_2,
                            size: 56, color: AppColors.border),
                        SizedBox(height: 12),
                        Text(
                          'Önizleme burada görünecek',
                          style: TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  )
                : Container(
                    key: ValueKey(value),
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.18),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Center(
                      child: QrImageView(
                        data: value,
                        version: QrVersions.auto,
                        size: 220,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Color(0xFF0F172A),
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Color(0xFF0F172A),
                        ),
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: value.isEmpty
                      ? null
                      : () => copyText(context, value),
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Kopyala'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: value.isEmpty ? null : () => shareText(value),
                  icon: const Icon(Icons.share_rounded),
                  label: const Text('Paylaş'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: value.isEmpty ? null : _saveToHistory,
            icon: const Icon(Icons.bookmark_add_outlined),
            label: const Text('Geçmişe kaydet'),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// History
// -----------------------------------------------------------------------------

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key, required this.history});

  final HistoryStore history;

  @override
  Widget build(BuildContext context) {
    final items = history.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Geçmiş'),
        actions: [
          if (items.isNotEmpty)
            IconButton(
              tooltip: 'Temizle',
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.surfaceHigh,
                    title: const Text('Geçmişi temizle?'),
                    content: const Text(
                      'Tüm tarama ve oluşturma kayıtları silinir.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Vazgeç'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text(
                          'Sil',
                          style: TextStyle(color: AppColors.danger),
                        ),
                      ),
                    ],
                  ),
                );
                if (ok == true) await history.clear();
              },
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: !history.ready
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? const _EmptyHistory()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _HistoryTile(
                      item: item,
                      onOpen: () {
                        showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: AppColors.surface,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(22)),
                          ),
                          builder: (_) => ResultSheet(value: item.value),
                        );
                      },
                      onDelete: () => history.remove(item.id),
                    );
                  },
                ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 52, color: AppColors.border),
            SizedBox(height: 14),
            Text(
              'Henüz kayıt yok',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Taradığınız veya oluşturduğunuz kodlar burada listelenir.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.item,
    required this.onOpen,
    required this.onDelete,
  });

  final HistoryItem item;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isScan = item.kind == HistoryKind.scan;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: (isScan ? AppColors.accent : AppColors.warn)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isScan ? Icons.qr_code_scanner : Icons.qr_code_2,
                  color: isScan ? AppColors.accent : AppColors.warn,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${isScan ? 'Tarama' : 'Oluşturma'} · ${formatTime(item.at)}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.close_rounded, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
