import 'dart:io';
import 'dart:math' as math;
import 'package:defer_pointer/defer_pointer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image/image.dart' as img;
import 'package:owl_tech_pdf_scaner/app/app_text_style.dart';
import 'package:owl_tech_pdf_scaner/models/scan_file.dart';
import 'package:snappy_list_view/snappy_list_view.dart';
import '../app/app_colors.dart';
import '../screens/test.dart';

/// Виджет для обрезки изображения (поддержка многостраничного режима).
class MultiPageCropWidget extends StatefulWidget {
  final ScanFile file; // Передаётся объект с списком страниц
  final int? index;

  const MultiPageCropWidget({super.key, required this.file, this.index});

  @override
  State<MultiPageCropWidget> createState() => MultiPageCropWidgetState();
}

class MultiPageCropWidgetState extends State<MultiPageCropWidget> {
  // Индекс текущей страницы
  int _currentPageIndex = 0;

  // Контроллер для PageView (вертикальная прокрутка)
  late PageController _pageController;

  // Контроллер для колесика (если потребуется)
  FixedExtentScrollController _wheelController =
  FixedExtentScrollController(initialItem: 0);

  // Размеры изображения (в пикселях) для текущей страницы
  int _imageWidth = 0;
  int _imageHeight = 0;

  // Флаг инициализации ручек (для текущей страницы)
  bool _initializedHandles = false;

  // Координаты углов (в координатах контейнера)
  Offset _topLeft = const Offset(0, 0);
  Offset _topRight = Offset(250.w, 50.h);
  Offset _bottomLeft = Offset(50.w, 350.h);
  Offset _bottomRight = Offset(250.w, 350.h);

  // Константы для ручек
  static final double cornerSize = 13.w;
  static final Size horizontalSize = Size(39.w, 6.h);
  static final Size verticalSize = Size(6.w, 39.h);
  static final double hitSize = 44.w;

  _HandlePosition? _draggingHandle;
  Offset _initialDragOffset = Offset.zero;
  late Offset _initialTopLeft,
      _initialTopRight,
      _initialBottomLeft,
      _initialBottomRight;

  // Размер контейнера (рабочей области)
  Size _containerSize = Size.zero;
  LocalKey imageKey = UniqueKey();

