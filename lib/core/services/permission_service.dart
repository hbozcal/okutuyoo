import 'package:permission_handler/permission_handler.dart';

enum CameraPermissionState {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  unknown,
}

class PermissionService {
  const PermissionService();

  Future<CameraPermissionState> cameraStatus() async {
    final status = await Permission.camera.status;
    return _map(status);
  }

  Future<CameraPermissionState> requestCamera() async {
    final status = await Permission.camera.request();
    return _map(status);
  }

  Future<bool> openAppSettingsPage() => openAppSettings();

  CameraPermissionState _map(PermissionStatus status) {
    if (status.isGranted || status.isLimited) {
      return CameraPermissionState.granted;
    }
    if (status.isPermanentlyDenied) {
      return CameraPermissionState.permanentlyDenied;
    }
    if (status.isRestricted) return CameraPermissionState.restricted;
    if (status.isDenied) return CameraPermissionState.denied;
    return CameraPermissionState.unknown;
  }
}
