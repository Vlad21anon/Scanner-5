import 'dart:io';
import 'dart:math' show Point;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class DocumentCorner {
  final double x;
  final double y;

  DocumentCorner(this.x, this.y);
}

class CustomScannerScreen extends StatefulWidget {
  const CustomScannerScreen({super.key});

  @override
  State<CustomScannerScreen> createState() => _CustomScannerScreenState();
}

class _CustomScannerScreenState extends State<CustomScannerScreen> {
  late CameraController _controller;
  bool _isMultiMode = false;
  List<String> _capturedImages = [];
  bool _isInitialized = false;
  List<DocumentCorner> _corners = [];
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    _controller = CameraController(
      cameras[0],
      ResolutionPreset.high,
    );

    await _controller.initialize();
    await _controller.startImageStream(_processImage);
    setState(() => _isInitialized = true);
  }

  Future<void> _processImage(CameraImage image) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      // Временно используем фиксированные углы для тестирования
      setState(() {
        _corners = [
          DocumentCorner(100, 100),
          DocumentCorner(300, 100),
          DocumentCorner(300, 400),
          DocumentCorner(100, 400),
        ];
      });
    } catch (e) {
      print('Error processing image: $e');
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _captureImage() async {
    if (_corners.isEmpty) return;

    try {
      final image = await _controller.takePicture();
      final croppedImage = await _cropImage(image.path, _corners);

      if (_isMultiMode) {
        setState(() => _capturedImages.add(croppedImage));
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EditScreen(imagePath: croppedImage),
          ),
        );
      }
    } catch (e) {
      print('Error capturing image: $e');
    }
  }

  Future<String> _cropImage(String imagePath, List<DocumentCorner> corners) async {
    try {
      final imageBytes = await File(imagePath).readAsBytes();
      final image = img.decodeImage(imageBytes);
      if (image == null) return imagePath;

      // Для тестирования возвращаем оригинальное изображение
      // В реальном приложении здесь будет логика обрезки
      return imagePath;
    } catch (e) {
      print('Error cropping image: $e');
      return imagePath;
    }
  }

  Widget _buildModeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModeButton("Single", !_isMultiMode),
          _buildModeButton("Multi", _isMultiMode),
        ],
      ),
    );
  }

  Widget _buildModeButton(String title, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _isMultiMode = !isSelected),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: CameraPreview(_controller),
          ),
          CustomPaint(
            size: Size.infinite,
            painter: DocumentBoundsPainter(corners: _corners),
          ),
          SafeArea(
            child: Column(
              children: [
                Container(
                  color: Colors.black.withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      _buildModeSelector(),
                      IconButton(
                        icon: const Icon(Icons.flash_on, color: Colors.white),
                        onPressed: () {
                          _controller.setFlashMode(
                            _controller.value.flashMode == FlashMode.off
                                ? FlashMode.torch
                                : FlashMode.off,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  color: Colors.black.withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.photo_library,
                          color: Colors.white,
                          size: 32,
                        ),
                        onPressed: () {},
                      ),
                      GestureDetector(
                        onTap: _corners.isNotEmpty ? _captureImage : null,
                        child: Container(
                          height: 80,
                          width: 80,
                          decoration: BoxDecoration(
                            color: _corners.isNotEmpty ? Colors.white : Colors.grey,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _corners.isNotEmpty ? Colors.white : Colors.grey,
                              width: 5,
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _corners.isNotEmpty ? Colors.blue : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (_capturedImages.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FilesScreen(images: _capturedImages),
                              ),
                            );
                          }
                        },
                        child: Container(
                          height: 40,
                          width: 40,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            border: Border.all(color: Colors.white),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _capturedImages.isEmpty
                              ? const Icon(Icons.image, color: Colors.white)
                              : Image.file(
                            File(_capturedImages.last),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DocumentBoundsPainter extends CustomPainter {
  final List<DocumentCorner> corners;

  DocumentBoundsPainter({required this.corners});

  @override
  void paint(Canvas canvas, Size size) {
    if (corners.isEmpty) return;

    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();
    path.moveTo(corners[0].x, corners[0].y);

    for (int i = 1; i < corners.length; i++) {
      path.lineTo(corners[i].x, corners[i].y);
    }

    path.close();
    canvas.drawPath(path, paint);

    final cornerPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    for (final corner in corners) {
      canvas.drawCircle(
        Offset(corner.x, corner.y),
        10,
        cornerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(DocumentBoundsPainter oldDelegate) {
    return corners != oldDelegate.corners;
  }
}

class FilesScreen extends StatelessWidget {
  final List<String>? images;

  const FilesScreen({super.key, this.images});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Files")),
      body: images == null || images!.isEmpty
          ? const Center(child: Text("No images"))
          : GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemCount: images!.length,
        itemBuilder: (_, index) => GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditScreen(imagePath: images![index]),
            ),
          ),
          child: Image.file(File(images![index])),
        ),
      ),
    );
  }
}

class EditScreen extends StatelessWidget {
  final String imagePath;

  const EditScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit")),
      body: Center(
        child: Image.file(File(imagePath)),
      ),
    );
  }
}