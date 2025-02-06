import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:owl_tech_pdf_scaner/app/app_colors.dart';
import 'package:owl_tech_pdf_scaner/app/app_text_style.dart';
import 'package:owl_tech_pdf_scaner/widgets/сustom_slider.dart';
import 'editable_movable_text.dart';
import '../models/scan_file.dart';
import 'package:image/image.dart' as img;
import 'dart:math' as math;

class TextEditWidget extends StatefulWidget {
  final ScanFile file;
  final int? index;

  const TextEditWidget({super.key, required this.file, this.index});

  @override
  State<TextEditWidget> createState() => TextEditWidgetState();
}

class TextEditWidgetState extends State<TextEditWidget> {
  // Общие параметры для наложения текста (по умолчанию для первой страницы)
  String _text = '';
  Color _textColor = Colors.black;
  double _fontSize = 16.sp;
  Offset _textOffset = Offset(100.w, 100.h);
  bool isEditMode = false;
  LocalKey imageKey = UniqueKey();
  final GlobalKey<EditableMovableResizableTextState> textEditKey = GlobalKey();
  final GlobalKey _textBoundaryKey = GlobalKey();

  int _imageWidth = 0;
  int _imageHeight = 0;

  double? _displayedWidth;
  double? _displayedHeight;

  // Для многостраничного режима:
  int _currentPageIndex = 0;
  late PageController _pageController;

