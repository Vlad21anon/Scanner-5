import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart'; // для compute
import 'package:flutter/material.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'package:image/image.dart' as img;
import 'package:owl_tech_pdf_scaner/app/app_colors.dart';
import 'package:owl_tech_pdf_scaner/widgets/paper_border_painter.dart';
import 'package:path_provider/path_provider.dart'; // для временной папки
import 'package:path/path.dart' as path;

/// Виджет, который реализует сканирование документа с использованием камеры.
class DocumentScannerTest extends StatefulWidget {
  const DocumentScannerTest({super.key});

  @override
  State<DocumentScannerTest> createState() => DocumentScannerTestState();
}

class DocumentScannerTestState extends State<DocumentScannerTest> {
  late CameraController _controller;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  List<Offset>? _paperCorners; // Найденные 4 угла (исходные координаты)
  Size? _cameraImageSize; // Размер исходного кадра (width, height)
  Uint8List? _lastPngBytes; // Последний обработанный кадр в PNG
  Uint8List? _previewPngBytes; // PNG-байты обработанного изображения для предпросмотра
  String? _croppedImagePath;

  // Дополнительные параметры для корректировки (например, смещения)
  double offsetAdjustmentX = 0;
  double offsetAdjustmentY = 5;

  // Параметры для алгоритма Canny и аппроксимации
  double _cannyThreshold1 = 50.0;
  double _cannyThreshold2 = 150.0;
  int _apertureSize = 3;
  double _approxPolyFactor = 0.02;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();

    _controller = CameraController(
      cameras[0],
      ResolutionPreset.medium,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    await _controller.initialize();
    setState(() {
      _isCameraInitialized = true;
    });
    _controller.startImageStream((CameraImage image) {
      if (!_isProcessing) {
        _isProcessing = true;
        _processCameraImage(image);
      }
    });
  }

  @override
  void dispose() {
    _controller.stopImageStream();
    _controller.dispose();
    super.dispose();
  }

