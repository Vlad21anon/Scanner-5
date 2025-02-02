import 'dart:io'; // Для File
import 'dart:math' as math; // Для min/max
import 'package:defer_pointer/defer_pointer.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img; // Для обрезки и кодирования
import 'package:owl_tech_pdf_scaner/models/scan_file.dart';
import 'package:owl_tech_pdf_scaner/widgets/resizable_note.dart';

import '../app/app_colors.dart';

///
/// Виджет обрезки фото: пользователь двигает «углы»,
/// а метод [saveCrop] обрезает и пересохраняет файл.
///
class CropWidget extends StatefulWidget {
  final ScanFile file;

  const CropWidget({super.key, required this.file});

  @override
  State<CropWidget> createState() => CropWidgetState();
}

class CropWidgetState extends State<CropWidget> {
  // Размеры изображения (в пикселях), полученные из файла
  int _imageWidth = 0;
  int _imageHeight = 0;

  // Флаг инициализации ручек.
  bool _initializedHandles = false;

  // 4 угла обрезаемой области (в координатах виджета)
  Offset _topLeft = const Offset(0, 0);
  Offset _topRight = const Offset(250, 50);
  Offset _bottomLeft = const Offset(50, 350);
  Offset _bottomRight = const Offset(250, 350);

  /// Константы для размеров ручек и области нажатия.
  static const double cornerSize = 13.0;
  static const Size horizontalSize = Size(39.0, 6.0);
  static const Size verticalSize = Size(6.0, 39.0);
  static const double hitSize = 44.0; // Минимальная область нажатия

  // Какую ручку сейчас тащим
  _HandlePosition? _draggingHandle;

  // Запоминаем позицию пальца при начале перетаскивания
  Offset _initialDragOffset = Offset.zero;

  // Запоминаем положения углов при начале перетаскивания
  late Offset _initialTopLeft,
      _initialTopRight,
      _initialBottomLeft,
      _initialBottomRight;

