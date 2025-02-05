import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:owl_tech_pdf_scaner/app/app_colors.dart';
import 'package:owl_tech_pdf_scaner/app/app_text_style.dart';
import 'package:owl_tech_pdf_scaner/widgets/сustom_slider.dart';
import 'editable_movable_text.dart';
import '../models/scan_file.dart';

class TextEditWidget extends StatefulWidget {
  final ScanFile file;

  const TextEditWidget({super.key, required this.file});

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

  // Если лишних смещений не нужно, устанавливаем их в 0
  double textShiftX = 0;
  double textShiftY = 0;

  // Для многостраничного режима:
  int _currentPageIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
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
      return editMode ? 0.8 : 0.1;
    } else {
      return editMode ? 0.82 : 0.1;
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
  Future<void> saveTextInImage() async {
    final pagePath = widget.file.pages[_currentPageIndex];
    if (pagePath.isEmpty || _text.isEmpty || _text == '') return;
    final file = File(pagePath);
    if (!await file.exists()) return;
    try {
      final fileBytes = await file.readAsBytes();
      final ui.Codec codec = await ui.instantiateImageCodec(fileBytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image originalImage = frameInfo.image;
      final int originalWidth = originalImage.width;
      final int originalHeight = originalImage.height;
      // Предполагаемые размеры контейнера (как в макете)
      final double displayedWidth = 361.w;
      final double displayedHeight = 491.h;
      final double scaleX = originalWidth / displayedWidth;
      final double scaleY = originalHeight / displayedHeight;
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);
      canvas.drawImage(originalImage, Offset.zero, Paint());
      final double drawX = _textOffset.dx * scaleX;
      final double drawY = _textOffset.dy * scaleY;
      final textSpan = TextSpan(
        text: _text,
        style: TextStyle(fontSize: _fontSize * scaleX, color: _textColor),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(maxWidth: displayedWidth * scaleX);
      textPainter.paint(canvas, Offset(drawX, drawY));
      final ui.Picture picture = recorder.endRecording();
      final ui.Image finalImage =
          await picture.toImage(originalWidth, originalHeight);
      final ByteData? finalByteData =
          await finalImage.toByteData(format: ui.ImageByteFormat.png);
      if (finalByteData == null) return;
      final Uint8List finalBytes = finalByteData.buffer.asUint8List();
      await file.writeAsBytes(finalBytes);
      imageCache.clear();
      imageCache.clearLiveImages();
      setState(() {
        imageKey = UniqueKey();
      });
    } catch (e) {
      debugPrint('Ошибка при сохранении изображения с текстом: $e');
    }
  }

  /// Строит область редактирования для конкретной страницы.
  /// Если файл многостраничный, для каждой страницы используется соответствующий путь из widget.file.pages.
  Widget _buildTextAnnotationUI(String pagePath) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.only(top: 24.h),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double containerWidth = 361.w;
            final double containerHeight = 491.h;
            return SizedBox(
              width: containerWidth,
              height: containerHeight,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: Image.file(
                  File(pagePath),
                  key: imageKey,
                  fit: BoxFit.contain,
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
                    return _buildTextAnnotationUI(widget.file.pages[index]);
                  },
                ),
                // Отображение номера текущей страницы внизу
                Positioned(
                  bottom: 90.h, // отступ от нижнего края (можно регулировать)
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

  /// Метод для сохранения финального изображения с наложенным текстом.
  /// Вызывается, например, перед выходом или по отдельной кнопке.
  Future<void> saveFinalImage() async {
    // Если многостраничный режим – сохраняем для текущей страницы.
    final String path = widget.file.pages.length > 1
        ? widget.file.pages[_currentPageIndex]
        : widget.file.pages.first;
    if (path.isEmpty || _text.isEmpty || _text == '') return;
    final file = File(path);
    if (!await file.exists()) return;
    try {
      final fileBytes = await file.readAsBytes();
      final ui.Codec codec = await ui.instantiateImageCodec(fileBytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image originalImage = frameInfo.image;
      final int originalWidth = originalImage.width;
      final int originalHeight = originalImage.height;
      final double displayedWidth = 361.w;
      final double displayedHeight = 491.h;
      final double scaleX = originalWidth / displayedWidth;
      final double scaleY = originalHeight / displayedHeight;
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);
      canvas.drawImage(originalImage, Offset.zero, Paint());
      final double drawX = _textOffset.dx * scaleX;
      final double drawY = _textOffset.dy * scaleY;
      final textSpan = TextSpan(
        text: _text,
        style: TextStyle(fontSize: _fontSize * scaleX, color: _textColor),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(maxWidth: displayedWidth * scaleX);
      textPainter.paint(canvas, Offset(drawX, drawY));
      final ui.Picture picture = recorder.endRecording();
      final ui.Image finalImage =
          await picture.toImage(originalWidth, originalHeight);
      final ByteData? finalByteData =
          await finalImage.toByteData(format: ui.ImageByteFormat.png);
      if (finalByteData == null) return;
      final Uint8List finalBytes = finalByteData.buffer.asUint8List();
      await file.writeAsBytes(finalBytes);
      imageCache.clear();
      imageCache.clearLiveImages();
      setState(() {
        imageKey = UniqueKey();
      });
    } catch (e) {
      debugPrint('Ошибка при сохранении изображения с текстом: $e');
    }
  }
}