  /// Преобразует CameraImage (YUV420) в PNG-байты с использованием пакета image.
  Uint8List convertYUV420ToPNG(CameraImage image) {
    // Если изображение имеет только одну плоскость – скорее всего это формат BGRA (например, на iOS)
    if (image.planes.length == 1) {
      final plane = image.planes[0];
      final img.Image bgraImage = img.Image.fromBytes(
        width: image.width,
        height: image.height,
        bytes: plane.bytes.buffer,
        order: img.ChannelOrder.bgra,
      );
      return Uint8List.fromList(img.encodePng(bgraImage));
    }
    // Если изображение имеет две плоскости – обрабатываем как NV12 (Y + interleaved UV)
    else if (image.planes.length == 2) {
      final int width = image.width;
      final int height = image.height;
      final img.Image rgbImage = img.Image(width: width, height: height);

      final planeY = image.planes[0];
      final planeUV = image.planes[1];
      final int uvRowStride = planeUV.bytesPerRow;
      // Обычно для NV12 bytesPerPixel равен 2, так что умножаем (x ~/ 2)*2

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          int yp = planeY.bytes[y * planeY.bytesPerRow + x];
          int uvIndex = (y ~/ 2) * uvRowStride + (x ~/ 2) * 2;
          // Для NV12 обычно порядок: [U, V]
          int u = planeUV.bytes[uvIndex];
          int v = planeUV.bytes[uvIndex + 1];

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
    }
    // Если плоскостей 3 – обрабатываем как YUV420
    else if (image.planes.length >= 3) {
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

  /// Обработка кадра в главном потоке.
  /// Конвертирует кадр в PNG, затем вызывает compute() для обработки изображения в изоляте,
  /// передавая текущие параметры из слайдеров.
  Future<void> _processCameraImage(CameraImage image) async {
    try {
      _cameraImageSize = Size(image.width.toDouble(), image.height.toDouble());
      Uint8List pngBytes = convertYUV420ToPNG(image);
      _lastPngBytes = pngBytes;

      debugPrint("Начинаем обработку кадра. Размер изображения: ${image.width}x${image.height}");

      final result = await compute(processFrameInIsolate, {
        'pngBytes': pngBytes,
        'width': image.width,
        'height': image.height,
        'cannyThreshold1': _cannyThreshold1,
        'cannyThreshold2': _cannyThreshold2,
        'apertureSize': _apertureSize,
        'approxPolyFactor': _approxPolyFactor,
      });

      if (result == null) {
        debugPrint("Результат из изолята равен null");
        return;
      }

      List<List<double>> cornersList = result['corners'] as List<List<double>>;
      Uint8List previewBytes = result['preview'] as Uint8List;

      debugPrint("Получено ${cornersList.length} углов из изолята");

      List<Offset> corners = [];
      for (int i = 0; i < cornersList.length; i++) {
        var pt = cornersList[i];
        debugPrint("Угол $i: (${pt[0]}, ${pt[1]})");
        corners.add(Offset(pt[0], pt[1]));
      }

      // Обновляем состояние: preview всегда показывается,
      // а paperCorners устанавливается только если найдено ровно 4 угла.
      setState(() {
        _previewPngBytes = previewBytes;
        _paperCorners = corners.length == 4 ? corners : null;
      });
    } catch (e, stackTrace) {
      debugPrint("Ошибка в _processCameraImage: $e");
      debugPrint("$stackTrace");
    } finally {
      _isProcessing = false;
    }
  }

  /// Функция, вызываемая при нажатии на кнопку "Обрезать фото"
  Future<String?> cropImage() async {
    if (_lastPngBytes == null ||
        _paperCorners == null ||
        _paperCorners!.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет корректного контура для обрезки')),
      );
      return null;
    }

    // Передаём в изолят: PNG-байты, контур, размеры исходного кадра.
    final croppedBytes = await compute(cropFrameInIsolate, {
      'pngBytes': _lastPngBytes,
      // Передаём контур как List<List<double>>
      'corners': _paperCorners!.map((pt) => [pt.dx, pt.dy]).toList(),
      'width': _cameraImageSize!.width.toInt(),
      'height': _cameraImageSize!.height.toInt(),
    });

    if (croppedBytes.isNotEmpty) {
      // Сохраняем обрезанное изображение в файловую систему
      try {
        // Получаем директорию для документов
        final Directory appDocDir = await getApplicationDocumentsDirectory();
        // Формируем уникальное имя файла
        final String fileName =
            "cropped_${DateTime.now().millisecondsSinceEpoch}.png";
        final String filePath = path.join(appDocDir.path, fileName);
        final File file = File(filePath);
        await file.writeAsBytes(croppedBytes);

        // Обновляем состояние
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
    return Scaffold(
      backgroundColor: AppColors.black,
      body: _isCameraInitialized
          ? Stack(
        children: [
          // Камера
          CameraPreview(_controller),
          // Отображение найденного контура (рамка)
          if (_paperCorners != null && _cameraImageSize != null)
            CustomPaint(
              size: MediaQuery.of(context).size,
              painter: PaperBorderPainter(
                corners: _paperCorners!,
                cameraImageSize: _cameraImageSize!,
                rotateClockwise: true,
                offsetAdjustmentX: offsetAdjustmentX,
                offsetAdjustmentY: offsetAdjustmentY,
              ),
            ),
          // Предпросмотр обработанного изображения (например, краев)
          if (_previewPngBytes != null)
            Positioned(
              top: 40,
              right: 20,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.yellow, width: 2),
                ),
                width: 150,
                height: 150,
                child: Image.memory(
                  _previewPngBytes!,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          // Панель со слайдерами параметров
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black54,
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Слайдер для порога 1 для Canny
                  Row(
                    children: [
                      const Expanded(
                          child: Text(
                            "Canny Th1",
                            style: TextStyle(color: Colors.white),
                          )),
                      Expanded(
                        flex: 3,
                        child: Slider(
                          min: 0,
                          max: 255,
                          value: _cannyThreshold1,
                          onChanged: (val) {
                            setState(() {
                              _cannyThreshold1 = val;
                            });
                          },
                        ),
                      ),
                      Text(
                        _cannyThreshold1.toStringAsFixed(0),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  // Слайдер для порога 2 для Canny
                  Row(
                    children: [
                      const Expanded(
                          child: Text(
                            "Canny Th2",
                            style: TextStyle(color: Colors.white),
                          )),
                      Expanded(
                        flex: 3,
                        child: Slider(
                          min: 0,
                          max: 255,
                          value: _cannyThreshold2,
                          onChanged: (val) {
                            setState(() {
                              _cannyThreshold2 = val;
                            });
                          },
                        ),
                      ),
                      Text(
                        _cannyThreshold2.toStringAsFixed(0),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  // Слайдер для размера апертуры
                  Row(
                    children: [
                      const Expanded(
                          child: Text(
                            "Aperture",
                            style: TextStyle(color: Colors.white),
                          )),
                      Expanded(
                        flex: 3,
                        child: Slider(
                          min: 3,
                          max: 7,
                          divisions: 2,
                          value: _apertureSize.toDouble(),
                          onChanged: (val) {
                            setState(() {
                              _apertureSize = val.toInt();
                            });
                          },
                        ),
                      ),
                      Text(
                        _apertureSize.toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  // Слайдер для коэффициента аппроксимации полигона
                  Row(
                    children: [
                      const Expanded(
                          child: Text(
                            "Approx Factor",
                            style: TextStyle(color: Colors.white),
                          )),
                      Expanded(
                        flex: 3,
                        child: Slider(
                          min: 0.0,
                          max: 0.1,
                          divisions: 100,
                          value: _approxPolyFactor,
                          onChanged: (val) {
                            setState(() {
                              _approxPolyFactor = val;
                            });
                          },
                        ),
                      ),
                      Text(
                        _approxPolyFactor.toStringAsFixed(3),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

/// Функция, выполняемая в изоляте для определения контура документа и формирования предпросмотра.
/// Принимает Map с ключами:
/// • 'pngBytes' – Uint8List с PNG-данными,
/// • 'width', 'height' – размеры исходного кадра,
/// • 'cannyThreshold1', 'cannyThreshold2', 'apertureSize' – параметры для cv.cannyAsync,
/// • 'approxPolyFactor' – коэффициент для аппроксимации контура.
// Функция, выполняемая в изоляте для обработки изображения и вычисления углов (без поворота точек)
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

    var contoursTuple = cv.findContours(edges, cv.RETR_LIST, cv.CHAIN_APPROX_SIMPLE);
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
    List<dynamic> cornersDynamic = params['corners']; // Ожидается список вида [[x1,y1],[x2,y2],[x3,y3],[x4,y4]]

    // Декодируем исходное изображение в cv.Mat в цветном режиме
    cv.Mat mat = cv.imdecode(pngBytes, cv.IMREAD_COLOR);
    debugPrint("Исходное изображение: ширина = ${mat.width}, высота = ${mat.height}, channels = ${mat.channels}");

    // Преобразуем список углов в список Point2f
    List<cv.Point2f> srcPoints = cornersDynamic
        .map<cv.Point2f>((item) => cv.Point2f(item[0].toDouble(), item[1].toDouble()))
        .toList();
    if (srcPoints.length != 4) {
      throw Exception('Ожидается ровно 4 точки для обрезки');
    }

    // Упорядочиваем точки в порядке: верхний левый, верхний правый, нижний правый, нижний левый
    List<cv.Point2f> orderedPoints = orderPoints(srcPoints);
    debugPrint("Упорядоченные точки: ${orderedPoints.map((pt) => "(${pt.x}, ${pt.y})").join(', ')}");

    // Вычисляем ширину итогового изображения как максимум из расстояний между верхними и нижними сторонами:
    double widthTop = math.sqrt(math.pow(orderedPoints[1].x - orderedPoints[0].x, 2) +
        math.pow(orderedPoints[1].y - orderedPoints[0].y, 2));
    double widthBottom = math.sqrt(math.pow(orderedPoints[2].x - orderedPoints[3].x, 2) +
        math.pow(orderedPoints[2].y - orderedPoints[3].y, 2));
    double maxWidth = math.max(widthTop, widthBottom);

    // Вычисляем высоту итогового изображения как максимум из расстояний между левыми и правыми сторонами:
    double heightLeft = math.sqrt(math.pow(orderedPoints[3].x - orderedPoints[0].x, 2) +
        math.pow(orderedPoints[3].y - orderedPoints[0].y, 2));
    double heightRight = math.sqrt(math.pow(orderedPoints[2].x - orderedPoints[1].x, 2) +
        math.pow(orderedPoints[2].y - orderedPoints[1].y, 2));
    double maxHeight = math.max(heightLeft, heightRight);

    debugPrint("Вычисленные размеры итогового изображения: maxWidth = $maxWidth, maxHeight = $maxHeight");

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
    debugPrint("Изображение после warpPerspective: ширина = ${warped.width}, высота = ${warped.height}, channels = ${warped.channels}");

    // Преобразуем цветовое пространство из BGR (стандарт OpenCV) в RGB
    cv.Mat rgbMat = cv.cvtColor(warped, cv.COLOR_BGR2RGB);
    debugPrint("Изображение после cvtColor: channels = ${rgbMat.channels}");

    // Если не iOS, поворачиваем изображение вправо (на 90° по часовой стрелке);
    // для iOS сохраняем исходное изображение.
    cv.Mat finalMat;
    if (!Platform.isIOS) {
      finalMat = cv.rotate(rgbMat, cv.ROTATE_90_CLOCKWISE);
      debugPrint("Изображение повернуто: ширина = ${finalMat.width}, высота = ${finalMat.height}");
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
    debugPrint("Размер обрезанного изображения (PNG): ${croppedPng.lengthInBytes} байт");

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
