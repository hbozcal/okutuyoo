import 'package:flutter/material.dart';
import 'package:qr_scanner/app/theme/app_tokens.dart';
import 'package:qr_scanner/core/services/permission_service.dart';
import 'package:qr_scanner/core/widgets/empty_state.dart';
import 'package:qr_scanner/shared/widgets/action_chip_button.dart';

class CameraPermissionGate extends StatelessWidget {
  const CameraPermissionGate({
    super.key,
    required this.state,
    required this.onRequest,
    required this.onOpenSettings,
  });

  final CameraPermissionState state;
  final VoidCallback onRequest;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final s = stringsOf(context);
    final permanent =
        state == CameraPermissionState.permanentlyDenied ||
        state == CameraPermissionState.restricted;

    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: EmptyStateView(
        icon: Icons.videocam_off_outlined,
        title: s.cameraNeededTitle,
        body: permanent ? s.permissionDeniedBody : s.cameraNeededBody,
        action: FilledButton.icon(
          onPressed: permanent ? onOpenSettings : onRequest,
          icon: Icon(permanent ? Icons.settings : Icons.camera_alt_outlined),
          label: Text(permanent ? s.openSettings : s.grantPermission),
        ),
      ),
    );
  }
}

class CameraErrorView extends StatelessWidget {
  const CameraErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final s = stringsOf(context);
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: EmptyStateView(
        icon: Icons.error_outline,
        title: s.cameraUnavailable,
        body: message,
        action: FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: Text(s.cameraRetry),
        ),
      ),
    );
  }
}

class SuccessFlash extends StatelessWidget {
  const SuccessFlash({super.key, required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 180),
        child: Container(
          color: AppColors.brandBright.withValues(alpha: 0.18),
          alignment: Alignment.center,
          child: const Icon(
            Icons.check_circle_rounded,
            size: 72,
            color: AppColors.brandBright,
          ),
        ),
      ),
    );
  }
}
