import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:owl_tech_pdf_scaner/app/app_colors.dart';
import 'package:owl_tech_pdf_scaner/blocs/files_cubit/files_cubit.dart';
import 'package:owl_tech_pdf_scaner/blocs/scan_files_cubit/scan_files_cubit.dart';
import 'package:owl_tech_pdf_scaner/blocs/text_edit_cubit.dart';
import 'package:owl_tech_pdf_scaner/screens/files_page.dart';
import 'package:owl_tech_pdf_scaner/screens/settings_page.dart';
import 'package:owl_tech_pdf_scaner/services/navigation_service.dart';
import 'package:owl_tech_pdf_scaner/widgets/custom_navigation_bar.dart';
import 'package:path_provider/path_provider.dart';

import 'blocs/filter_cubit.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorageDirectory.web
        : HydratedStorageDirectory((await getTemporaryDirectory()).path),
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ScanFilesCubit(),
        ),
        BlocProvider(
          create: (context) => FilesCubit(),
        ),
        BlocProvider(
          create: (context) => FilterCubit(),
        ),
        BlocProvider(
          create: (context) => TextEditCubit(),
        ),
      ],
      child: MaterialApp(
        navigatorKey: NavigationService().navigatorKey,
        title: 'PDF Scanner',
        debugShowCheckedModeBanner: false,
        home: MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    FilesPage(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        alignment: Alignment.center,
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
          Positioned(
            bottom: 46,
            child: CustomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) => setState(() => _selectedIndex = index),
            ),
          )
        ],
      ),
    );
  }
}