  @override
  void didChangeDependencies() {
    _loadImageSize();
    super.didChangeDependencies();
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.index ?? 0);
    _currentPageIndex = widget.index ?? 0;
    _loadImageSize();
  }

  /// Метод для загрузки размеров изображения (например, из файла)
  Future<void> _loadImageSize() async {
    final String path = widget
        .file.pages[_currentPageIndex]; // или другой способ получения пути
    if (path.isEmpty) return;
    final fileBytes = await File(path).readAsBytes();
    final decoded = img.decodeImage(fileBytes);
    if (decoded != null) {
      setState(() {
        _imageWidth = decoded.width;
        _imageHeight = decoded.height;
      });
    }
  }

  /// Вычисляет прямоугольник, в котором реально отрисовывается изображение
  /// внутри контейнера с заданными размерами (с учетом BoxFit.contain).
  /// [containerSize] – размеры контейнера (например, 361.w x 491.h),
  /// [originalWidth] и [originalHeight] – реальные размеры исходного изображения.
  Rect _getImageRectForOriginal(
      Size containerSize, int originalWidth, int originalHeight) {
    if (originalWidth == 0 || originalHeight == 0) {
      return Rect.fromLTWH(0, 0, containerSize.width, containerSize.height);
    }
    final double containerAspect = containerSize.width / containerSize.height;
    final double imageAspect = originalWidth / originalHeight;
    double scale;
    double offsetX = 0;
    double offsetY = 0;
    if (imageAspect > containerAspect) {
      // Изображение шире контейнера: масштабируем по ширине.
      scale = containerSize.width / originalWidth;
      final double realHeight = originalHeight * scale;
      offsetY = (containerSize.height - realHeight) / 2;
      return Rect.fromLTWH(0, offsetY, containerSize.width, realHeight);
    } else {
      // Изображение выше контейнера: масштабируем по высоте.
      scale = containerSize.height / originalHeight;
      final double realWidth = originalWidth * scale;
      offsetX = (containerSize.width - realWidth) / 2;
      return Rect.fromLTWH(offsetX, 0, realWidth, containerSize.height);
    }
  }

  void updateImage(LocalKey key) {
    setState(() {
      imageKey = key;
    });
  }

  double getInitialChildSize(BuildContext context, bool editMode) {
    final screenHeight = MediaQuery.of(context).size.height;
    if (screenHeight >= 800) {
      return editMode ? 0.8 : 0.45;
    } else {
      return editMode ? 0.82 : 0.50;
    }
  }

  double getMinChildSize(BuildContext context, bool editMode) {
    final screenHeight = MediaQuery.of(context).size.height;
    if (screenHeight >= 800) {
      return editMode ? 0.1 : 0.1;
    } else {
      return editMode ? 0.1 : 0.1;
    }
  }

  double getMaxChildSize(BuildContext context, bool editMode) {
    final screenHeight = MediaQuery.of(context).size.height;
    if (screenHeight >= 800) {
      return editMode ? 0.8 : 0.45;
    } else {
      return editMode ? 0.82 : 0.50;
    }
  }

  /// Сохраняем наложенный текст для текущей страницы.
  /// Используется текущий путь из widget.file.pages[_currentPageIndex]
  /// Метод для сохранения наложенного текста на изображение,
  /// используя скриншот виджета с текстом (обернутого в RepaintBoundary).
  Future<void> saveTextInImage() async {
    final String path = widget.file.pages[_currentPageIndex];
    if (path.isEmpty || _text.isEmpty) return;
    final file = File(path);
    if (!await file.exists()) return;

    try {
      // Загружаем исходное изображение
      final fileBytes = await file.readAsBytes();
      final ui.Codec codec = await ui.instantiateImageCodec(fileBytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image originalImage = frameInfo.image;
      final int originalWidth = originalImage.width;
      final int originalHeight = originalImage.height;

      // Задаём размеры контейнера, в котором изображение отображается
      final double containerWidth = 361.w;
      final double containerHeight = 491.h;
      final Size containerSize = Size(containerWidth, containerHeight);

      // Вычисляем прямоугольник, в котором реально отрисовывается изображение (с учётом BoxFit.contain)
      final Rect imageRect = _getImageRect(containerSize);

      // Вычисляем коэффициенты масштабирования относительно отрисованного изображения
      final double scaleX = originalWidth / imageRect.width;
      final double scaleY = originalHeight / imageRect.height;

      // Захватываем скриншот текстового виджета
      final RenderRepaintBoundary boundary = _textBoundaryKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      final double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
      final ui.Image textImage = await boundary.toImage(pixelRatio: devicePixelRatio);

      // Получаем логические размеры текстового виджета (как указаны в layout)
      final Size textLogicalSize = boundary.size;

      // Вычисляем смещение текста относительно изображения:
      // _textOffset хранится относительно контейнера, поэтому вычитаем imageRect.topLeft
      final Offset adjustedOffset = _textOffset - imageRect.topLeft;
      final Offset drawOffset = Offset(
        adjustedOffset.dx * scaleX,
        adjustedOffset.dy * scaleY,
      );

      // Вычисляем целевые размеры текстового виджета на итоговом изображении
      final double destWidth = textLogicalSize.width * scaleX;
      final double destHeight = textLogicalSize.height * scaleY;

      // Исходный прямоугольник для захваченного изображения текста (полностью)
      final Rect srcRect = Rect.fromLTWH(
        0,
        0,
        textImage.width.toDouble(),
        textImage.height.toDouble(),
      );

      // Целевой прямоугольник, в который будет вписан текст
      final Rect dstRect = Rect.fromLTWH(
        drawOffset.dx,
        drawOffset.dy,
        destWidth,
        destHeight,
      );

      // Создаем холст для комбинирования исходного изображения и текста
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      // Рисуем исходное изображение
      canvas.drawImage(originalImage, Offset.zero, Paint());

      // Ограничиваем область отрисовки размерами исходного изображения
      canvas.clipRect(Rect.fromLTWH(
        0,
        0,
        originalWidth.toDouble(),
        originalHeight.toDouble(),
      ));

      // Рисуем текстовый виджет с учетом вычисленного масштабирования и смещения
      canvas.drawImageRect(textImage, srcRect, dstRect, Paint());

      // Завершаем запись и получаем итоговое изображение
      final ui.Picture picture = recorder.endRecording();
      final ui.Image finalImage =
      await picture.toImage(originalWidth, originalHeight);
      final ByteData? finalByteData =
      await finalImage.toByteData(format: ui.ImageByteFormat.png);
      if (finalByteData == null) return;
      final Uint8List finalBytes = finalByteData.buffer.asUint8List();

      // Перезаписываем файл итоговым изображением
      await file.writeAsBytes(finalBytes);
      imageCache.clear();
      imageCache.clearLiveImages();

      // Сбрасываем состояние
      setState(() {
        _text = '';
        _textOffset = Offset(100.w, 100.h);
        isEditMode = false;
        imageKey = UniqueKey();
      });
    } catch (e) {
      debugPrint('Ошибка при сохранении изображения с текстом: $e');
    }
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

  /// Строит область редактирования для аннотаций для конкретной страницы.
  /// Здесь аналогично вычисляем положение изображения, как в _buildCropUI.
  Widget _buildTextAnnotationUI(String pagePath) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.only(top: 24.h),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Получаем размеры контейнера, в котором нужно отобразить изображение
            final Size containerSize =
                Size(constraints.maxWidth, constraints.maxHeight - 200.h);
            // Вычисляем прямоугольник изображения по аналогии с _buildCropUI
            final Rect imageRect = _getImageRect(containerSize);

            return SizedBox(
              width: containerSize.width,
              height: containerSize.height,
              child: _buildImageArea(pagePath),
            );
          },
        ),
      ),
    );
  }

  /// Метод для построения области с изображением.
  Widget _buildImageArea(String imagePath) {
    final double containerWidth = 361.w;
    final double containerHeight = 491.h;
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.only(top: 24.h),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Сохраняем реальные размеры контейнера
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_displayedWidth != constraints.maxWidth ||
                  _displayedHeight != constraints.maxHeight) {
                setState(() {
                  _displayedWidth = constraints.maxWidth;
                  _displayedHeight = constraints.maxHeight;
                });
              }
            });
            return SizedBox(
              width: containerWidth,
              height: containerHeight,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: Image.file(
                  File(imagePath),
                  key: imageKey,
                  //fit: BoxFit.contain,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// При смене страницы в многостраничном режиме:
  /// 1. Сохраняем изменения для текущей страницы (наложенный текст).
  /// 2. Сбрасываем состояние (если требуется) и обновляем индекс.
  Future<void> _onPageChanged(int newPage) async {
    await saveTextInImage();
    setState(() {
      _currentPageIndex = newPage;
      // При необходимости можно сбрасывать текст и положение для новой страницы:
      _text = '';
      _textOffset = Offset(100.w, 100.h);
      isEditMode = false;
      imageKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Если многостраничный режим
    final bool multiPage = widget.file.pages.length > 1;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.background,
      body: SizedBox.expand(
        child: Stack(
          children: [
            // Если многостраничный режим – используем PageView
            multiPage
                ? Stack(
                    children: [
                      // Основной виджет PageView
                      PageView.builder(
                        controller: _pageController,
                        scrollDirection: Axis.vertical,
                        itemCount: widget.file.pages.length,
                        onPageChanged: _onPageChanged,
                        itemBuilder: (context, index) {
                          return _buildTextAnnotationUI(
                              widget.file.pages[index]);
                        },
                      ),
                      // Отображение номера текущей страницы внизу
                      Positioned(
                        bottom:
                            90.h, // отступ от нижнего края (можно регулировать)
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12.w, vertical: 6.h),
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
                    ],
                  )
                : _buildTextAnnotationUI(widget.file.pages.first),
            // Панель с настройками (DraggableScrollableSheet)
            DraggableScrollableSheet(
              initialChildSize: getInitialChildSize(context, isEditMode),
              minChildSize: getMinChildSize(context, isEditMode),
              maxChildSize: getMaxChildSize(context, isEditMode),
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(30.r)),
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.only(top: 12.h),
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Container(
                                width: 110.w,
                                height: 4.h,
                                decoration: BoxDecoration(
                                  color: AppColors.black,
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text('Font Size', style: AppTextStyle.exo20),
                            SizedBox(height: 16.h),
                            Row(
                              children: [
                                Text('Small', style: AppTextStyle.exo16),
                                Expanded(
                                  child: GradientSlider(
                                    isActive: true,
                                    onChanged: (val) {
                                      setState(() {
                                        _fontSize = val;
                                      });
                                    },
                                    value: _fontSize,
                                  ),
                                ),
                                Text('Large', style: AppTextStyle.exo16),
                              ],
                            ),
                            SizedBox(height: 24.h),
                            Text('Color', style: AppTextStyle.exo20),
                            SizedBox(height: 16.h),
                          ],
                        ),
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Padding(
                          padding: EdgeInsets.only(left: 16.w),
                          child: Row(
                            children: [
                              _colorDot(Colors.black),
                              _colorDot(Colors.white),
                              _colorDot(Colors.grey),
                              _colorDot(Colors.yellow),
                              _colorDot(Colors.orange),
                              _colorDot(Colors.red),
                              _colorDot(Colors.green),
                              _colorDot(Colors.greenAccent),
                              _colorDot(Colors.blue),
                              _colorDot(Colors.indigoAccent),
                              _colorDot(Colors.purple),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                    ],
                  ),
                );
              },
            ),
            // Виджет редактируемого текста, поверх изображения
            Positioned.fill(
              child: EditableMovableResizableText(
                key: ValueKey(_currentPageIndex),
                initialPosition: _textOffset,
                initialText: _text,
                textColor: _textColor,
                fontSize: _fontSize,
                onPositionChanged: (newPosition) {
                  setState(() {
                    _textOffset = newPosition;
                  });
                },
                onTextChanged: (newText) {
                  setState(() {
                    _text = newText;
                    isEditMode = false;
                  });
                },
                isEditMode: (value) {
                  setState(() {
                    isEditMode = value;
                  });
                },
                textBoundaryKey: _textBoundaryKey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _colorDot(Color color, {bool showBorder = true}) {
    final bool isSelected = (_textColor == color);
    return GestureDetector(
      onTap: () {
        setState(() {
          _textColor = color;
        });
      },
      child: Container(
        margin: EdgeInsets.only(right: 8.r),
        width: 30.w,
        height: 30.h,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: AppColors.black, width: 3.w)
              : (showBorder
                  ? Border.all(color: AppColors.greyIcon, width: 2.w)
                  : null),
        ),
      ),
    );
  }
  //
  // /// Метод для сохранения финального изображения с наложенным текстом.
  // /// Вызывается, например, перед выходом или по отдельной кнопке.
  // Future<void> saveFinalImage() async {
  //   // Если многостраничный режим – сохраняем для текущей страницы.
  //   final String path = widget.file.pages.length > 1
  //       ? widget.file.pages[_currentPageIndex]
  //       : widget.file.pages.first;
  //   if (path.isEmpty || _text.isEmpty) return;
  //   final file = File(path);
  //   if (!await file.exists()) return;
  //   try {
  //     final fileBytes = await file.readAsBytes();
  //     final ui.Codec codec = await ui.instantiateImageCodec(fileBytes);
  //     final ui.FrameInfo frameInfo = await codec.getNextFrame();
  //     final ui.Image originalImage = frameInfo.image;
  //     final int originalWidth = originalImage.width;
  //     final int originalHeight = originalImage.height;
  //
  //     // Задаём размеры контейнера, как в макете (отображаемой области)
  //     final double containerWidth = 361.w;
  //     final double containerHeight = 491.h;
  //     final Size containerSize = Size(containerWidth, containerHeight);
  //
  //     // Вычисляем прямоугольник, в котором отрисовывается изображение с BoxFit.contain
  //     // Здесь передаём размеры контейнера и "оригинальные" размеры контейнера (макета),
  //     // чтобы понять, как изображение масштабируется в макете.
  //     final Rect imageRect = _getImageRectForOriginal(
  //       containerSize,
  //       containerWidth.toInt(),
  //       containerHeight.toInt(),
  //     );
  //
  //     // Масштаб относительно реально отрисованного изображения в контейнере
  //     final double scaleX = originalWidth / imageRect.width;
  //     final double scaleY = originalHeight / imageRect.height;
  //
  //     // _textOffset задан относительно контейнера,
  //     // поэтому корректируем, чтобы получить позицию относительно области изображения
  //     final Offset adjustedOffset = _textOffset - imageRect.topLeft;
  //     final double drawX = adjustedOffset.dx * scaleX;
  //     final double drawY = adjustedOffset.dy * scaleY;
  //
  //     // Создаём TextSpan и TextPainter.
  //     // Убираем ограничение по ширине, чтобы текст полностью отрисовался, даже если выходит за границы.
  //     final textSpan = TextSpan(
  //       text: _text,
  //       style: TextStyle(fontSize: _fontSize * scaleX, color: _textColor),
  //     );
  //     final textPainter = TextPainter(
  //       text: textSpan,
  //       textDirection: TextDirection.ltr,
  //     );
  //     // Вызываем layout без ограничения по maxWidth,
  //     // чтобы получить полные размеры текста.
  //     textPainter.layout();
  //
  //     // Определяем boundingRect для текста (на финальном изображении)
  //     final Rect textRect =
  //         Rect.fromLTWH(drawX, drawY, textPainter.width, textPainter.height);
  //
  //     // Вычисляем объединяющий прямоугольник для исходного изображения (начиная с 0,0)
  //     // и текстового блока, чтобы итоговое изображение вместило оба элемента.
  //     final double unionLeft = math.min(0, textRect.left);
  //     final double unionTop = math.min(0, textRect.top);
  //     final double unionRight =
  //         math.max(originalWidth.toDouble(), textRect.right);
  //     final double unionBottom =
  //         math.max(originalHeight.toDouble(), textRect.bottom);
  //     final int newWidth = (unionRight - unionLeft).ceil();
  //     final int newHeight = (unionBottom - unionTop).ceil();
  //
  //     final ui.PictureRecorder recorder = ui.PictureRecorder();
  //     final Canvas canvas = Canvas(recorder);
  //
  //     // Рисуем исходное изображение с учетом смещения, чтобы его верхний левый угол оказался в (−unionLeft, −unionTop)
  //     canvas.drawImage(originalImage, Offset(-unionLeft, -unionTop), Paint());
  //
  //     // Рисуем текст: смещаем координаты так, чтобы они корректно отобразились относительно нового холста
  //     textPainter.paint(canvas, Offset(drawX - unionLeft, drawY - unionTop));
  //
  //     final ui.Picture picture = recorder.endRecording();
  //     // Создаем итоговое изображение с новыми размерами, чтобы вместить и фон, и текст полностью
  //     final ui.Image finalImage = await picture.toImage(newWidth, newHeight);
  //     final ByteData? finalByteData =
  //         await finalImage.toByteData(format: ui.ImageByteFormat.png);
  //     if (finalByteData == null) return;
  //     final Uint8List finalBytes = finalByteData.buffer.asUint8List();
  //     await file.writeAsBytes(finalBytes);
  //     imageCache.clear();
  //     imageCache.clearLiveImages();
  //     setState(() {
  //       _text = '';
  //       _textOffset = Offset(100.w, 100.h);
  //       isEditMode = false;
  //       imageKey = UniqueKey();
  //     });
  //   } catch (e) {
  //     debugPrint('Ошибка при сохранении изображения с текстом: $e');
  //   }
  // }
}
