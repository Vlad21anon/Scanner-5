import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:owl_tech_pdf_scaner/app/app_colors.dart';
import 'package:owl_tech_pdf_scaner/app/app_text_style.dart';
import 'package:owl_tech_pdf_scaner/widgets/сustom_slider.dart';
import '../screens/test.dart';
import 'editable_movable_text.dart';
import '../models/scan_file.dart';
import 'package:image/image.dart' as img;
import 'package:snappy_list_view/snappy_list_view.dart';
import 'dart:math' as math;

/// Виджет для редактирования текста с листингом страниц, позиционированием аннотации и панелью настроек (DraggableScrollableSheet)
class TextEditWidget extends StatefulWidget {
  final ScanFile file;
  final int? index;

  const TextEditWidget({super.key, required this.file, this.index});

  @override
  State<TextEditWidget> createState() => TextEditWidgetState();
}

class TextEditWidgetState extends State<TextEditWidget> {
  // Параметры редактирования текста
  String _text = '';
  Color _textColor = Colors.black;
  double _fontSize = 16.sp;
  Offset _textOffset = Offset(100.w, 100.h);
  bool isEditMode = false;
  LocalKey imageKey = UniqueKey();
  final GlobalKey<EditableMovableResizableTextState> textEditKey = GlobalKey();
  final GlobalKey _textBoundaryKey = GlobalKey();

  // GlobalKey для выбранного изображения – он используется для привязки слоя аннотаций к изображению.
  final GlobalKey _selectedImageKey = GlobalKey();

  // Размеры исходного изображения
  int _imageWidth = 0;
  int _imageHeight = 0;

  // Многостраничный режим
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

  /// Загружаем реальные размеры изображения из файла
  Future<void> _loadImageSize() async {
    final String path = widget.file.pages[_currentPageIndex];
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

  /// Вычисляет прямоугольник, в котором изображение отрисовывается с учетом BoxFit.contain
  Rect _getImageRect(Size containerSize) {
    if (_imageWidth == 0 || _imageHeight == 0) {
      return Rect.fromLTWH(0, 0, containerSize.width, containerSize.height);
    }
    final double containerAspect = containerSize.width / containerSize.height;
    final double imageAspect = _imageWidth / _imageHeight;
    double scale;
    double offsetX = 0;
    double offsetY = 0;
    if (imageAspect > containerAspect) {
      scale = containerSize.width / _imageWidth;
      final double realHeight = _imageHeight * scale;
      offsetY = (containerSize.height - realHeight) / 2;
      return Rect.fromLTWH(0, offsetY, containerSize.width, realHeight);
    } else {
      scale = containerSize.height / _imageHeight;
      final double realWidth = _imageWidth * scale;
      offsetX = (containerSize.width - realWidth) / 2;
      return Rect.fromLTWH(offsetX, 0, realWidth, containerSize.height);
    }
  }

  /// Метод для построения области с изображением.
  /// Если изображение выбрано (isSelected == true), то поверх него располагается слой с аннотациями,
  /// реализованный через Stack, что обеспечивает корректное позиционирование независимо от прокрутки.
  Widget _buildImageArea(String imagePath, double itemHeight, bool withShadow,
      {bool isSelected = false}) {
    final double containerWidth = 361.w;

    Widget imageWidget = ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: Image.file(
        File(imagePath),
        key: imageKey, // для принудительного обновления
        fit: BoxFit.contain,
        color: withShadow ? Colors.black.withAlpha(128) : null,
        colorBlendMode: withShadow ? BlendMode.darken : null,
      ),
    );

    Widget imageWidgetBack = ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: Image.file(
        File(imagePath),
        fit: BoxFit.contain,
        color: withShadow ? Colors.black.withAlpha(128) : null,
        colorBlendMode: withShadow ? BlendMode.darken : null,
      ),
    );