  // Для вычислений обрезки
  Size _containerSize = Size.zero;
  LocalKey imageKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _loadImageSize();
  }

  /// Считываем исходное изображение, чтобы узнать его реальные размеры.
  Future<void> _loadImageSize() async {
    try {
      final filePath = widget.file.path;
      if (filePath == null || filePath.isEmpty) return;

      final fileBytes = await File(filePath).readAsBytes();
      final decoded = img.decodeImage(fileBytes);
      if (decoded == null) return;

      setState(() {
        _imageWidth = decoded.width;
        _imageHeight = decoded.height;
      });
    } catch (e) {
      debugPrint('Ошибка при загрузке изображения: $e');
    }
  }

  /// Метод обрезки и сохранения (вызывается при смене режима).
  Future<void> saveCrop() async {
    final path = widget.file.path;
    if (path == null || path.isEmpty) {
      debugPrint('Файл не задан или путь пуст');
      return;
    }

    // Если не знаем исходные размеры, нет смысла обрезать
    if (_imageWidth == 0 || _imageHeight == 0) {
      debugPrint('Размеры изображения неизвестны (0x0)');
      return;
    }

    final file = File(path);
    if (!await file.exists()) {
      debugPrint('Файл не найден: $path');
      return;
    }

    try {
      // 1. Читаем изображение
      final fileBytes = await file.readAsBytes();
      final original = img.decodeImage(fileBytes);
      if (original == null) {
        debugPrint('Не удалось декодировать изображение');
        return;
      }

      // 2. Вычисляем прямоугольник обрезки (bounding box) в пикселях исходного изображения
      final cropRect = _calculateRealCropRect(
        containerSize: _containerSize,
        imageWidth: _imageWidth,
        imageHeight: _imageHeight,
      );

      // Чтобы избежать отрицательных размеров, проверим ещё раз
      if (cropRect.width <= 0 || cropRect.height <= 0) {
        debugPrint('Некорректные размеры обрезки: $cropRect');
        return;
      }

      // 3. Обрезаем
      final cropped = img.copyCrop(
        original,
        x: cropRect.left.toInt(),
        y: cropRect.top.toInt(),
        width: cropRect.width.toInt(),
        height: cropRect.height.toInt(),
      );

      // 4. Кодируем в PNG (можно в JPG — тогда используйте encodeJpg)
      final newBytes = img.encodePng(cropped);

      // 5. Перезаписываем файл
      await file.writeAsBytes(newBytes);

      debugPrint('Обрезка сохранена в тот же файл: $path');
      imageCache.clear();
      imageCache.clearLiveImages();
      final fileImage = FileImage(File(path));
      await fileImage.evict();
      setState(() {});
    } catch (e) {
      debugPrint('Ошибка обрезки: $e');
    }
  }

  /// Переводим координаты 4 углов в координаты исходного изображения (пиксели).
  /// Берём bounding box из четырёх точек и возвращаем [Rect].
  Rect _calculateRealCropRect({
    required Size containerSize,
    required int imageWidth,
    required int imageHeight,
  }) {
    if (containerSize.width == 0 || containerSize.height == 0) {
      return const Rect.fromLTWH(0, 0, 0, 0);
    }

    final widgetAspect = containerSize.width / containerSize.height;
    final imageAspect = imageWidth / imageHeight.toDouble();

    double scale;
    double offsetX = 0;
    double offsetY = 0;

    // Считаем, как вписан оригинал в контейнер при BoxFit.contain
    if (imageAspect > widgetAspect) {
      // Изображение "шире", чем контейнер
      scale = containerSize.width / imageWidth;
      final realHeight = imageHeight * scale;
      offsetY = (containerSize.height - realHeight) / 2;
    } else {
      // Изображение "выше" или пропорции равны
      scale = containerSize.height / imageHeight;
      final realWidth = imageWidth * scale;
      offsetX = (containerSize.width - realWidth) / 2;
    }

    // Функция перевода координат
    Offset toImageCoords(Offset screenOffset) {
      final dx = (screenOffset.dx - offsetX) / scale;
      final dy = (screenOffset.dy - offsetY) / scale;
      return Offset(dx, dy);
    }

    final p1 = toImageCoords(_topLeft);
    final p2 = toImageCoords(_topRight);
    final p3 = toImageCoords(_bottomLeft);
    final p4 = toImageCoords(_bottomRight);

    // Ищем bounding box
    final minX = math.min(math.min(p1.dx, p2.dx), math.min(p3.dx, p4.dx));
    final maxX = math.max(math.max(p1.dx, p2.dx), math.max(p3.dx, p4.dx));
    final minY = math.min(math.min(p1.dy, p2.dy), math.min(p3.dy, p4.dy));
    final maxY = math.max(math.max(p1.dy, p2.dy), math.max(p3.dy, p4.dy));

    final left = math.max(0, minX).toDouble();
    final top = math.max(0, minY).toDouble();
    final right = math.min(imageWidth.toDouble(), maxX);
    final bottom = math.min(imageHeight.toDouble(), maxY);

    return Rect.fromLTRB(left, top, right, bottom);
  }

  /// Вычисляем прямоугольник, в котором отрисовывается изображение с BoxFit.contain.
  Rect _getImageRect(Size containerSize) {
    if (_imageWidth == 0 || _imageHeight == 0) return Rect.zero;
    final containerAspect = containerSize.width / containerSize.height;
    final imageAspect = _imageWidth / _imageHeight;
    double scale;
    double offsetX = 0;
    double offsetY = 0;
    if (imageAspect > containerAspect) {
      scale = containerSize.width / _imageWidth;
      final realHeight = _imageHeight * scale;
      offsetY = (containerSize.height - realHeight) / 2;
      return Rect.fromLTWH(0, offsetY, containerSize.width, realHeight);
    } else {
      scale = containerSize.height / _imageHeight;
      final realWidth = _imageWidth * scale;
      offsetX = (containerSize.width - realWidth) / 2;
      return Rect.fromLTWH(offsetX, 0, realWidth, containerSize.height);
    }
  }

  void updateImage(LocalKey key) {
    setState(() {
      imageKey = key;
    });
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = widget.file.path;
    if (imagePath == null || imagePath.isEmpty) {
      return const Center(child: Text('Нет пути к изображению'));
    }

    return DeferredPointerHandler(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 24,
              bottom: 210,
            ),
            child: LayoutBuilder(
              builder: (ctx, innerConstraints) {
                // Размер «рабочей» области (после Padding)
                _containerSize = Size(
                  innerConstraints.maxWidth,
                  innerConstraints.maxHeight,
                );

                // Если ручки ещё не инициализированы и размеры изображения уже загружены,
                // вычисляем прямоугольник, в котором отрисовано изображение, и устанавливаем углы.
                if (!_initializedHandles && _imageWidth != 0 && _imageHeight != 0) {
                  final imageRect = _getImageRect(_containerSize);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() {
                      _topLeft = imageRect.topLeft;
                      _topRight = imageRect.topRight;
                      _bottomLeft = imageRect.bottomLeft;
                      _bottomRight = imageRect.bottomRight;
                      _initializedHandles = true;
                    });
                  });
                }

                return Stack(
                  children: [
                    // 1) Само изображение
                    Positioned.fill(
                      child: Image.file(
                        File(imagePath),
                        key: imageKey,
                        fit: BoxFit.contain,
                      ),
                    ),
                    // 2) Рисуем затемнение + рамку
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _CropPainter(
                          topLeft: _topLeft,
                          topRight: _topRight,
                          bottomLeft: _bottomLeft,
                          bottomRight: _bottomRight,
                        ),
                      ),
                    ),
                    // 3) Генерируем 8 ручек (4 угла + 4 стороны)
                    ..._buildAllHandles(),
                    // Можно добавить кнопки, кнопки «Сохранить» и т.д.
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// Создаём все 8 ручек.
  List<Widget> _buildAllHandles() {
    return [
      _buildHandle(_HandlePosition.topLeft),
      _buildHandle(_HandlePosition.topRight),
      _buildHandle(_HandlePosition.bottomLeft),
      _buildHandle(_HandlePosition.bottomRight),
      _buildHandle(_HandlePosition.topCenter),
      _buildHandle(_HandlePosition.rightCenter),
      _buildHandle(_HandlePosition.bottomCenter),
      _buildHandle(_HandlePosition.leftCenter),
    ];
  }

  /// Создаём конкретную ручку с новым дизайном, привязанную к границам изображения.
  Widget _buildHandle(_HandlePosition pos) {
    // Определяем тип ручки в зависимости от позиции
    late HandleType type;
    if (pos == _HandlePosition.topLeft ||
        pos == _HandlePosition.topRight ||
        pos == _HandlePosition.bottomLeft ||
        pos == _HandlePosition.bottomRight) {
      type = HandleType.corner;
    } else if (pos == _HandlePosition.topCenter ||
        pos == _HandlePosition.bottomCenter) {
      type = HandleType.horizontal;
    } else {
      type = HandleType.vertical;
    }

    // Вычисляем положение центра ручки
    final offset = _getHandleOffset(pos);

    // Определяем визуальный размер ручки в зависимости от типа
    late Size visualSize;
    switch (type) {
      case HandleType.corner:
        visualSize = const Size(cornerSize, cornerSize);
        break;
      case HandleType.horizontal:
        visualSize = horizontalSize;
        break;
      case HandleType.vertical:
        visualSize = verticalSize;
        break;
    }
    // Вычисляем размер области нажатия
    final double hitW = math.max(visualSize.width, hitSize);
    final double hitH = math.max(visualSize.height, hitSize);

    return Positioned(
      left: offset.dx - hitW / 2,
      top: offset.dy - hitH / 2,
      width: hitW,
      height: hitH,
      child: DeferPointer(
        link: null,
        // Здесь можно задать ссылку для отложенного распознавания указателей
        paintOnTop: true,
        child: GestureDetector(
          onPanStart: (details) {
            setState(() {
              _draggingHandle = pos;
              _initialDragOffset = details.globalPosition;
              // Запоминаем исходные координаты углов
              _initialTopLeft = _topLeft;
              _initialTopRight = _topRight;
              _initialBottomLeft = _bottomLeft;
              _initialBottomRight = _bottomRight;
            });
          },
          onPanUpdate: (details) {
            setState(() {
              final dx = details.globalPosition.dx - _initialDragOffset.dx;
              final dy = details.globalPosition.dy - _initialDragOffset.dy;
              _updateOffsets(pos, dx, dy);
            });
          },
          onPanEnd: (details) {
            setState(() {
              _draggingHandle = null;
            });
          },
          child: Container(
            width: hitW,
            height: hitH,
            alignment: Alignment.center,
            color: Colors.transparent,
            child: Container(
              width: visualSize.width,
              height: visualSize.height,
              decoration: () {
                // Оформление ручки в зависимости от типа
                switch (type) {
                  case HandleType.corner:
                    return BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.blueLight),
                      shape: BoxShape.circle,
                    );
                  case HandleType.horizontal:
                    return BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.blueLight),
                      borderRadius: BorderRadius.circular(11),
                    );
                  case HandleType.vertical:
                    return BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.blueLight),
                      borderRadius: BorderRadius.circular(11),
                    );
                }
              }(),
            ),
          ),
        ),
      ),
    );
  }

  /// Получаем "экранные" координаты ручки (середина кружка)
  Offset _getHandleOffset(_HandlePosition pos) {
    switch (pos) {
      case _HandlePosition.topLeft:
        return _topLeft;
      case _HandlePosition.topRight:
        return _topRight;
      case _HandlePosition.bottomLeft:
        return _bottomLeft;
      case _HandlePosition.bottomRight:
        return _bottomRight;

      case _HandlePosition.topCenter:
        return Offset(
          (_topLeft.dx + _topRight.dx) / 2,
          (_topLeft.dy + _topRight.dy) / 2,
        );
      case _HandlePosition.bottomCenter:
        return Offset(
          (_bottomLeft.dx + _bottomRight.dx) / 2,
          (_bottomLeft.dy + _bottomRight.dy) / 2,
        );
      case _HandlePosition.leftCenter:
        return Offset(
          (_topLeft.dx + _bottomLeft.dx) / 2,
          (_topLeft.dy + _bottomLeft.dy) / 2,
        );
      case _HandlePosition.rightCenter:
        return Offset(
          (_topRight.dx + _bottomRight.dx) / 2,
          (_topRight.dy + _bottomRight.dy) / 2,
        );
    }
  }

  /// Меняем координаты углов в зависимости от того, какую ручку тащим.
  void _updateOffsets(_HandlePosition pos, double dx, double dy) {
    // Начинаем с исходных положений (зафиксированных в onPanStart)
    Offset tl = _initialTopLeft;
    Offset tr = _initialTopRight;
    Offset bl = _initialBottomLeft;
    Offset br = _initialBottomRight;

    switch (pos) {
      // Углы
      case _HandlePosition.topLeft:
        tl = tl.translate(dx, dy);
        break;
      case _HandlePosition.topRight:
        tr = tr.translate(dx, dy);
        break;
      case _HandlePosition.bottomLeft:
        bl = bl.translate(dx, dy);
        break;
      case _HandlePosition.bottomRight:
        br = br.translate(dx, dy);
        break;

      // Середины сторон
      case _HandlePosition.topCenter:
        // Перемещаем только по оси Y верхние углы
        tl = tl.translate(0, dy);
        tr = tr.translate(0, dy);
        break;
      case _HandlePosition.bottomCenter:
        // Перемещаем только по оси Y нижние углы
        bl = bl.translate(0, dy);
        br = br.translate(0, dy);
        break;
      case _HandlePosition.leftCenter:
        // Перемещаем только по оси X левые углы
        tl = tl.translate(dx, 0);
        bl = bl.translate(dx, 0);
        break;
      case _HandlePosition.rightCenter:
        // Перемещаем только по оси X правые углы
        tr = tr.translate(dx, 0);
        br = br.translate(dx, 0);
        break;
    }

    // Здесь можно вставить проверки, чтобы не уходить за границы.
    // Например:
    tl = _clampToArea(tl);
    bl = _clampToArea(bl);
    br = _clampToArea(br);
    tr = _clampToArea(tr);
    // ... итд

    _topLeft = tl;
    _topRight = tr;
    _bottomLeft = bl;
    _bottomRight = br;
  }

  /// При желании ограничивать движение в пределах [0.._containerSize].
  Offset _clampToArea(Offset p) {
    final x = p.dx.clamp(0, _containerSize.width);
    final y = p.dy.clamp(0, _containerSize.height);
    return Offset(x.toDouble(), y.toDouble());
  }
}

