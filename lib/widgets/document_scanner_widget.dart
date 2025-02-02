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

/// Виджет, который реализует сканирование документа с использованием камеры.
/// После нажатия на кнопку «Сфотографировать» происходит обработка изображения в отдельном изоляте.
class DocumentScannerWidget extends StatefulWidget {
  const DocumentScannerWidget({super.key});

  @override
  State<DocumentScannerWidget> createState() => DocumentScannerWidgetState();
}

class DocumentScannerWidgetState extends State<DocumentScannerWidget> {
  late CameraController _controller;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  List<Offset>? _paperCorners; // Найденные 4 угла (исходные координаты)
  Size? _cameraImageSize; // Размер исходного кадра (width, height)
  Uint8List? _lastPngBytes; // Последний обработанный кадр в PNG
  String? _croppedImagePath;

  // Дополнительные параметры для корректировки смещения
  double offsetAdjustmentX = 0;
  double offsetAdjustmentY = 5;//-115;

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
    final int width = image.width;
    final int height = image.height;
    final img.Image rgbImage = img.Image(width: width, height: height);

    final planeY = image.planes[0];
    final planeU = image.planes[1];
    final planeV = image.planes[2];

    // Получаем параметры для U/V-плоскостей:
    final int uvRowStride = planeU.bytesPerRow;
    final int uvPixelStride = planeU.bytesPerPixel ?? 0;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        // Индекс для Y-плоскости (полное разрешение)
        int yp = planeY.bytes[y * planeY.bytesPerRow + x];

        // Вычисляем индекс для U/V-плоскостей с учетом субдискретизации
        int uvIndex = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;

        // Меняем местами: берём U из planeV и V из planeU
        int up = planeV.bytes[uvIndex];
        int vp = planeU.bytes[uvIndex];

        // Приводим значения к диапазону и вычитаем смещение
        double yVal = yp.toDouble();
        double uVal = up.toDouble() - 128.0;
        double vVal = vp.toDouble() - 128.0;

        // Преобразование YUV в RGB по стандартной формуле
        int r = (yVal + 1.402 * vVal).round().clamp(0, 255);
        int g =
            (yVal - 0.344136 * uVal - 0.714136 * vVal).round().clamp(0, 255);
        int b = (yVal + 1.772 * uVal).round().clamp(0, 255);

        rgbImage.setPixelRgba(x, y, r, g, b, 255);
      }
    }
    return Uint8List.fromList(img.encodePng(rgbImage));
  }

  /// Обработка кадра в главном потоке: конвертируем кадр в PNG-байты,
  /// затем вызываем compute(), который запускает функцию processFrameInIsolate.
  Future<void> _processCameraImage(CameraImage image) async {
    try {
      // Сохраняем размер кадра
      _cameraImageSize = Size(image.width.toDouble(), image.height.toDouble());
      // Получаем PNG-байты из CameraImage
      Uint8List pngBytes = convertYUV420ToPNG(image);
      // Сохраняем последний кадр для последующей обрезки
      _lastPngBytes = pngBytes;
      // Вызываем функцию в изоляте:
      final result = await compute(processFrameInIsolate, {
        'pngBytes': pngBytes,
        'width': image.width,
        'height': image.height,
      });

      // result – это List<List<double>>, преобразуем его в List<Offset>
      List<Offset> corners = [];
      for (var pt in result) {
        // Каждая точка представлена как [x, y]
        corners.add(Offset(pt[0], pt[1]));
      }

      // Выводим отладку
      for (int i = 0; i < corners.length; i++) {
        debugPrint('Corner $i: ${corners[i]}');
      }

      if (mounted) {
        setState(() {
          _paperCorners = corners;
        });
      }
    } catch (e) {
      debugPrint("Ошибка в изоляте: $e");
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

    // Передаём в изоляте: PNG-байты, контур, размеры исходного кадра.
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
        // Формируем уникальное имя файла, например, с использованием текущего времени
        final String fileName =
            "cropped_${DateTime.now().millisecondsSinceEpoch}.png";
        final String filePath = path.join(appDocDir.path, fileName);
        final File file = File(filePath);
        await file.writeAsBytes(croppedBytes);

        // Обновляем состояние: сохраняем байты и путь к файлу
        if (mounted) {
          setState(() {
            _croppedImagePath = filePath;
          });
        }

        return _croppedImagePath;
      } catch (e) {
        debugPrint("Ошибка при сохранении файла: $e");
      }
    } else {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: _isCameraInitialized
          ? Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      CameraPreview(_controller),
                      if (_paperCorners != null && _cameraImageSize != null)
                        CustomPaint(
                          size:
                              Size(constraints.maxWidth, constraints.maxHeight),
                          painter: PaperBorderPainter(
                            corners: _paperCorners!,
                            cameraImageSize: _cameraImageSize!,
                            rotateClockwise: true,
                            offsetAdjustmentX: offsetAdjustmentX,
                            offsetAdjustmentY: offsetAdjustmentY,
                          ),
                        ),
                    ],
                  );
                },
              ),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

