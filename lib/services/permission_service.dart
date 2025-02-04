import 'package:permission_handler/permission_handler.dart';

/// Сервис для запроса разрешений на камеру и микрофон
class PermissionService {
  /// Запрашивает разрешения на использование камеры и микрофона.
  /// Возвращает true, если оба разрешения получены, иначе false.
  Future<bool> requestCameraAndMicrophonePermissions() async {
    // Проверяем статус разрешения на камеру
    final cameraStatus = await Permission.camera.status;
    // Проверяем статус разрешения на микрофон
    final microphoneStatus = await Permission.microphone.status;

    // Если оба разрешения уже предоставлены, возвращаем true
    if (cameraStatus.isGranted && microphoneStatus.isGranted) {
      return true;
    }

    // Запрашиваем недостающие разрешения
    final statuses = await [
      if (!cameraStatus.isGranted) Permission.camera,
      if (!microphoneStatus.isGranted) Permission.microphone,
    ].request();

    // Проверяем, предоставлены ли теперь оба разрешения
    return statuses[Permission.camera]?.isGranted == true &&
        statuses[Permission.microphone]?.isGranted == true;
  }
}
