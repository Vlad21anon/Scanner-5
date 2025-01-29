import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../services/camera_service.dart';

class ScanScreen extends StatefulWidget {
  final CameraService cameraService;

  const ScanScreen({super.key, required this.cameraService});

  @override
  _ScanScreenState createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  late CameraController _controller;
  bool _isMultiScan = false;
  List<XFile> _capturedImages = [];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _controller = await widget.cameraService.getController();
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Document'),
        actions: [
          Switch(
            value: _isMultiScan,
            onChanged: (value) => setState(() => _isMultiScan = value),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: CameraPreview(_controller),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                FloatingActionButton(
                  onPressed: _captureImage,
                  child: const Icon(Icons.camera),
                ),
                if (_isMultiScan)
                  FloatingActionButton(
                    onPressed: _finishMultiScan,
                    child: const Icon(Icons.done),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _captureImage() async {
    final image = await _controller.takePicture();
    setState(() => _capturedImages.add(image));

    if (!_isMultiScan) {
      _navigateToEditor(image);
    }
  }

  void _finishMultiScan() {
    if (_capturedImages.isNotEmpty) {
      _navigateToEditor(_capturedImages.first);
    }
  }

  void _navigateToEditor(XFile image) {
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (_) => ImageEditorScreen(image: File(image.path)),
    //   ),
    // );
  }
}