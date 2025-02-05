import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart'; // для compute
import 'package:flutter/material.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'package:image/image.dart' as img;
import 'package:owl_tech_pdf_scaner/app/app_colors.dart';
import 'package:owl_tech_pdf_scaner/widgets/paper_border_painter.dart';
import 'package:path_provider/path_provider.dart'; // для временной папки
import 'package:path/path.dart' as path;
import 'package:visibility_detector/visibility_detector.dart';

import '../screens/loading_screen.dart';

/// Виджет, который реализует сканирование документа с использованием камеры.
/// После нажатия на кнопку «Сфотографировать» происходит обработка изображения в отдельном изоляте.
class DocumentScannerWidget extends StatefulWidget {
  const DocumentScannerWidget({super.key});

  @override
  State<DocumentScannerWidget> createState() => DocumentScannerWidgetState();
}

class DocumentScannerWidgetState extends State<DocumentScannerWidget>
    with WidgetsBindingObserver {
  late CameraController _controller;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  List<Offset>? _paperCorners; // Найденные 4 угла (исходные координаты)
  Size? _cameraImageSize; // Размер исходного кадра (width, height)
  Uint8List? _lastPngBytes; // Последний обработанный кадр в PNG
  String? _croppedImagePath;

  // Дополнительные параметры для корректировки смещения
  double offsetAdjustmentX = 0;
  double offsetAdjustmentY = -55; // можно настроить под ваш дизайн

  int _frameCounter = 0; // Счётчик кадров для обработки каждого N-ого кадра
  final int _processEveryNthFrame = 2; // например, обрабатывать каждый второй кадр
  bool _isVisible = true; // Флаг, отражающий, отображается ли виджет на экране

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _initCamera();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    offsetAdjustmentY = getOffsetAdjustmentY(context);
  }

  double getOffsetAdjustmentY(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    if (screenHeight >= 800) {
      return -120;
    } else {
      return -90;
    }
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    _controller = CameraController(
      cameras[0],
      ResolutionPreset.max,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    await _controller.initialize();
    if (!mounted) return;
    setState(() {
      _isCameraInitialized = true;
    });
    _controller.startImageStream((CameraImage image) {
      // Если виджет не виден – прекращаем обработку кадра
      if (!_isVisible) return;

      _frameCounter++;
      if (_frameCounter % _processEveryNthFrame != 0) return;

      if (!_isProcessing) {
        _isProcessing = true;
        _processCameraImage(image);
      }
    });
  }

  /// Останавливает поток изображений камеры, если он запущен.
  void stopScanner() {
    if (_isCameraInitialized && _controller.value.isStreamingImages) {
      _controller.stopImageStream();
      debugPrint("Сканер остановлен");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_controller.value.isStreamingImages) {
      _controller.stopImageStream();
    }
    _controller.dispose();
    super.dispose();
  }

  /// Отслеживаем изменения жизненного цикла приложения
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isCameraInitialized || !_controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _isVisible = false; // Флаг скрытости
      _controller.stopImageStream();
      debugPrint("Приложение не активно, сканер остановлен");
    } else if (state == AppLifecycleState.resumed) {
      _isVisible = true;
      if (!_controller.value.isStreamingImages) {
        _controller.startImageStream((CameraImage image) {
          if (!_isVisible) return;
          _frameCounter++;
          if (_frameCounter % _processEveryNthFrame != 0) return;
          if (!_isProcessing) {
            _isProcessing = true;
            _processCameraImage(image);
          }
        });
      }
    }
  }

  /// Преобразует CameraImage (YUV420) в PNG-байты с использованием пакета image.
  Uint8List convertYUV420ToPNG(CameraImage image) {
    // Реализация (без изменений)
    if (image.planes.length == 1) {
      final plane = image.planes[0];
      final img.Image bgraImage = img.Image.fromBytes(
        width: image.width,
        height: image.height,
        bytes: plane.bytes.buffer,
        order: img.ChannelOrder.bgra,
      );
      return Uint8List.fromList(img.encodePng(bgraImage));
    } else if (image.planes.length == 2) {
      final int width = image.width;
      final int height = image.height;
      final img.Image rgbImage = img.Image(width: width, height: height);

      final planeY = image.planes[0];
      final planeUV = image.planes[1];
      final int uvRowStride = planeUV.bytesPerRow;

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          int yp = planeY.bytes[y * planeY.bytesPerRow + x];
          int uvIndex = (y ~/ 2) * uvRowStride + (x ~/ 2) * 2;
          int u, v;
          if (Platform.isIOS) {
            v = planeUV.bytes[uvIndex];
            u = planeUV.bytes[uvIndex + 1];
          } else {
            u = planeUV.bytes[uvIndex];
            v = planeUV.bytes[uvIndex + 1];
          }
          double yVal = yp.toDouble();
          double uVal = u.toDouble() - 128.0;
          double vVal = v.toDouble() - 128.0;
          int r = (yVal + 1.402 * vVal).round().clamp(0, 255);
          int g =
          (yVal - 0.344136 * uVal - 0.714136 * vVal).round().clamp(0, 255);
          int b = (yVal + 1.772 * uVal).round().clamp(0, 255);
          rgbImage.setPixelRgba(x, y, r, g, b, 255);
        }
      }
      return Uint8List.fromList(img.encodePng(rgbImage));
    } else if (image.planes.length >= 3) {
      final int width = image.width;
      final int height = image.height;
      final img.Image rgbImage = img.Image(width: width, height: height);

      final planeY = image.planes[0];
      final planeU = image.planes[1];
      final planeV = image.planes[2];

      final int uvRowStride = planeU.bytesPerRow;
      final int uvPixelStride = planeU.bytesPerPixel ?? 0;

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          int yp = planeY.bytes[y * planeY.bytesPerRow + x];
          int uvIndex = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;
          int up = planeV.bytes[uvIndex];
          int vp = planeU.bytes[uvIndex];
          double yVal = yp.toDouble();
          double uVal = up.toDouble() - 128.0;
          double vVal = vp.toDouble() - 128.0;
          int r = (yVal + 1.402 * vVal).round().clamp(0, 255);
          int g =
          (yVal - 0.344136 * uVal - 0.714136 * vVal).round().clamp(0, 255);
          int b = (yVal + 1.772 * uVal).round().clamp(0, 255);
          rgbImage.setPixelRgba(x, y, r, g, b, 255);
        }
      }
      return Uint8List.fromList(img.encodePng(rgbImage));
    } else {
      throw Exception(
          "Неподдерживаемый формат камеры: ожидается 1 (BGRA), 2 (NV12) или 3 (YUV420) плоскости.");
    }
  }

  Map<String, dynamic> cameraImageToMap(CameraImage image) {
    if (image.planes.isEmpty) {
      throw Exception("Нет данных в image.planes");
    }
    final map = <String, dynamic>{
      'width': image.width,
      'height': image.height,
      'planesCount': image.planes.length,
      'plane0': {
        'bytes': List<int>.from(image.planes[0].bytes),
        'rowStride': image.planes[0].bytesPerRow,
        'pixelStride': image.planes[0].bytesPerPixel,
      },
    };

    if (image.planes.length > 1) {
      map['plane1'] = {
        'bytes': List<int>.from(image.planes[1].bytes),
        'rowStride': image.planes[1].bytesPerRow,
        'pixelStride': image.planes[1].bytesPerPixel,
      };
    }

    if (image.planes.length > 2) {
      map['plane2'] = {
        'bytes': List<int>.from(image.planes[2].bytes),
        'rowStride': image.planes[2].bytesPerRow,
        'pixelStride': image.planes[2].bytesPerPixel,
      };
    }

    return map;
  }

  Future<void> _processCameraImage(CameraImage image) async {
    try {
      _cameraImageSize = Size(image.width.toDouble(), image.height.toDouble());

      // Преобразуем CameraImage в Map
      Map<String, dynamic> imageMap = cameraImageToMap(image);

      // Вызываем функцию через compute
      Uint8List pngBytes = await compute(convertYUV420ToPNGFromMap, imageMap);

      _lastPngBytes = pngBytes;
      debugPrint("Начинаем обработку кадра. Размер изображения: ${image.width}x${image.height}");



      // Если виджет не виден, нет смысла выполнять дальнейшую обработку
      if (!_isVisible) return;

      final result = await compute(processFrameInIsolate, {
        'pngBytes': pngBytes,
        'width': image.width,
        'height': image.height,
      });

      if (result == null) {
        debugPrint("Результат из изолята равен null");
        return;
      }

      List<List<double>> cornersList =
      result['corners'] as List<List<double>>;

      debugPrint("Получено ${cornersList.length} углов из изолята");

      List<Offset> corners = [];
      for (int i = 0; i < cornersList.length; i++) {
        var pt = cornersList[i];
        debugPrint("Угол $i: (${pt[0]}, ${pt[1]})");
        corners.add(Offset(pt[0], pt[1]));
      }

      if (mounted) {
        setState(() {
          _paperCorners = corners.length == 4 ? corners : null;
        });
      }
    } catch (e, stackTrace) {
      debugPrint("Ошибка в _processCameraImage: $e");
      debugPrint("$stackTrace");
    } finally {
      _isProcessing = false;
    }
  }

  Future<String?> cropImage() async {
    // Проверяем, что есть изображение для сохранения
    if (_lastPngBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет изображения для сохранения')),
      );
      return null;
    }

    List<int> imageBytes;

    // Если есть корректный контур (4 угла), выполняем обрезку в отдельном isolate
    if (_paperCorners != null && _paperCorners!.length == 4) {
      imageBytes = await compute(cropFrameInIsolate, {
        'pngBytes': _lastPngBytes,
        'corners': _paperCorners!.map((pt) => [pt.dx, pt.dy]).toList(),
        'width': _cameraImageSize!.width.toInt(),
        'height': _cameraImageSize!.height.toInt(),
      });
    } else {
      // Если углов нет или их количество не равно 4, выполняем преобразование (цвет, поворот, кодирование в PNG)
      Uint8List pngBytes = _lastPngBytes!;

      // Если _paperCorners равен null, можно создать пустой список или игнорировать его
      List<dynamic> cornersDynamic = _paperCorners != null
          ? _paperCorners!.map((pt) => [pt.dx, pt.dy]).toList()
          : [];

      // Декодируем исходное изображение в cv.Mat в цветном режиме
      cv.Mat mat = cv.imdecode(pngBytes, cv.IMREAD_COLOR);

      // Преобразуем цвет из BGR (по умолчанию OpenCV) в RGB
      cv.Mat rgbMat = cv.cvtColor(mat, cv.COLOR_BGR2RGB);
      debugPrint("Изображение после cvtColor: channels = ${rgbMat.channels}");

      // Если устройство не iOS, поворачиваем изображение на 90° по часовой стрелке
      cv.Mat finalMat;
      if (!Platform.isIOS) {
        finalMat = cv.rotate(rgbMat, cv.ROTATE_90_CLOCKWISE);
        debugPrint("Изображение повернуто: ширина = ${finalMat.width}, высота = ${finalMat.height}");
        rgbMat.dispose();
      } else {
        finalMat = rgbMat;
      }

      // Кодируем итоговое изображение в PNG
      final result = cv.imencode(".png", finalMat);
      if (!result.$1) {
        throw Exception("Ошибка при кодировании изображения в PNG");
      }
      Uint8List pngBytesf = result.$2;
      debugPrint("Размер итогового изображения (PNG): ${pngBytesf.lengthInBytes} байт");

      finalMat.dispose();
      imageBytes = pngBytesf;
    }

    // Если полученные байты не пустые, сохраняем файл
    if (imageBytes.isNotEmpty) {
      try {
        final Directory appDocDir = await getApplicationDocumentsDirectory();
        final String fileName =
            "cropped_${DateTime.now().millisecondsSinceEpoch}.png";
        final String filePath = path.join(appDocDir.path, fileName);
        final File file = File(filePath);
        await file.writeAsBytes(imageBytes);

        if (mounted) {
          setState(() {
            _croppedImagePath = filePath;
          });
        }

        return _croppedImagePath;
      } catch (e) {
        debugPrint("Ошибка при сохранении файла: $e");
      }
    }
    return null;
  }


  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: const Key("document-scanner-widget"),
      onVisibilityChanged: (VisibilityInfo info) {
        // Обновляем флаг видимости в зависимости от процента отображения
        bool isNowVisible = info.visibleFraction > 0;
        if (_isVisible != isNowVisible) {
          if (mounted) {
            setState(() {
              _isVisible = isNowVisible;
            });
          }

          if (!isNowVisible) {
            stopScanner();
          } else {
            // При возвращении на экран можно заново запустить imageStream,
            // если контроллер инициализирован и не работает
            if (_isCameraInitialized && !_controller.value.isStreamingImages) {
              _controller.startImageStream((CameraImage image) {
                if (!_isVisible) return;
                _frameCounter++;
                if (_frameCounter % _processEveryNthFrame != 0) return;
                if (!_isProcessing) {
                  _isProcessing = true;
                  _processCameraImage(image);
                }
              });
            }
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.black,
        body: _isCameraInitialized
            ? LayoutBuilder(
          builder: (context, constraints) {
            return Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  CameraPreview(_controller),
                  if (_paperCorners != null && _cameraImageSize != null)
                    CustomPaint(
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                      painter: PaperBorderPainter(
                        corners: _paperCorners!,
                        cameraImageSize: _cameraImageSize!,
                        rotateClockwise: true,
                        offsetAdjustmentX: offsetAdjustmentX,
                        offsetAdjustmentY: offsetAdjustmentY,
                      ),
                    ),
                ],
              ),
            );
          },
        )
            : LoadingScreen(),
      ),
    );
  }
}