/// 8 позиций «ручек»
enum _HandlePosition {
  topLeft,
  topCenter,
  topRight,
  rightCenter,
  bottomRight,
  bottomCenter,
  bottomLeft,
  leftCenter,
}

////
/// CustomPainter, который рисует затемнение и рамку по четырём углам.
///
class _CropPainter extends CustomPainter {
  final Offset topLeft;
  final Offset topRight;
  final Offset bottomLeft;
  final Offset bottomRight;
  final bool withShadow;

  _CropPainter({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
    this.withShadow = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintOverlay = Paint()..color = Colors.black54;
    final paintBorder = Paint()
      ..color = AppColors.blueLight
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    // затемнение
    withShadow ? canvas.drawRect(fullRect, paintOverlay) : null;

    final cropPath = Path()
      ..moveTo(topLeft.dx, topLeft.dy)
      ..lineTo(topRight.dx, topRight.dy)
      ..lineTo(bottomRight.dx, bottomRight.dy)
      ..lineTo(bottomLeft.dx, bottomLeft.dy)
      ..close();

    // «Вырезаем» обрезаемую область
    canvas.saveLayer(Rect.largest, Paint());
    canvas.drawRect(fullRect, paintOverlay);
    final clearPaint = Paint()..blendMode = BlendMode.dstOut;
    canvas.drawPath(cropPath, clearPaint);
    canvas.restore();

    // Рисуем белую рамку
    canvas.drawPath(cropPath, paintBorder);
  }

  @override
  bool shouldRepaint(_CropPainter oldDelegate) {
    return topLeft != oldDelegate.topLeft ||
        topRight != oldDelegate.topRight ||
        bottomLeft != oldDelegate.bottomLeft ||
        bottomRight != oldDelegate.bottomRight;
  }
}