// import 'dart:async';
// import 'dart:io';
// import 'dart:math' as math;
// import 'dart:typed_data';
// import 'package:camera/camera.dart';
// import 'package:flutter/foundation.dart'; // для compute
// import 'package:flutter/material.dart';
// import 'package:opencv_dart/opencv_dart.dart' as cv;
// import 'package:image/image.dart' as img;
// import 'package:path_provider/path_provider.dart';
// import 'package:path/path.dart' as path;
//
// // Глобальный список камер
// late List<CameraDescription> cameras;
//
// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   cameras = await availableCameras();
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Документ с изолятами',
//       theme: ThemeData(primarySwatch: Colors.blue),
//       home: const PaperBorderScreen(),
//     );
//   }
// }
//
// class PaperBorderScreen extends StatefulWidget {
//   const PaperBorderScreen({super.key});
//   @override
//   State<PaperBorderScreen> createState() => _PaperBorderScreenState();
// }
//
// class _PaperBorderScreenState extends State<PaperBorderScreen> {
//   late CameraController _controller;
//   bool _isCameraInitialized = false;
//   bool _isProcessing = false;
//   List<Offset>? _paperCorners; // Найденные 4 угла (исходные координаты)
//   Size? _cameraImageSize; // Размер исходного кадра (width, height)
//   Uint8List? _lastPngBytes; // Последний обработанный кадр в PNG
//   Uint8List? _croppedImage; // Обрезанное изображение
//   String? _croppedImagePath;
//
//   // Дополнительные параметры для корректировки смещения
//   double offsetAdjustmentX = -45;
//   double offsetAdjustmentY = 0.0;
//
//   @override
//   void initState() {
//     super.initState();
//     _initCamera();
//   }
//
//   Future<void> _initCamera() async {
//     _controller = CameraController(
//       cameras[0],
//       ResolutionPreset.medium,
//       imageFormatGroup: ImageFormatGroup.yuv420,
//     );
//     await _controller.initialize();
//     setState(() {
//       _isCameraInitialized = true;
//     });
//     _controller.startImageStream((CameraImage image) {
//       if (!_isProcessing) {
//         _isProcessing = true;
//         _processCameraImage(image);
//       }
//     });
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   /// Преобразует CameraImage (YUV420) в PNG-байты с использованием пакета image.
//   Uint8List convertYUV420ToPNG(CameraImage image) {
//     final int width = image.width;
//     final int height = image.height;
//     final img.Image rgbImage = img.Image(width: width, height: height);
//
//     final planeY = image.planes[0];
//     final planeU = image.planes[1];
//     final planeV = image.planes[2];
//
//     for (int y = 0; y < height; y++) {
//       for (int x = 0; x < width; x++) {
//         int yp = planeY.bytes[y * planeY.bytesPerRow + x];
//         int uvX = x ~/ 2;
//         int uvY = y ~/ 2;
//         int uvIndex = uvY * planeU.bytesPerRow + uvX;
//         int up = planeU.bytes[uvIndex];
//         int vp = planeV.bytes[uvIndex];
//
//         double yVal = yp.toDouble();
//         double uVal = up.toDouble() - 128.0;
//         double vVal = vp.toDouble() - 128.0;
//
//         int r = (yVal + 1.402 * vVal).round().clamp(0, 255);
//         int g = (yVal - 0.344136 * uVal - 0.714136 * vVal).round().clamp(0, 255);
//         int b = (yVal + 1.772 * uVal).round().clamp(0, 255);
//
//         rgbImage.setPixelRgba(x, y, r, g, b, 255);
//       }
//     }
//     return Uint8List.fromList(img.encodePng(rgbImage));
//   }
//
//   /// Обработка кадра в главном потоке: конвертируем кадр в PNG-байты,
//   /// затем вызываем compute(), который запускает функцию processFrameInIsolate.
//   Future<void> _processCameraImage(CameraImage image) async {
//     try {
//       // Сохраняем размер кадра
//       _cameraImageSize = Size(image.width.toDouble(), image.height.toDouble());
//       // Получаем PNG-байты из CameraImage
//       Uint8List pngBytes = convertYUV420ToPNG(image);
//       // Сохраняем последний кадр для последующей обрезки
//       _lastPngBytes = pngBytes;
//       // Вызываем функцию в изоляте:
//       final result = await compute(processFrameInIsolate, {
//         'pngBytes': pngBytes,
//         'width': image.width,
//         'height': image.height,
//       });
//
//       // result – это List<List<double>>, преобразуем его в List<Offset>
//       List<Offset> corners = [];
//       for (var pt in result) {
//         // Каждая точка представлена как [x, y]
//         corners.add(Offset(pt[0], pt[1]));
//       }
//
//       // Выводим отладку
//       for (int i = 0; i < corners.length; i++) {
//         debugPrint('Corner $i: ${corners[i]}');
//       }
//
//       setState(() {
//         _paperCorners = corners;
//       });
//     } catch (e) {
//       debugPrint("Ошибка в изоляте: $e");
//     } finally {
//       _isProcessing = false;
//     }
//   }
//
//   /// Функция, вызываемая при нажатии на кнопку "Обрезать фото"
//   Future<void> _cropImage() async {
//     if (_lastPngBytes == null || _paperCorners == null || _paperCorners!.length != 4) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Нет корректного контура для обрезки')),
//       );
//       return;
//     }
//
//     // Передаём в изоляте: PNG-байты, контур, размеры исходного кадра.
//     final croppedBytes = await compute(cropFrameInIsolate, {
//       'pngBytes': _lastPngBytes,
//       // Передаём контур как List<List<double>>
//       'corners': _paperCorners!.map((pt) => [pt.dx, pt.dy]).toList(),
//       'width': _cameraImageSize!.width.toInt(),
//       'height': _cameraImageSize!.height.toInt(),
//     });
//
//     if (croppedBytes.isNotEmpty) {
//       // Сохраняем обрезанное изображение в файловую систему
//       try {
//         // Получаем директорию для документов
//         final Directory appDocDir = await getApplicationDocumentsDirectory();
//         // Формируем уникальное имя файла, например, с использованием текущего времени
//         final String fileName =
//             "cropped_${DateTime.now().millisecondsSinceEpoch}.png";
//         final String filePath = path.join(appDocDir.path, fileName);
//         final File file = File(filePath);
//         await file.writeAsBytes(croppedBytes);
//
//         // Обновляем состояние: сохраняем байты и путь к файлу
//         setState(() {
//           _croppedImage = croppedBytes;
//           _croppedImagePath = filePath; // Объявите эту переменную в вашем классе
//         });
//
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Изображение сохранено по пути: $filePath')),
//         );
//       } catch (e) {
//         debugPrint("Ошибка при сохранении файла: $e");
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Ошибка при сохранении изображения')),
//         );
//       }
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Не удалось обрезать изображение')),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Документ (с изолятами)'),
//       ),
//       body: Column(
//         children: [
//           // Область отображения камеры и оверлей
//           Expanded(
//             flex: 5,
//             child: _isCameraInitialized
//                 ? LayoutBuilder(builder: (context, constraints) {
//               return Stack(
//                 children: [
//                   CameraPreview(_controller),
//                   if (_paperCorners != null && _cameraImageSize != null)
//                     CustomPaint(
//                       size: Size(constraints.maxWidth, constraints.maxHeight),
//                       painter: PaperBorderPainter(
//                         corners: _paperCorners!,
//                         cameraImageSize: _cameraImageSize!,
//                         rotateClockwise: true,
//                         offsetAdjustmentX: offsetAdjustmentX,
//                         offsetAdjustmentY: offsetAdjustmentY,
//                       ),
//                     ),
//                 ],
//               );
//             })
//                 : const Center(child: CircularProgressIndicator()),
//           ),
//           // Панель отладки и кнопка обрезки
//           Expanded(
//             flex: 3,
//             child: SingleChildScrollView(
//               child: Column(
//                 children: [
//                   // Секция ползунков для смещения
//                   Padding(
//                     padding: const EdgeInsets.all(8.0),
//                     child: Column(
//                       children: [
//                         Text('Корректировка смещения X: ${offsetAdjustmentX.toStringAsFixed(1)}'),
//                         Slider(
//                           min: -50,
//                           max: 50,
//                           value: offsetAdjustmentX,
//                           onChanged: (value) {
//                             setState(() {
//                               offsetAdjustmentX = value;
//                             });
//                           },
//                         ),
//                         Text('Корректировка смещения Y: ${offsetAdjustmentY.toStringAsFixed(1)}'),
//                         Slider(
//                           min: -50,
//                           max: 50,
//                           value: offsetAdjustmentY,
//                           onChanged: (value) {
//                             setState(() {
//                               offsetAdjustmentY = value;
//                             });
//                           },
//                         ),
//                       ],
//                     ),
//                   ),
//                   // Кнопка для обрезки изображения
//                   ElevatedButton(
//                     onPressed: _cropImage,
//                     child: const Text('Обрезать фото'),
//                   ),
//                   const SizedBox(height: 8),
//                   // Отображение обрезанного изображения (если оно имеется)
//                   if (_croppedImagePath != null)
//                     Column(
//                       children: [
//                         const Text('Обрезанное изображение:'),
//                         Padding(
//                           padding: const EdgeInsets.all(8.0),
//                           child: Transform.rotate(
//                             angle: math.pi / 2, // Поворот на 90° по часовой стрелке
//                             child: Image.file(File(_croppedImagePath!)),
//                           ),
//                         ),
//                       ],
//                     ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// /// Функция, выполняемая в изоляте для определения контура документа.
// /// Принимает Map с ключами:
// /// 'pngBytes' – Uint8List с PNG-данными,
// /// 'width', 'height' – размеры исходного кадра.
// /// Возвращает List<List<double>> – список 4-х точек, каждая из которых представлена как [x, y].
// Future<List<List<double>>> processFrameInIsolate(Map<String, dynamic> params) async {
//   try {
//     Uint8List pngBytes = params['pngBytes'];
//     int width = params['width'];
//     int height = params['height'];
//
//     // Декодируем изображение в cv.Mat
//     cv.Mat mat = cv.imdecode(pngBytes, cv.IMREAD_COLOR);
//
//     cv.Mat gray = await cv.cvtColorAsync(mat, cv.COLOR_BGR2GRAY);
//     cv.Mat blur = await cv.gaussianBlurAsync(gray, (5, 5), 0);
//     cv.Mat edges = await cv.cannyAsync(blur, 50, 150);
//
//     var contoursTuple = await cv.findContours(edges, cv.RETR_LIST, cv.CHAIN_APPROX_SIMPLE);
//     var contours = contoursTuple.$1;
//
//     dynamic paperContour;
//     double maxArea = 0;
//
//     for (var contour in contours) {
//       double peri = await cv.arcLength(contour, true);
//       var approx = await cv.approxPolyDP(contour, 0.02 * peri, true);
//       if (approx.length == 4) {
//         double area = await cv.contourArea(approx);
//         if (area > maxArea && area > 1000) {
//           maxArea = area;
//           paperContour = approx;
//         }
//       }
//     }
//
//     List<List<double>> result = [];
//     if (paperContour != null) {
//       for (int i = 0; i < paperContour.length; i++) {
//         var pt = paperContour[i];
//         result.add([pt.x.toDouble(), pt.y.toDouble()]);
//       }
//     }
//
//     // Освобождаем ресурсы
//     mat.dispose();
//     gray.dispose();
//     blur.dispose();
//     edges.dispose();
//
//     return result;
//   } catch (e) {
//     // Если произошла ошибка, возвращаем пустой список
//     return [];
//   }
// }
//
//
// /// Упорядочивает 4 точки так, чтобы получилась последовательность:
// /// [верхний левый, верхний правый, нижний правый, нижний левый]
// List<cv.Point2f> orderPoints(List<cv.Point2f> pts) {
//   if (pts.length != 4) {
//     throw Exception('Ожидается ровно 4 точки');
//   }
//
//   // Инициализируем все четыре переменные первой точкой из списка.
//   cv.Point2f tl = pts[0];
//   cv.Point2f tr = pts[0];
//   cv.Point2f br = pts[0];
//   cv.Point2f bl = pts[0];
//
//   double minSum = double.infinity, maxSum = -double.infinity;
//   double minDiff = double.infinity, maxDiff = -double.infinity;
//
//   for (var pt in pts) {
//     double sum = pt.x + pt.y;
//     double diff = pt.y - pt.x;
//     if (sum < minSum) {
//       minSum = sum;
//       tl = pt;
//     }
//     if (sum > maxSum) {
//       maxSum = sum;
//       br = pt;
//     }
//     if (diff < minDiff) {
//       minDiff = diff;
//       tr = pt;
//     }
//     if (diff > maxDiff) {
//       maxDiff = diff;
//       bl = pt;
//     }
//   }
//   return [tl, tr, br, bl];
// }
// /// Функция, выполняемая в изоляте для обрезки изображения по найденному контуру.
// /// Ожидает Map с ключами:
// /// 'pngBytes' – исходное изображение в PNG,
// /// 'corners' – List<List<double>> с координатами 4-х углов,
// /// 'width', 'height' – размеры исходного изображения.
// /// Возвращает Uint8List с PNG-данными обрезанного изображения.
// Future<Uint8List> cropFrameInIsolate(Map<String, dynamic> params) async {
//   try {
//     // Исходные данные
//     Uint8List pngBytes = params['pngBytes'];
//     List<dynamic> cornersDynamic = params['corners']; // Ожидается список вида [[x1,y1],[x2,y2],[x3,y3],[x4,y4]]
//     int origWidth = params['width'];
//     int origHeight = params['height'];
//
//     // Декодируем исходное изображение в cv.Mat в цветном режиме
//     cv.Mat mat = cv.imdecode(pngBytes, cv.IMREAD_COLOR);
//     debugPrint("Исходное изображение: ширина = ${mat.width}, высота = ${mat.height}, channels = ${mat.channels}");
//
//     // Преобразуем список углов в список Point2f
//     List<cv.Point2f> srcPoints = cornersDynamic
//         .map<cv.Point2f>(
//             (item) => cv.Point2f(item[0].toDouble(), item[1].toDouble()))
//         .toList();
//
//     if (srcPoints.length != 4) {
//       throw Exception('Ожидается ровно 4 точки для обрезки');
//     }
//
//     // Упорядочиваем точки в порядке: верхний левый, верхний правый, нижний правый, нижний левый
//     List<cv.Point2f> orderedPoints = orderPoints(srcPoints);
//     debugPrint("Упорядоченные точки: ${orderedPoints.map((pt) => "(${pt.x}, ${pt.y})").join(', ')}");
//
//     // Вычисляем ширину итогового изображения как максимум из расстояний между верхними и нижними сторонами:
//     double widthTop = math.sqrt(math.pow(orderedPoints[1].x - orderedPoints[0].x, 2) +
//         math.pow(orderedPoints[1].y - orderedPoints[0].y, 2));
//     double widthBottom = math.sqrt(math.pow(orderedPoints[2].x - orderedPoints[3].x, 2) +
//         math.pow(orderedPoints[2].y - orderedPoints[3].y, 2));
//     double maxWidth = math.max(widthTop, widthBottom);
//
//     // Вычисляем высоту итогового изображения как максимум из расстояний между левыми и правыми сторонами:
//     double heightLeft = math.sqrt(math.pow(orderedPoints[3].x - orderedPoints[0].x, 2) +
//         math.pow(orderedPoints[3].y - orderedPoints[0].y, 2));
//     double heightRight = math.sqrt(math.pow(orderedPoints[2].x - orderedPoints[1].x, 2) +
//         math.pow(orderedPoints[2].y - orderedPoints[1].y, 2));
//     double maxHeight = math.max(heightLeft, heightRight);
//
//     debugPrint("Вычисленные размеры итогового изображения: maxWidth = $maxWidth, maxHeight = $maxHeight");
//
//     // Определяем целевые точки для перспективного преобразования
//     List<cv.Point2f> dstPoints = [
//       cv.Point2f(0, 0),
//       cv.Point2f(maxWidth - 1, 0),
//       cv.Point2f(maxWidth - 1, maxHeight - 1),
//       cv.Point2f(0, maxHeight - 1),
//     ];
//
//     // Получаем матрицу перспективного преобразования (используем Point2f-версии)
//     cv.VecPoint2f srcVec = cv.VecPoint2f.fromList(orderedPoints);
//     cv.VecPoint2f dstVec = cv.VecPoint2f.fromList(dstPoints);
//     cv.Mat perspectiveMatrix = cv.getPerspectiveTransform2f(srcVec, dstVec);
//     debugPrint("Матрица перспективного преобразования получена");
//
//     // Применяем перспективное преобразование для получения "выпрямленного" изображения
//     cv.Mat warped = await cv.warpPerspective(
//       mat,
//       perspectiveMatrix,
//       (maxWidth.toInt(), maxHeight.toInt()),
//     );
//     debugPrint("Изображение после warpPerspective: ширина = ${warped.width}, высота = ${warped.height}, channels = ${warped.channels}");
//
//     // Преобразуем цветовое пространство из BGR (стандарт OpenCV) в RGB
//     cv.Mat rgbMat = cv.cvtColor(warped, cv.COLOR_BGR2RGB);
//     debugPrint("Изображение после cvtColor: channels = ${rgbMat.channels}");
//
//     // Конвертируем полученное цветное изображение в PNG
//     final result = cv.imencode(".png", rgbMat);
//     if (!result.$1) {
//       throw Exception("Ошибка при кодировании изображения в PNG");
//     }
//     Uint8List croppedPng = result.$2;
//     debugPrint("Размер обрезанного изображения (PNG): ${croppedPng.lengthInBytes} байт");
//
//     // Освобождаем ресурсы
//     mat.dispose();
//     perspectiveMatrix.dispose();
//     warped.dispose();
//     rgbMat.dispose();
//     srcVec.dispose();
//     dstVec.dispose();
//
//     return croppedPng;
//   } catch (e) {
//     debugPrint("Ошибка при обрезке: $e");
//     return Uint8List(0);
//   }
// }
//
//
// // Функция для преобразования List<List<double>> в List<Point>
// List<cv.Point> convertToPointList(List<List<double>> list) {
//   return list.map((lst) => cv.Point(lst[0].round(), lst[1].round())).toList();
// }
//
// List<cv.Point> convertPoints(List<cv.Point2f> points2f) {
//   return points2f.map((pt) => cv.Point(pt.x.round(), pt.y.round())).toList();
// }
//
// /// CustomPainter, который получает список 4 углов (в исходных координатах), размер кадра и параметры поворота.
// /// Если rotateClockwise == true, применяется формула:
// ///     newX = (cameraImageSize.height - y)
// ///     newY = x
// /// Затем точки масштабируются с учетом вычисленного scale и отступов (offsetX, offsetY),
// /// а также добавляются корректирующие смещения.
// class PaperBorderPainter extends CustomPainter {
//   final List<Offset> corners;
//   final Size cameraImageSize;
//   final bool rotateClockwise;
//   final double offsetAdjustmentX;
//   final double offsetAdjustmentY;
//
//   PaperBorderPainter({
//     required this.corners,
//     required this.cameraImageSize,
//     this.rotateClockwise = false,
//     this.offsetAdjustmentX = 0,
//     this.offsetAdjustmentY = 0,
//   });
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     if (corners.length != 4) return;
//
//     // Преобразуем точки с учетом поворота
//     List<Offset> transformedCorners = corners.map((pt) {
//       if (rotateClockwise) {
//         // Поворот по часовой стрелке: (x, y) -> (cameraImageSize.height - y, x)
//         return Offset(cameraImageSize.height - pt.dy, pt.dx);
//       } else {
//         // Поворот против часовой стрелки: (x, y) -> (pt.dy, cameraImageSize.width - pt.dx)
//         return Offset(pt.dy, cameraImageSize.width - pt.dx);
//       }
//     }).toList();
//
//     // Новый размер изображения после поворота
//     final newImageSize = rotateClockwise
//         ? Size(cameraImageSize.height, cameraImageSize.width)
//         : Size(cameraImageSize.width, cameraImageSize.height);
//
//     // Вычисляем коэффициент масштабирования (сохраняя пропорции) и отступы для центрирования
//     final scale = math.min(size.width / newImageSize.width, size.height / newImageSize.height);
//     final drawWidth = newImageSize.width * scale;
//     final drawHeight = newImageSize.height * scale;
//     final offsetX = (size.width - drawWidth) / 2;
//     final offsetY = (size.height - drawHeight) / 2;
//
//     // Масштабируем и смещаем точки, добавляя корректирующие смещения
//     final List<Offset> scaledCorners = transformedCorners.map((pt) {
//       return Offset(pt.dx * scale + offsetX + offsetAdjustmentX,
//           pt.dy * scale + offsetY + offsetAdjustmentY);
//     }).toList();
//
//     // Отладочный вывод преобразованных точек
//     for (int i = 0; i < scaledCorners.length; i++) {
//       debugPrint('Scaled Corner $i: ${scaledCorners[i]}');
//     }
//
//     final linePaint = Paint()
//       ..color = Colors.red
//       ..strokeWidth = 3
//       ..style = PaintingStyle.stroke;
//     final pointPaint = Paint()
//       ..color = Colors.green
//       ..style = PaintingStyle.fill;
//
//     // Рисуем линии между точками
//     final path = Path();
//     path.moveTo(scaledCorners[0].dx, scaledCorners[0].dy);
//     for (int i = 1; i < scaledCorners.length; i++) {
//       path.lineTo(scaledCorners[i].dx, scaledCorners[i].dy);
//     }
//     path.close();
//     canvas.drawPath(path, linePaint);
//
//     // Рисуем кружки и метки для отладки
//     for (int i = 0; i < scaledCorners.length; i++) {
//       canvas.drawCircle(scaledCorners[i], 5, pointPaint);
//       final tp = TextPainter(
//         text: TextSpan(
//           text: "$i",
//           style: const TextStyle(color: Colors.white, fontSize: 14),
//         ),
//         textDirection: TextDirection.ltr,
//       );
//       tp.layout();
//       tp.paint(canvas, scaledCorners[i] + const Offset(6, -6));
//     }
//   }
//
//   @override
//   bool shouldRepaint(covariant PaperBorderPainter oldDelegate) {
//     return oldDelegate.corners != corners ||
//         oldDelegate.cameraImageSize != cameraImageSize ||
//         oldDelegate.rotateClockwise != rotateClockwise ||
//         oldDelegate.offsetAdjustmentX != offsetAdjustmentX ||
//         oldDelegate.offsetAdjustmentY != offsetAdjustmentY;
//   }
// }
//