/// Функция, которую можно запускать через compute().
Uint8List convertYUV420ToPNGFromMap(Map<String, dynamic> params) {
  final int width = params['width'];
  final int height = params['height'];
  final int planesCount = params['planesCount'];

  if (planesCount == 1) {
    final List<int> planeBytes = List<int>.from(params['plane0']['bytes']);
    // Здесь ожидается ByteBuffer, поэтому:
    final img.Image bgraImage = img.Image.fromBytes(
      width: width,
      height: height,
      bytes: Uint8List.fromList(planeBytes).buffer,
      order: img.ChannelOrder.bgra,
    );
    return Uint8List.fromList(img.encodePng(bgraImage));
  } else if (planesCount == 2) {
    final List<int> planeY = List<int>.from(params['plane0']['bytes']);
    final int rowStrideY = params['plane0']['rowStride'];
    final List<int> planeUV = List<int>.from(params['plane1']['bytes']);
    final int uvRowStride = params['plane1']['rowStride'];
    final int uvPixelStride = params['plane1']['pixelStride'] ?? 2;

    final img.Image rgbImage = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        int yp = planeY[y * rowStrideY + x];
        int uvIndex = (y ~/ 2) * uvRowStride + (x ~/ 2) * 2;
        int u, v;
        if (Platform.isIOS) {
          v = planeUV[uvIndex];
          u = planeUV[uvIndex + 1];
        } else {
          u = planeUV[uvIndex];
          v = planeUV[uvIndex + 1];
        }
        double yVal = yp.toDouble();
        double uVal = u.toDouble() - 128.0;
        double vVal = v.toDouble() - 128.0;
        int r = (yVal + 1.402 * vVal).round().clamp(0, 255);
        int g = (yVal - 0.344136 * uVal - 0.714136 * vVal).round().clamp(0, 255);
        int b = (yVal + 1.772 * uVal).round().clamp(0, 255);
        rgbImage.setPixelRgba(x, y, r, g, b, 255);
      }
    }
    return Uint8List.fromList(img.encodePng(rgbImage));
  } else if (planesCount >= 3) {
    final List<int> planeY = List<int>.from(params['plane0']['bytes']);
    final int rowStrideY = params['plane0']['rowStride'];
    final List<int> planeU = List<int>.from(params['plane1']['bytes']);
    final int rowStrideU = params['plane1']['rowStride'];
    final List<int> planeV = List<int>.from(params['plane2']['bytes']);
    final int rowStrideV = params['plane2']['rowStride'];
    final int uvPixelStride = params['plane1']['pixelStride'] ?? 1;

    final img.Image rgbImage = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        int yp = planeY[y * rowStrideY + x];
        int uvIndex = (y ~/ 2) * rowStrideU + (x ~/ 2) * uvPixelStride;
        int up = planeV[uvIndex];
        int vp = planeU[uvIndex];
        double yVal = yp.toDouble();
        double uVal = up.toDouble() - 128.0;
        double vVal = vp.toDouble() - 128.0;
        int r = (yVal + 1.402 * vVal).round().clamp(0, 255);
        int g = (yVal - 0.344136 * uVal - 0.714136 * vVal).round().clamp(0, 255);
        int b = (yVal + 1.772 * uVal).round().clamp(0, 255);
        rgbImage.setPixelRgba(x, y, r, g, b, 255);
      }
    }
    return Uint8List.fromList(img.encodePng(rgbImage));
  } else {
    throw Exception("Неподдерживаемый формат камеры: ожидается 1 (BGRA), 2 (NV12) или 3 (YUV420) плоскости.");
  }
}

