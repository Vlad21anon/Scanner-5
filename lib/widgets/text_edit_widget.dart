import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:owl_tech_pdf_scaner/app/app_colors.dart';
import 'package:owl_tech_pdf_scaner/app/app_text_style.dart';
import 'package:owl_tech_pdf_scaner/widgets/%D1%81ustom_slider.dart';
import 'editable_movable_text.dart';
import '../models/scan_file.dart';

class TextEditWidget extends StatefulWidget {
  final ScanFile file;
  const TextEditWidget({super.key, required this.file});

  @override
  State<TextEditWidget> createState() => TextEditWidgetState();
}

class TextEditWidgetState extends State<TextEditWidget> {
  String _text = '';
  Color _textColor = Colors.black;
  double _fontSize = 16.sp;
  Offset _textOffset =  Offset(100.w, 100.h);
  bool isEditMode = false;
  LocalKey imageKey = UniqueKey();
  final GlobalKey<EditableMovableResizableTextState> textEditKey = GlobalKey();

  // Если лишних смещений не нужно, устанавливаем их в 0
  double textShiftX = 0;
  double textShiftY = 0;

  void updateImage(LocalKey key) {
    setState(() {
      imageKey = key;
    });
  }

  double getInitialChildSize(BuildContext context, bool addPenMode) {
    final screenHeight = MediaQuery.of(context).size.height;
    // Если высота экрана больше (например, iPhone 14), используем "больше" значения
    if (screenHeight >= 800) {
      return addPenMode ? 0.8 : 0.45;
    } else {
      // Для маленьких экранов (например, iPhone 7) немного уменьшаем размеры
      return addPenMode ? 0.82 : 0.50;
    }
  }

  double getMinChildSize(BuildContext context, bool addPenMode) {
    final screenHeight = MediaQuery.of(context).size.height;
    if (screenHeight >= 800) {
      return addPenMode ? 0.8 : 0.1;
    } else {
      return addPenMode ? 0.82 : 0.1;
    }
  }

  double getMaxChildSize(BuildContext context, bool addPenMode) {
    final screenHeight = MediaQuery.of(context).size.height;
    if (screenHeight >= 800) {
      return addPenMode ? 0.8 : 0.45;
    } else {
      return addPenMode ? 0.82 : 0.50;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.background,
      body: SizedBox.expand(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding:  EdgeInsets.only(top: 24.h),
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
                          File(widget.file.path),
                          key: imageKey,
                          fit: BoxFit.contain,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            DraggableScrollableSheet(
              initialChildSize: getInitialChildSize(context, isEditMode),
              minChildSize: getMinChildSize(context, isEditMode),
              maxChildSize: getMaxChildSize(context, isEditMode),
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding:  EdgeInsets.all(16.r),
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
                              isActive: isEditMode,
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
            Positioned.fill(
              child: EditableMovableResizableText(
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
              : (showBorder ? Border.all(color: AppColors.greyIcon, width: 2.w) : null),
        ),
      ),
    );
  }

  Future<void> saveTextInImage() async {
    final path = widget.file.path;
    if (path.isEmpty || _text == 'Tap to edit') return;
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
      final ui.Image finalImage = await picture.toImage(originalWidth, originalHeight);
      final ByteData? finalByteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);
      if (finalByteData == null) return;
      final Uint8List finalBytes = finalByteData.buffer.asUint8List();
      await file.writeAsBytes(finalBytes);
      final FileImage fileImage = FileImage(File(path));
      await fileImage.evict();
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