  // GlobalKey для выбранного изображения – используется для привязки слоя аннотаций.
  final GlobalKey _selectedImageKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.index ?? 0);
    _currentPageIndex = widget.index ?? 0;
    _loadImageSize();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    _loadImageSize();
    _currentPageIndex = widget.index ?? 0;
    super.didChangeDependencies();
  }

  /// Загружаем размеры изображения для текущей страницы.
  Future<void> _loadImageSize() async {
    try {
      final pagePath = widget.file.pages[_currentPageIndex];
      if (pagePath.isEmpty) return;
      final fileBytes = await File(pagePath).readAsBytes();
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

  bool _isLoading = false;
  /// Сохраняем обрезку для текущей страницы.
  Future<void> saveCrop() async {
    final pagePath = widget.file.pages[_currentPageIndex];
    if (pagePath.isEmpty) {
      debugPrint('Путь к изображению пустой');
      return;
    }
    if (_imageWidth == 0 || _imageHeight == 0) {
      debugPrint('Размеры изображения неизвестны (0x0)');
      return;
    }
    final file = File(pagePath);
    if (!await file.exists()) {
      debugPrint('Файл не найден: $pagePath');
      return;
    }
    setState(() {
      _isLoading = true;
    });
    final cropRect = _calculateRealCropRect(
      containerSize: _containerSize,
      imageWidth: _imageWidth,
      imageHeight: _imageHeight,
    );

    if (cropRect.width <= 0 || cropRect.height <= 0) {
      debugPrint('Некорректные размеры обрезки: $cropRect');
      return;
    }

    final params = {
      'filePath': pagePath,
      'cropRect': {
        'left': cropRect.left,
        'top': cropRect.top,
        'width': cropRect.width,
        'height': cropRect.height,
      },
    };

    try {
      final newBytes = await compute(_processImageInIsolate, params);
      await file.writeAsBytes(newBytes);
      debugPrint('Обрезка для страницы $_currentPageIndex сохранена');
      final fileImage = FileImage(File(pagePath));
      await fileImage.evict();
      setState(() {});
    } catch (e) {
      debugPrint('Ошибка обрезки: $e');
    } finally {
      // Скрыть индикатор загрузки после завершения операции
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Переводим координаты ручек в реальные координаты исходного изображения.
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
    if (imageAspect > widgetAspect) {
      scale = containerSize.width / imageWidth;
      final realHeight = imageHeight * scale;
      offsetY = (containerSize.height - realHeight) / 2;
    } else {
      scale = containerSize.height / imageHeight;
      final realWidth = imageWidth * scale;
      offsetX = (containerSize.width - realWidth) / 2;
    }
    Offset toImageCoords(Offset screenOffset) {
      final dx = (screenOffset.dx - offsetX) / scale;
      final dy = (screenOffset.dy - offsetY) / scale;
      return Offset(dx, dy);
    }

    final p1 = toImageCoords(_topLeft);
    final p2 = toImageCoords(_topRight);
    final p3 = toImageCoords(_bottomLeft);
    final p4 = toImageCoords(_bottomRight);
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

  void updateImage(LocalKey key) {
    setState(() {
      imageKey = key;
    });
  }

  /// При переходе на новую страницу: сохраняем обрезку текущей страницы,
  /// сбрасываем состояния и загружаем размеры нового изображения.
  Future<void> _onPageChanged(int newPage, double nd) async {
    await saveCrop();
    setState(() {
      _currentPageIndex = newPage;
      _initializedHandles = false;
      _imageWidth = 0;
      _imageHeight = 0;
    });
    await _loadImageSize();
  }

  /// Строим UI для обрезки текущей страницы.
  Widget _buildCropUI(String imagePath) {
    return DeferredPointerHandler(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16.w,
              right: 16.w,
              top: 24.h,
              bottom: 210.h,
            ),
            child: LayoutBuilder(
              builder: (ctx, innerConstraints) {
                _containerSize = Size(innerConstraints.maxWidth, innerConstraints.maxHeight);
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
                return SizedBox(
                  width: innerConstraints.maxWidth,
                  height: innerConstraints.maxHeight,
                  child: Stack(
                    children: [
                      // Само изображение
                      Positioned.fill(
                        child: Image.file(
                          File(imagePath),
                          key: imageKey,
                          fit: BoxFit.contain,
                        ),
                      ),
                      // Затемнение и рамка
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                          child: CustomPaint(
                            painter: _CropPainter(
                              topLeft: _topLeft,
                              topRight: _topRight,
                              bottomLeft: _bottomLeft,
                              bottomRight: _bottomRight,
                            ),
                          ),
                        ),
                      ),
                      // Ручки
                      ..._buildAllHandles(),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // Вычисляем прямоугольник, в котором отрисовывается изображение с BoxFit.contain.
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

  /// Метод для построения области с изображением.
  /// Если изображение выбрано (isSelected == true), поверх него располагается слой с аннотациями.
  Widget _buildImageArea(String imagePath, double itemHeight, bool withShadow,
      {bool isSelected = false}) {
    final double containerWidth = 361.w;

    // Создаём базовое отображение изображения.
    Widget baseImageWidget = ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: Image.file(
        File(imagePath),
        key: imageKey,
        fit: BoxFit.contain,
        color: withShadow ? Colors.black.withAlpha(128) : null,
        colorBlendMode: withShadow ? BlendMode.darken : null,
      ),
    );
    Widget baseImageWidgetBack = ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: Image.file(
        File(imagePath),
        fit: BoxFit.contain,
        color: withShadow ? Colors.black.withAlpha(128) : null,
        colorBlendMode: withShadow ? BlendMode.darken : null,
      ),
    );

    Widget imageWidget;
    if (isSelected) {
      imageWidget = DeferredPointerHandler(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16.w,
                right: 16.w,
              ),
              child: LayoutBuilder(
                builder: (ctx, innerConstraints) {
                  _containerSize = Size(innerConstraints.maxWidth, innerConstraints.maxHeight);
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
                  return SizedBox(
                    width: innerConstraints.maxWidth,
                    height: innerConstraints.maxHeight,
                    child: Stack(
                      children: [
                        Positioned.fill(child: baseImageWidgetBack),
                        Positioned.fill(child: baseImageWidget),
                        // Слой аннотаций
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                            child: CustomPaint(
                              painter: _CropPainter(
                                topLeft: _topLeft,
                                topRight: _topRight,
                                bottomLeft: _bottomLeft,
                                bottomRight: _bottomRight,
                              ),
                            ),
                          ),
                        ),
                        ..._buildAllHandles(),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      );
    } else {
      imageWidget = baseImageWidget;
    }

    return Align(
      alignment: Alignment.center,
      child: Padding(
        padding: EdgeInsets.only(top: 24.h),
        child: SizedBox(
          key: isSelected ? _selectedImageKey : null,
          width: containerWidth,
          height: itemHeight,
          child: imageWidget,
        ),
      ),
    );
  }

  /// Создаём 8 ручек.
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

  Widget _buildHandle(_HandlePosition pos) {
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
    final offset = _getHandleOffset(pos);
    late Size visualSize;
    switch (type) {
      case HandleType.corner:
        visualSize = Size(cornerSize, cornerSize);
        break;
      case HandleType.horizontal:
        visualSize = horizontalSize;
        break;
      case HandleType.vertical:
        visualSize = verticalSize;
        break;
    }
    final double hitW = math.max(visualSize.width, hitSize);
    final double hitH = math.max(visualSize.height, hitSize);
    return Positioned(
      left: offset.dx - hitW / 2,
      top: offset.dy - hitH / 2,
      width: hitW,
      height: hitH,
      child: DeferPointer(
        link: null,
        paintOnTop: true,
        child: GestureDetector(
          onPanStart: (details) {
            setState(() {
              _draggingHandle = pos;
              _initialDragOffset = details.globalPosition;
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
            (_topLeft.dx + _topRight.dx) / 2, (_topLeft.dy + _topRight.dy) / 2);
      case _HandlePosition.bottomCenter:
        return Offset(
            (_bottomLeft.dx + _bottomRight.dx) / 2,
            (_bottomLeft.dy + _bottomRight.dy) / 2);
      case _HandlePosition.leftCenter:
        return Offset(
            (_topLeft.dx + _bottomLeft.dx) / 2,
            (_topLeft.dy + _bottomLeft.dy) / 2);
      case _HandlePosition.rightCenter:
        return Offset(
            (_topRight.dx + _bottomRight.dx) / 2,
            (_topRight.dy + _bottomRight.dy) / 2);
    }
  }

  void _updateOffsets(_HandlePosition pos, double dx, double dy) {
    Offset tl = _initialTopLeft;
    Offset tr = _initialTopRight;
    Offset bl = _initialBottomLeft;
    Offset br = _initialBottomRight;
    switch (pos) {
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
      case _HandlePosition.topCenter:
        tl = tl.translate(0, dy);
        tr = tr.translate(0, dy);
        break;
      case _HandlePosition.bottomCenter:
        bl = bl.translate(0, dy);
        br = br.translate(0, dy);
        break;
      case _HandlePosition.leftCenter:
        tl = tl.translate(dx, 0);
        bl = bl.translate(dx, 0);
        break;
      case _HandlePosition.rightCenter:
        tr = tr.translate(dx, 0);
        br = br.translate(dx, 0);
        break;
    }
    tl = _clampToArea(tl);
    tr = _clampToArea(tr);
    bl = _clampToArea(bl);
    br = _clampToArea(br);
    setState(() {
      _topLeft = tl;
      _topRight = tr;
      _bottomLeft = bl;
      _bottomRight = br;
    });
  }

  Offset _clampToArea(Offset p) {
    final x = p.dx.clamp(0, _containerSize.width);
    final y = p.dy.clamp(0, _containerSize.height);
    return Offset(x.toDouble(), y.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final bool multiPage = widget.file.pages.length > 1;
    final double screenHeight = MediaQuery.of(context).size.height;
    // Высота для выбранного и невыбранного элементов (по 50% экрана)
    final double selectedHeight = screenHeight * 0.50;
    final double nonSelectedHeight = screenHeight * 0.50;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.background,
      body: SizedBox.expand(
        child: Stack(
          children: [
            // Если файлов несколько, используем SnappyListView, иначе одно изображение.
            multiPage
                ? SnappyListView(
              snapAlignment: SnapAlignment.static(0.1),
              snapOnItemAlignment: SnapAlignment.static(0.1),
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: widget.file.pages.length,
              itemSnapping: true,
              physics: const CustomPageViewScrollPhysics(),
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                final double itemHeight = index == _currentPageIndex
                    ? selectedHeight
                    : nonSelectedHeight;
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 5),
                  child: _buildImageArea(
                    widget.file.pages[index],
                    itemHeight,
                    index != _currentPageIndex, // затемнение для невыбранного
                    isSelected: index == _currentPageIndex,
                  ),
                );
              },
            )
                : _buildImageArea(
                widget.file.pages.first, selectedHeight.toDouble(), false,
                isSelected: true),
            // Индикатор текущей страницы
            Positioned(
              bottom: 90.h,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    "${_currentPageIndex + 1} / ${widget.file.pages.length}",
                    style: AppTextStyle.exo20,
                  ),
                ),
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.5), // затемненный фон
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.blue,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Перечисление позиций ручек.
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

enum HandleType { corner, horizontal, vertical }

/// CustomPainter для отрисовки затемнения и рамки.
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
    if (withShadow) {
      canvas.drawRect(fullRect, paintOverlay);
    }
    final cropPath = Path()
      ..moveTo(topLeft.dx, topLeft.dy)
      ..lineTo(topRight.dx, topRight.dy)
      ..lineTo(bottomRight.dx, bottomRight.dy)
      ..lineTo(bottomLeft.dx, bottomLeft.dy)
      ..close();
    canvas.saveLayer(Rect.largest, Paint());
    canvas.drawRect(fullRect, paintOverlay);
    final clearPaint = Paint()..blendMode = BlendMode.dstOut;
    canvas.drawPath(cropPath, clearPaint);
    canvas.restore();
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

/// Функция для обработки изображения в изоляте.
Future<List<int>> _processImageInIsolate(Map<String, dynamic> params) async {
  final String filePath = params['filePath'];
  final Map<String, double> cropRect =
  params['cropRect']; // left, top, width, height

  final fileBytes = await File(filePath).readAsBytes();
  final original = img.decodeImage(fileBytes);
  if (original == null) {
    throw Exception('Не удалось декодировать изображение');
  }

  final cropped = img.copyCrop(
    original,
    x: cropRect['left']!.toInt(),
    y: cropRect['top']!.toInt(),
    width: cropRect['width']!.toInt(),
    height: cropRect['height']!.toInt(),
  );

  return img.encodePng(cropped);
}
