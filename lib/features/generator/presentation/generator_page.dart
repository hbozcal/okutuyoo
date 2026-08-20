import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qr_scanner/app/theme/app_tokens.dart';
import 'package:qr_scanner/core/l10n/app_strings.dart';
import 'package:qr_scanner/core/services/clipboard_service.dart';
import 'package:qr_scanner/core/services/share_service.dart';
import 'package:qr_scanner/core/utils/url_safety.dart';
import 'package:qr_scanner/features/history/data/history_controller.dart';
import 'package:qr_scanner/features/history/models/qr_content_type.dart';
import 'package:qr_scanner/shared/widgets/action_chip_button.dart';
import 'package:share_plus/share_plus.dart';

enum GeneratorMode { text, url, email, phone, wifi }

class GeneratorPage extends StatefulWidget {
  const GeneratorPage({super.key});

  @override
  State<GeneratorPage> createState() => _GeneratorPageState();
}

class _GeneratorPageState extends State<GeneratorPage> {
  GeneratorMode _mode = GeneratorMode.text;
  final _main = TextEditingController();
  final _secondary = TextEditingController();
  final _tertiary = TextEditingController();
  final _qrKey = GlobalKey();
  String? _error;

  @override
  void dispose() {
    _main.dispose();
    _secondary.dispose();
    _tertiary.dispose();
    super.dispose();
  }

  String? get _payload {
    switch (_mode) {
      case GeneratorMode.text:
        final t = _main.text.trim();
        return t.isEmpty ? null : t;
      case GeneratorMode.url:
        final raw = _main.text.trim();
        if (raw.isEmpty) return null;
        final result = UrlSafety.analyzeWebUrl(raw);
        if (!result.isWebUrl || !result.isSafeToOpen) return null;
        return result.uri!.toString();
      case GeneratorMode.email:
        final email = _main.text.trim();
        if (email.isEmpty) return null;
        return 'mailto:$email';
      case GeneratorMode.phone:
        final phone = _main.text.trim();
        if (phone.isEmpty) return null;
        return 'tel:$phone';
      case GeneratorMode.wifi:
        final ssid = _main.text.trim();
        if (ssid.isEmpty) return null;
        final pass = _secondary.text;
        final type = _tertiary.text.trim().isEmpty
            ? 'WPA'
            : _tertiary.text.trim();
        return 'WIFI:S:$ssid;T:$type;P:$pass;;';
    }
  }

  void _onChanged() {
    String? error;
    if (_mode == GeneratorMode.url && _main.text.trim().isNotEmpty) {
      final result = UrlSafety.analyzeWebUrl(_main.text.trim());
      if (!result.isWebUrl || !result.isSafeToOpen) {
        error = stringsOf(context).invalidUrl;
      }
    }
    setState(() => _error = error);
  }

  Future<void> _saveHistory() async {
    final payload = _payload;
    final s = stringsOf(context);
    if (payload == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.emptyInput)));
      return;
    }
    await context.read<HistoryController>().add(
      content: payload,
      source: HistorySource.create,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(s.savedToHistory)));
  }

  Future<void> _shareQrImage() async {
    final payload = _payload;
    if (payload == null) return;
    final s = stringsOf(context);
    try {
      final boundary =
          _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/okutuyo_qr.png');
      await file.writeAsBytes(bytes.buffer.asUint8List());
      await const ShareService().shareFiles([XFile(file.path)], text: payload);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(s.shareFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = stringsOf(context);
    final payload = _payload;

    return Scaffold(
      appBar: AppBar(title: Text(s.createTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text(
            s.createHint,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final mode in GeneratorMode.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_modeLabel(mode, s)),
                      selected: _mode == mode,
                      onSelected: (_) {
                        setState(() {
                          _mode = mode;
                          _error = null;
                        });
                        _onChanged();
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ..._fields(s),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: AppColors.danger, fontSize: 13),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: payload == null
                ? Container(
                    key: const ValueKey('empty'),
                    height: 240,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.qr_code_2,
                          size: 56,
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: 12),
                        Text(s.previewEmpty),
                      ],
                    ),
                  )
                : Container(
                    key: ValueKey(payload),
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brand.withValues(alpha: 0.16),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Center(
                      child: RepaintBoundary(
                        key: _qrKey,
                        child: ColoredBox(
                          color: Colors.white,
                          child: QrImageView(
                            data: payload,
                            version: QrVersions.auto,
                            size: 220,
                            padding: const EdgeInsets.all(12),
                            gapless: false,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Color(0xFF0F172A),
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Color(0xFF0F172A),
                            ),
                            backgroundColor: Colors.white,
                            errorCorrectionLevel: QrErrorCorrectLevel.M,
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: payload == null
                      ? null
                      : () => const ClipboardService().copyWithFeedback(
                          context,
                          payload,
                        ),
                  icon: const Icon(Icons.copy_rounded),
                  label: Text(s.copy),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: payload == null ? null : _shareQrImage,
                  icon: const Icon(Icons.share_rounded),
                  label: Text(s.shareQr),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: payload == null ? null : _saveHistory,
            icon: const Icon(Icons.bookmark_add_outlined),
            label: Text(s.saveToHistory),
          ),
        ],
      ),
    );
  }

  List<Widget> _fields(AppStrings s) {
    switch (_mode) {
      case GeneratorMode.text:
        return [
          TextField(
            controller: _main,
            minLines: 3,
            maxLines: 6,
            onChanged: (_) => _onChanged(),
            decoration: InputDecoration(hintText: s.modeText),
          ),
        ];
      case GeneratorMode.url:
        return [
          TextField(
            controller: _main,
            keyboardType: TextInputType.url,
            onChanged: (_) => _onChanged(),
            decoration: const InputDecoration(hintText: 'https://'),
          ),
        ];
      case GeneratorMode.email:
        return [
          TextField(
            controller: _main,
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => _onChanged(),
            decoration: InputDecoration(hintText: s.modeEmail),
          ),
        ];
      case GeneratorMode.phone:
        return [
          TextField(
            controller: _main,
            keyboardType: TextInputType.phone,
            onChanged: (_) => _onChanged(),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d+\s\-()]')),
            ],
            decoration: InputDecoration(hintText: s.modePhone),
          ),
        ];
      case GeneratorMode.wifi:
        return [
          TextField(
            controller: _main,
            onChanged: (_) => _onChanged(),
            decoration: const InputDecoration(hintText: 'SSID'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _secondary,
            onChanged: (_) => _onChanged(),
            obscureText: true,
            decoration: const InputDecoration(hintText: 'Password'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _tertiary,
            onChanged: (_) => _onChanged(),
            decoration: const InputDecoration(hintText: 'WPA / WEP / nopass'),
          ),
        ];
    }
  }

  String _modeLabel(GeneratorMode mode, AppStrings s) => switch (mode) {
    GeneratorMode.text => s.modeText,
    GeneratorMode.url => s.modeUrl,
    GeneratorMode.email => s.modeEmail,
    GeneratorMode.phone => s.modePhone,
    GeneratorMode.wifi => s.modeWifi,
  };
}
