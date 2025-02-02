import 'package:permission_handler/permission_handler.dart';

/// Сервис для запроса разрешений на камеру и микрофон
class PermissionService {
  /// Запрашивает разрешения на использование камеры и микрофона.
  /// Возвращает true, если оба разрешения получены, иначе false.
  Future<bool> requestCameraAndMicrophonePermissions() async {
    // Запрашиваем разрешение на камеру
    final cameraStatus = await Permission.camera.request();
    // Запрашиваем разрешение на микрофон
    final microphoneStatus = await Permission.microphone.request();

    // Если оба разрешения предоставлены, возвращаем true
    if (cameraStatus.isGranted && microphoneStatus.isGranted) {
      return true;
    } else {
      // Если какое-либо разрешение не предоставлено,
      // можно предложить пользователю открыть настройки приложения
      await openAppSettings();
      return false;
    }
  }
}
