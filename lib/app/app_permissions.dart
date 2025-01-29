import 'package:permission_handler/permission_handler.dart';

class AppPermissions {
  static Future<bool> checkCamera() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  static Future<void> requestCamera() async {
    await Permission.camera.request();
  }

  static Future<bool> checkPhotos() async {
    final status = await Permission.photos.status;
    return status.isGranted;
  }

  static Future<void> requestPhotos() async {
    await Permission.photos.request();
  }
}