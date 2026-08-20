import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:qr_scanner/app/theme/app_tokens.dart';
import 'package:qr_scanner/core/l10n/app_strings.dart';
import 'package:qr_scanner/core/services/feedback_service.dart';
import 'package:qr_scanner/core/services/permission_service.dart';
import 'package:qr_scanner/core/utils/duplicate_guard.dart';
import 'package:qr_scanner/core/widgets/app_brand.dart';
import 'package:qr_scanner/features/history/data/history_controller.dart';
import 'package:qr_scanner/features/history/models/qr_content_type.dart';
import 'package:qr_scanner/features/scanner/presentation/result_sheet.dart';
import 'package:qr_scanner/features/scanner/widgets/permission_gate.dart';
import 'package:qr_scanner/features/scanner/widgets/scan_overlay.dart';
import 'package:qr_scanner/shared/widgets/action_chip_button.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key, required this.isActive});

  final ValueNotifier<bool> isActive;

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final _permissions = const PermissionService();
  final _feedback = const FeedbackService();
  final _duplicateGuard = DuplicateScanGuard();

  MobileScannerController? _controller;
  late final AnimationController _scanLine;

  CameraPermissionState _permission = CameraPermissionState.unknown;
  String? _lastCode;
  bool _handling = false;
  bool _showSuccess = false;
  bool _torchOn = false;
  String? _fatalError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scanLine = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    widget.isActive.addListener(_onActiveChanged);
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    final status = await _permissions.cameraStatus();
    if (!mounted) return;
    setState(() => _permission = status);
    if (status == CameraPermissionState.granted) {
      await _ensureController(start: widget.isActive.value);
    }
  }

  Future<void> _ensureController({required bool start}) async {
    _controller ??= MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
      autoStart: false,
    );
    if (start) {
      try {
        await _controller!.start();
        if (mounted) setState(() => _fatalError = null);
      } catch (_) {
        if (mounted) {
          setState(() => _fatalError = stringsOf(context).cameraUnavailable);
        }
      }
    } else {
      await _controller?.stop();
    }
  }

  void _onActiveChanged() {
    if (widget.isActive.value) {
      if (!_scanLine.isAnimating) _scanLine.repeat(reverse: true);
    } else {
      _scanLine.stop();
    }
    unawaited(_syncCameraWithLifecycle());
  }

  Future<void> _syncCameraWithLifecycle() async {
    if (_permission != CameraPermissionState.granted) return;
    final appResumed =
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed ||
        WidgetsBinding.instance.lifecycleState == null;
    final shouldRun = widget.isActive.value && appResumed && !_handling;
    await _ensureController(start: shouldRun);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    unawaited(_syncCameraWithLifecycle());
  }

  @override
  void dispose() {
    widget.isActive.removeListener(_onActiveChanged);
    WidgetsBinding.instance.removeObserver(this);
    _scanLine.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _requestPermission() async {
    final status = await _permissions.requestCamera();
    if (!mounted) return;
    setState(() => _permission = status);
    if (status == CameraPermissionState.granted) {
      await _ensureController(start: widget.isActive.value);
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling || !widget.isActive.value) return;
    final raw = capture.barcodes
        .map((b) => b.rawValue)
        .whereType<String>()
        .map((s) => s.trim())
        .firstWhere((s) => s.isNotEmpty, orElse: () => '');
    if (raw.isEmpty) return;
    if (!_duplicateGuard.allow(raw)) return;

    _handling = true;
    await _feedback.scanSuccess();
    await _controller?.stop();
    if (!mounted) return;

    setState(() {
      _lastCode = raw;
      _showSuccess = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;
    setState(() => _showSuccess = false);

    final history = context.read<HistoryController>();
    await history.add(content: raw, source: HistorySource.scan);

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => ResultSheet(
        raw: raw,
        createdAt: DateTime.now(),
        onRescan: () {
          _duplicateGuard.reset();
        },
      ),
    );

    if (!mounted) return;
    _handling = false;
    await _syncCameraWithLifecycle();
  }

  Future<void> _toggleTorch() async {
    final c = _controller;
    if (c == null) return;
    try {
      await c.toggleTorch();
      if (mounted) setState(() => _torchOn = !_torchOn);
    } catch (_) {}
  }

  Future<void> _flipCamera() async {
    final c = _controller;
    if (c == null) return;
    try {
      await c.switchCamera();
      if (mounted) setState(() => _torchOn = false);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final s = stringsOf(context);

    if (_permission != CameraPermissionState.granted) {
      return Scaffold(
        appBar: AppBar(title: const AppBrandTitle()),
        body: CameraPermissionGate(
          state: _permission,
          onRequest: _requestPermission,
          onOpenSettings: () => _permissions.openAppSettingsPage(),
        ),
      );
    }

    if (_fatalError != null || _controller == null) {
      return Scaffold(
        appBar: AppBar(title: const AppBrandTitle()),
        body: CameraErrorView(
          message: _fatalError ?? s.cameraNeededBody,
          onRetry: () => _ensureController(start: true),
        ),
      );
    }

    final size = MediaQuery.sizeOf(context);
    final cut = (size.shortestSide * 0.72).clamp(220.0, 320.0);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const AppBrandTitle(),
        actions: [
          IconButton(
            tooltip: s.flash,
            onPressed: _toggleTorch,
            icon: Icon(
              _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: _torchOn ? AppColors.warning : null,
            ),
          ),
          IconButton(
            tooltip: s.switchCamera,
            onPressed: _flipCamera,
            icon: const Icon(Icons.cameraswitch_rounded),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller!,
            onDetect: _onDetect,
            errorBuilder: (context, error) {
              return CameraErrorView(
                message: _mapScannerError(error, s),
                onRetry: () => _ensureController(start: true),
              );
            },
          ),
          ScanOverlay(cutOutSize: cut, animation: _scanLine),
          SuccessFlash(visible: _showSuccess),
          Positioned(
            left: 24,
            right: 24,
            bottom: 36,
            child: Column(
              children: [
                Semantics(
                  liveRegion: true,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      _handling ? s.scanSuccess : s.scanHint,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                if (_lastCode != null) ...[
                  const SizedBox(height: 14),
                  _LastResultChip(
                    value: _lastCode!,
                    onTap: () {
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(22),
                          ),
                        ),
                        builder: (_) => ResultSheet(raw: _lastCode!),
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

  String _mapScannerError(MobileScannerException error, AppStrings s) {
    return switch (error.errorCode) {
      MobileScannerErrorCode.permissionDenied => s.permissionDeniedBody,
      MobileScannerErrorCode.unsupported => s.cameraUnavailable,
      _ => s.cameraUnavailable,
    };
  }
}

class _LastResultChip extends StatelessWidget {
  const _LastResultChip({required this.value, required this.onTap});

  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: scheme.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
