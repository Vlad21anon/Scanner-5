//
//
// import 'package:camera/camera.dart';
//
// class CameraService {
//   final List<CameraDescription> cameras;
//   late CameraController _controller;
//
//   CameraService(this.cameras);
//
//   Future<CameraController> getController() async {
//     _controller = CameraController(
//       cameras.first,
//       ResolutionPreset.high,
//     );
//     await _controller.initialize();
//     return _controller;
//   }
// }