/// Функция, выполняемая в изоляте для определения контура документа.
/// Принимает Map с ключами:
/// 'pngBytes' – Uint8List с PNG-данными,
/// 'width', 'height' – размеры исходного кадра.
/// Возвращает List<List<double>> – список 4-х точек, каждая из которых представлена как [x, y].
Future<Map<String, dynamic>> processFrameInIsolate(
    Map<String, dynamic> params) async {
  try {
    Uint8List pngBytes = params['pngBytes'];
    int width = params['width'];
    int height = params['height'];
    double cannyThreshold1 = params['cannyThreshold1'] ?? 50.0;
    double cannyThreshold2 = params['cannyThreshold2'] ?? 150.0;
    int apertureSize = params['apertureSize']?.toInt() ?? 3;
    double approxPolyFactor = params['approxPolyFactor'] ?? 0.02;

    // Декодируем изображение в cv.Mat
    cv.Mat mat = cv.imdecode(pngBytes, cv.IMREAD_COLOR);
    if (mat == null) {
      return {
        'corners': <List<double>>[],
        'preview': Uint8List(0),
      };
    }

    cv.Mat gray = await cv.cvtColorAsync(mat, cv.COLOR_BGR2GRAY);
    cv.Mat blur = await cv.gaussianBlurAsync(gray, (5, 5), 0);
    cv.Mat edges = await cv.cannyAsync(blur, cannyThreshold1, cannyThreshold2,
        apertureSize: apertureSize);

    // Кодируем промежуточное изображение (краев) для предпросмотра
    final previewResult = cv.imencode('.png', edges);
    Uint8List previewPng = Uint8List(0);
    if (previewResult.$1) {
      previewPng = previewResult.$2;
    }

    var contoursTuple =
        cv.findContours(edges, cv.RETR_LIST, cv.CHAIN_APPROX_SIMPLE);
    var contours = contoursTuple.$1;

    dynamic paperContour;
    double maxArea = 0;
    for (int i = 0; i < contours.length; i++) {
      var contour = contours[i];
      double peri = cv.arcLength(contour, true);
      var approx = cv.approxPolyDP(contour, approxPolyFactor * peri, true);
      if (approx.length == 4) {
        double area = cv.contourArea(approx);
        if (area > maxArea && area > 1000) {
          maxArea = area;
          paperContour = approx;
        }
      }
    }

    List<List<double>> resultCorners = [];
    if (paperContour != null) {
      for (int i = 0; i < paperContour.length; i++) {
        var pt = paperContour[i];
        resultCorners.add([pt.x.toDouble(), pt.y.toDouble()]);
      }
    }

    // Освобождаем ресурсы
    mat.dispose();
    gray.dispose();
    blur.dispose();
    edges.dispose();

    // Обратите внимание: угловые точки отправляются без каких-либо преобразований (поворота)
    return {
      'corners': resultCorners,
      'preview': previewPng,
    };
  } catch (e, stackTrace) {
    debugPrint("Ошибка в processFrameInIsolate: $e");
    debugPrint("$stackTrace");
    return {
      'corners': <List<double>>[],
      'preview': Uint8List(0),
    };
  }
}