    // Если изображение выбрано, оборачиваем его в Stack с наложением аннотаций.
    if (isSelected) {
      imageWidget = Stack(
        children: [
          Positioned.fill(child: imageWidgetBack),
          Positioned.fill(child: imageWidget),
          // Слой аннотаций, занимающий всю область изображения.
          // Виджет редактируемого текста (с возможностью перемещения/масштабирования)
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
      );
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

  /// Сохраняем текст, наложенный на изображение, посредством скриншота текстового блока
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

      // Задаём размеры контейнера, в котором отрисовывается изображение
      // Если возможно, используем реальные размеры контейнера выбранного изображения
      Size containerSize = Size(361.w, 491.h); // значения по умолчанию
      if (_selectedImageKey.currentContext != null) {
        containerSize =
            _selectedImageKey.currentContext!.size ?? containerSize;
      }
      final Rect imageRect = _getImageRect(containerSize);

      // Вычисляем коэффициенты масштабирования
      final double scaleX = originalWidth / imageRect.width;
      final double scaleY = originalHeight / imageRect.height;

      // Захватываем скриншот текстового виджета (обёрнутого в RepaintBoundary)
      final RenderRepaintBoundary boundary = _textBoundaryKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      final double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
      final ui.Image textImage =
      await boundary.toImage(pixelRatio: devicePixelRatio);
      final Size textLogicalSize = boundary.size;

      // Вычисляем позицию текста относительно изображения
      final Offset adjustedOffset = _textOffset - imageRect.topLeft;
      final Offset drawOffset = Offset(
        adjustedOffset.dx * scaleX,
        adjustedOffset.dy * scaleY,
      );

      // Вычисляем размеры текстового блока на итоговом изображении
      final double destWidth = textLogicalSize.width * scaleX;
      final double destHeight = textLogicalSize.height * scaleY;

      final Rect srcRect = Rect.fromLTWH(
        0,
        0,
        textImage.width.toDouble(),
        textImage.height.toDouble(),
      );
      final Rect dstRect = Rect.fromLTWH(
        drawOffset.dx,
        drawOffset.dy,
        destWidth,
        destHeight,
      );

      // Рисуем итоговое изображение с наложенным текстом
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      canvas.drawImage(originalImage, Offset.zero, Paint());
      canvas.clipRect(
          Rect.fromLTWH(0, 0, originalWidth.toDouble(), originalHeight.toDouble()));
      canvas.drawImageRect(textImage, srcRect, dstRect, Paint());

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

  /// При смене страницы сохраняем изменения и сбрасываем состояние.
  Future<void> _onPageChanged(int newPage, double nd) async {
    await saveTextInImage();
    setState(() {
      _currentPageIndex = newPage;
      _text = '';
      _textOffset = Offset(100.w, 100.h);
      isEditMode = false;
      imageKey = UniqueKey();
    });
  }

  void updateImage(LocalKey key) {
    setState(() {
      imageKey = key;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool multiPage = widget.file.pages.length > 1;
    final double screenHeight = MediaQuery.of(context).size.height;
    // Для упрощения считаем, что высота выбранного и невыбранного элементов одинакова (50% экрана)
    final double selectedHeight = screenHeight * 0.50;
    final double nonSelectedHeight = screenHeight * 0.50;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.background,
      body: SizedBox.expand(
        child: Stack(
          children: [
            // Если файлов несколько, используем SnappyListView, иначе просто отображаем одно изображение.
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
                    index != _currentPageIndex, // затемнение для невыбранного элемента
                    isSelected: index == _currentPageIndex,
                  ),
                );
              },
            )
                : _buildImageArea(
                widget.file.pages.first, _imageHeight.toDouble(), false,
                isSelected: true),
            // Индикатор номера страницы (если многостраничный режим)
            if (multiPage)
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
            // Панель настроек внизу (DraggableScrollableSheet)
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

          ],
        ),
      ),
    );
  }

  double getInitialChildSize(BuildContext context, bool editMode) {
    final screenHeight = MediaQuery.of(context).size.height;
    return screenHeight >= 800 ? (editMode ? 0.8 : 0.45) : (editMode ? 0.82 : 0.5);
  }

  double getMinChildSize(BuildContext context, bool editMode) => 0.1;

  double getMaxChildSize(BuildContext context, bool editMode) {
    final screenHeight = MediaQuery.of(context).size.height;
    return screenHeight >= 800 ? (editMode ? 0.8 : 0.45) : (editMode ? 0.82 : 0.5);
  }

  /// Кружок для выбора цвета текста
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
              : (showBorder ? Border.all(color: AppColors.greyIcon, width: 2.w) : null),
        ),
      ),
    );
  }
}