/// Функция, выполняемая в изоляте для определения контура документа.
/// Принимает Map с ключами:
/// 'pngBytes' – Uint8List с PNG-данными,
/// 'width', 'height' – размеры исходного кадра.
/// Возвращает List<List<double>> – список 4-х точек, каждая из которых представлена как [x, y].
Future<List<List<double>>> processFrameInIsolate(
    Map<String, dynamic> params) async {
  try {
    Uint8List pngBytes = params['pngBytes'];

    // Декодируем изображение в cv.Mat
    cv.Mat mat = cv.imdecode(pngBytes, cv.IMREAD_COLOR);

    cv.Mat gray = await cv.cvtColorAsync(mat, cv.COLOR_BGR2GRAY);
    cv.Mat blur = await cv.gaussianBlurAsync(gray, (5, 5), 0);
    cv.Mat edges = await cv.cannyAsync(blur, 50, 300, apertureSize: 3);

    var contoursTuple =
        cv.findContours(edges, cv.RETR_LIST, cv.CHAIN_APPROX_SIMPLE);
    var contours = contoursTuple.$1;

    dynamic paperContour;
    double maxArea = 0;

    for (var contour in contours) {
      double peri = cv.arcLength(contour, true);
      var approx = cv.approxPolyDP(contour, 0.02 * peri, true);
      if (approx.length == 4) {
        double area = cv.contourArea(approx);
        if (area > maxArea && area > 1000) {
          maxArea = area;
          paperContour = approx;
        }
      }
    }

    List<List<double>> result = [];
    if (paperContour != null) {
      for (int i = 0; i < paperContour.length; i++) {
        var pt = paperContour[i];
        result.add([pt.x.toDouble(), pt.y.toDouble()]);
      }
    }

    // Освобождаем ресурсы
    mat.dispose();
    gray.dispose();
    blur.dispose();
    edges.dispose();

    return result;
  } catch (e) {
    // Если произошла ошибка, возвращаем пустой список
    return [];
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

    // Получаем матрицу перспективного преобразования (используем Point2f-версии)
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

    // Поворачиваем изображение вправо (на 90° по часовой стрелке)
    cv.Mat rotated = cv.rotate(rgbMat, cv.ROTATE_90_CLOCKWISE);
    debugPrint("Изображение повернуто вправо: ширина = ${rotated.width}, высота = ${rotated.height}");

    // Конвертируем полученное цветное изображение в PNG
    final result = cv.imencode(".png", rotated);
    if (!result.$1) {
      throw Exception("Ошибка при кодировании изображения в PNG");
    }
    Uint8List croppedPng = result.$2;
    debugPrint(
        "Размер обрезанного изображения (PNG): ${croppedPng.lengthInBytes} байт");

    // Освобождаем ресурсы
    mat.dispose();
    perspectiveMatrix.dispose();
    rotated.dispose();
    warped.dispose();
    rgbMat.dispose();
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