/// Упорядочивает 4 точки так, чтобы получилась последовательность:
/// [верхний левый, верхний правый, нижний правый, нижний левый]
List<cv.Point2f> orderPoints(List<cv.Point2f> pts) {
  if (pts.length != 4) {
    throw Exception('Ожидается ровно 4 точки');
  }

  // Инициализируем все четыре переменные первой точкой из списка.
  cv.Point2f tl = pts[0];
  cv.Point2f tr = pts[0];
  cv.Point2f br = pts[0];
  cv.Point2f bl = pts[0];

  double minSum = double.infinity, maxSum = -double.infinity;
  double minDiff = double.infinity, maxDiff = -double.infinity;

  for (var pt in pts) {
    double sum = pt.x + pt.y;
    double diff = pt.y - pt.x;
    if (sum < minSum) {
      minSum = sum;
      tl = pt;
    }
    if (sum > maxSum) {
      maxSum = sum;
      br = pt;
    }
    if (diff < minDiff) {
      minDiff = diff;
      tr = pt;
    }
    if (diff > maxDiff) {
      maxDiff = diff;
      bl = pt;
    }
  }
  return [tl, tr, br, bl];
}

/// Функция, выполняемая в изоляте для обрезки изображения по найденному контуру.
/// Ожидает Map с ключами:
/// 'pngBytes' – исходное изображение в PNG,
/// 'corners' – List<List<double>> с координатами 4-х углов,
/// 'width', 'height' – размеры исходного изображения.
/// Возвращает Uint8List с PNG-данными обрезанного изображения.
Future<Uint8List> cropFrameInIsolate(Map<String, dynamic> params) async {
  try {
    // Исходные данные
    Uint8List pngBytes = params['pngBytes'];
    List<dynamic> cornersDynamic = params[
    'corners']; // Ожидается список вида [[x1,y1],[x2,y2],[x3,y3],[x4,y4]]

    // Декодируем исходное изображение в cv.Mat в цветном режиме
    cv.Mat mat = cv.imdecode(pngBytes, cv.IMREAD_COLOR);
    debugPrint(
        "Исходное изображение: ширина = ${mat.width}, высота = ${mat.height}, channels = ${mat.channels}");

    // Преобразуем список углов в список Point2f
    List<cv.Point2f> srcPoints = cornersDynamic
        .map<cv.Point2f>(
            (item) => cv.Point2f(item[0].toDouble(), item[1].toDouble()))
        .toList();
    if (srcPoints.length != 4) {
      throw Exception('Ожидается ровно 4 точки для обрезки');
    }

    // Упорядочиваем точки в порядке: верхний левый, верхний правый, нижний правый, нижний левый
    List<cv.Point2f> orderedPoints = orderPoints(srcPoints);
    debugPrint(
        "Упорядоченные точки: ${orderedPoints.map((pt) => "(${pt.x}, ${pt.y})").join(', ')}");

    // Вычисляем ширину итогового изображения как максимум из расстояний между верхними и нижними сторонами:
    double widthTop = math.sqrt(
        math.pow(orderedPoints[1].x - orderedPoints[0].x, 2) +
            math.pow(orderedPoints[1].y - orderedPoints[0].y, 2));
    double widthBottom = math.sqrt(
        math.pow(orderedPoints[2].x - orderedPoints[3].x, 2) +
            math.pow(orderedPoints[2].y - orderedPoints[3].y, 2));
    double maxWidth = math.max(widthTop, widthBottom);

    // Вычисляем высоту итогового изображения как максимум из расстояний между левыми и правыми сторонами:
    double heightLeft = math.sqrt(
        math.pow(orderedPoints[3].x - orderedPoints[0].x, 2) +
            math.pow(orderedPoints[3].y - orderedPoints[0].y, 2));
    double heightRight = math.sqrt(
        math.pow(orderedPoints[2].x - orderedPoints[1].x, 2) +
            math.pow(orderedPoints[2].y - orderedPoints[1].y, 2));
    double maxHeight = math.max(heightLeft, heightRight);

    debugPrint(
        "Вычисленные размеры итогового изображения: maxWidth = $maxWidth, maxHeight = $maxHeight");

    // Определяем целевые точки для перспективного преобразования
    List<cv.Point2f> dstPoints = [
      cv.Point2f(0, 0),
      cv.Point2f(maxWidth - 1, 0),
      cv.Point2f(maxWidth - 1, maxHeight - 1),
      cv.Point2f(0, maxHeight - 1),
    ];

    // Получаем матрицу перспективного преобразования
    cv.VecPoint2f srcVec = cv.VecPoint2f.fromList(orderedPoints);
    cv.VecPoint2f dstVec = cv.VecPoint2f.fromList(dstPoints);
    cv.Mat perspectiveMatrix = cv.getPerspectiveTransform2f(srcVec, dstVec);
    debugPrint("Матрица перспективного преобразования получена");

    // Применяем перспективное преобразование для получения "выпрямленного" изображения
    cv.Mat warped = cv.warpPerspective(
      mat,
      perspectiveMatrix,
      (maxWidth.toInt(), maxHeight.toInt()),
    );
    debugPrint(
        "Изображение после warpPerspective: ширина = ${warped.width}, высота = ${warped.height}, channels = ${warped.channels}");

    // Преобразуем цветовое пространство из BGR (стандарт OpenCV) в RGB
    cv.Mat rgbMat = cv.cvtColor(warped, cv.COLOR_BGR2RGB);
    debugPrint("Изображение после cvtColor: channels = ${rgbMat.channels}");

    // Если не iOS, поворачиваем изображение вправо (на 90° по часовой стрелке);
    // для iOS сохраняем исходное изображение.
    cv.Mat finalMat;
    if (!Platform.isIOS) {
      finalMat = cv.rotate(rgbMat, cv.ROTATE_90_CLOCKWISE);
      debugPrint(
          "Изображение повернуто: ширина = ${finalMat.width}, высота = ${finalMat.height}");
      rgbMat.dispose();
    } else {
      finalMat = rgbMat;
    }

    // Конвертируем полученное изображение в PNG
    final result = cv.imencode(".png", finalMat);
    if (!result.$1) {
      throw Exception("Ошибка при кодировании изображения в PNG");
    }
    Uint8List croppedPng = result.$2;
    debugPrint(
        "Размер обрезанного изображения (PNG): ${croppedPng.lengthInBytes} байт");

    // Освобождаем ресурсы
    mat.dispose();
    perspectiveMatrix.dispose();
    warped.dispose();
    finalMat.dispose();
    srcVec.dispose();
    dstVec.dispose();

    return croppedPng;
  } catch (e) {
    debugPrint("Ошибка при обрезке: $e");
    return Uint8List(0);
  }
}


// Функция для преобразования List<List<double>> в List<Point>
List<cv.Point> convertToPointList(List<List<double>> list) {
  return list.map((lst) => cv.Point(lst[0].round(), lst[1].round())).toList();
}

List<cv.Point> convertPoints(List<cv.Point2f> points2f) {
  return points2f.map((pt) => cv.Point(pt.x.round(), pt.y.round())).toList();
}
