import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
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
  String _text = 'Tap to edit';
  Color _textColor = Colors.black;
  double _fontSize = 16.0;
  Offset _textOffset = const Offset(100, 100);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SizedBox.expand(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 24),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const double containerWidth = 361;
                    const double containerHeight = 491;
                    return SizedBox(
                      width: containerWidth,
                      height: containerHeight,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
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
              initialChildSize: isEditMode ? 0.6 : 0.45,
              minChildSize: isEditMode ? 0.6 : 0.2,
              maxChildSize: isEditMode ? 0.6 : 0.45,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      Center(
                        child: Container(
                          width: 110,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.black,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Font Size', style: AppTextStyle.exo20),
                      const SizedBox(height: 16),
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
                      const SizedBox(height: 24),
                      Text('Color', style: AppTextStyle.exo20),
                      const SizedBox(height: 16),
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
                      const SizedBox(height: 16),
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
        margin: const EdgeInsets.only(right: 8),
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: AppColors.black, width: 3)
              : (showBorder ? Border.all(color: AppColors.greyIcon, width: 2) : null),
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
      const double displayedWidth = 361;
      const double displayedHeight = 491;
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
