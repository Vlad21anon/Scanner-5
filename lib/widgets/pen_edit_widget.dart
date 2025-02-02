import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:owl_tech_pdf_scaner/app/app_colors.dart';
import 'package:owl_tech_pdf_scaner/app/app_text_style.dart';
import 'package:owl_tech_pdf_scaner/gen/assets.gen.dart';
import 'package:owl_tech_pdf_scaner/models/draw_point.dart';
import 'package:owl_tech_pdf_scaner/models/note_data.dart';
import 'package:owl_tech_pdf_scaner/models/scan_file.dart';
import 'package:owl_tech_pdf_scaner/widgets/crop_widget.dart';
import 'package:owl_tech_pdf_scaner/widgets/custom_circular_button.dart';
import 'package:owl_tech_pdf_scaner/widgets/handwriting_painter.dart';
import 'package:owl_tech_pdf_scaner/widgets/%D1%81ustom_slider.dart';
import 'package:owl_tech_pdf_scaner/widgets/resizable_note.dart';
import 'editable_movable_text.dart';

class PenEditWidget extends StatefulWidget {
  final ScanFile file;
  final Function(File)? onSave;
  const PenEditWidget({super.key, required this.file, this.onSave});

  @override
  State<PenEditWidget> createState() => PenEditWidgetState();
}

class PenEditWidgetState extends State<PenEditWidget> {
  bool addPenMode = false;
  Color _textColor = Colors.black;
  double _fontSize = 16.0;
  bool isSelectEraser = false;
  final GlobalKey _globalKey = GlobalKey();
  final GlobalKey _drawingKey = GlobalKey();
  LocalKey imageKey = UniqueKey();
  final List<NoteData> _notes = [];
  final List<DrawPoint?> _currentDrawing = [];
  double? _displayedWidth;
  double? _displayedHeight;

  void updateImage(LocalKey key) {
    setState(() {
      imageKey = key;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RepaintBoundary(
        key: _globalKey,
        child: SizedBox.expand(
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 24),
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
                      // Фиксированные размеры для изображения, если они требуются
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
              ..._notes.map((note) {
                return ResizableNote(
                  note: note,
                  onUpdate: () {
                    setState(() {});
                  },
                );
              }),
              DraggableScrollableSheet(
                initialChildSize: addPenMode ? 0.82 : 0.5,
                minChildSize: addPenMode ? 0.82 : 0.2,
                maxChildSize: addPenMode ? 0.82 : 0.5,
                builder: (context, scrollController) {
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius:
                      BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    child: ListView(
                      controller: scrollController,
                      physics: addPenMode
                          ? const NeverScrollableScrollPhysics()
                          : const BouncingScrollPhysics(),
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
                        addPenMode
                            ? Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Add sign', style: AppTextStyle.exo20),
                            CustomCircularButton(
                              withBorder: true,
                              withShadow: false,
                              onTap: () {
                                setState(() {
                                  if (_currentDrawing.isNotEmpty) {
                                    _notes.add(
                                      NoteData(
                                        points:
                                        List.from(_currentDrawing),
                                        offset: const Offset(100, 100),
                                        color: _textColor,
                                        strokeWidth: _fontSize,
                                        size: const Size(150, 100),
                                        baseSize: const Size(361, 203),
                                      ),
                                    );
                                    _currentDrawing.clear();
                                    isSelectEraser = false;
                                  }
                                  addPenMode = false;
                                });
                              },
                              child: Assets.images.select.image(
                                width: 22,
                                height: 15,
                                color: AppColors.black,
                              ),
                            ),
                          ],
                        )
                            : Text('Saved sign', style: AppTextStyle.exo20),
                        const SizedBox(height: 18),
                        addPenMode
                            ? Container(
                          key: _drawingKey,
                          decoration: BoxDecoration(
                            borderRadius:
                            const BorderRadius.all(Radius.circular(12)),
                            color: AppColors.white,
                            border: Border.all(
                              width: 2,
                              color: AppColors.greyIcon,
                            ),
                          ),
                          padding: const EdgeInsets.all(8),
                          width: 361,
                          height: 203,
                          child: GestureDetector(
                            onPanStart: (details) {
                              setState(() {
                                RenderBox box = _drawingKey.currentContext!
                                    .findRenderObject() as RenderBox;
                                Offset localPosition = box.globalToLocal(
                                    details.globalPosition);
                                _currentDrawing.add(
                                    DrawPoint(localPosition, isSelectEraser));
                              });
                            },
                            onPanUpdate: (details) {
                              setState(() {
                                RenderBox box = _drawingKey.currentContext!
                                    .findRenderObject() as RenderBox;
                                Offset localPosition = box.globalToLocal(
                                    details.globalPosition);
                                _currentDrawing.add(
                                    DrawPoint(localPosition, isSelectEraser));
                              });
                            },
                            onPanEnd: (details) {
                              _currentDrawing.add(null);
                            },
                            child: CustomPaint(
                              painter: HandwritingPainter(
                                points: _currentDrawing,
                                color: _textColor,
                                strokeWidth: _fontSize,
                                baseSize: const Size(361, 203),
                              ),
                              child: Container(),
                            ),
                          ),
                        )
                            : Wrap(
                          alignment: WrapAlignment.start,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 16,
                          runSpacing: 8,
                          children: [
                            ..._notes.map((note) {
                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(12)),
                                  color: AppColors.white,
                                  border: Border.all(
                                    width: 2,
                                    color: AppColors.greyIcon,
                                  ),
                                ),
                                padding: const EdgeInsets.all(8),
                                width: 148,
                                height: 95,
                                child: Stack(
                                  children: [
                                    CustomPaint(
                                      painter: HandwritingPainter(
                                        points: note.points,
                                        color: note.color,
                                        strokeWidth: note.strokeWidth,
                                        baseSize: note.baseSize,
                                      ),
                                      child: Container(),
                                    ),
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _notes.remove(note);
                                          });
                                        },
                                        child: Assets.images.x.image(
                                          width: 12,
                                          height: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            CustomCircularButton(
                              withBorder: true,
                              withShadow: false,
                              onTap: () {
                                setState(() {
                                  addPenMode = true;
                                });
                              },
                              child: Assets.images.plus.image(
                                width: 22,
                                height: 22,
                                color: AppColors.black,
                              ),
                            ),
                          ],
                        ),
                        if (addPenMode)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 24),
                              Text('Font Size', style: AppTextStyle.exo20),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Text('Small', style: AppTextStyle.exo16),
                                  Expanded(
                                    child: GradientSlider(
                                      isActive: addPenMode,
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
                                    _eraserDot(),
                                    const SizedBox(width: 8),
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
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
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
          isSelectEraser = false;
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
              : (showBorder
              ? Border.all(color: AppColors.greyIcon, width: 2)
              : null),
        ),
      ),
    );
  }

  Widget _eraserDot() {
    return GestureDetector(
      onTap: () {
        setState(() {
          isSelectEraser = !isSelectEraser;
        });
      },
      child: SizedBox(
        width: 30,
        height: 30,
        child: Assets.images.eraser.image(width: 28, height: 26),
      ),
    );
  }

  Future<void> saveAnnotatedImage() async {
    final path = widget.file.path;
    if (path.isEmpty) return;
    final file = File(path);
    if (!await file.exists()) return;
    try {
      final fileBytes = await file.readAsBytes();
      final ui.Codec codec = await ui.instantiateImageCodec(fileBytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image originalImage = frameInfo.image;
      final int originalWidth = originalImage.width;
      final int originalHeight = originalImage.height;
      // Если размеры контейнера не сохранены, используем дефолтные значения.
      final double displayedWidth = _displayedWidth ?? 361;
      final double displayedHeight = _displayedHeight ?? 491;
      final double scaleX = originalWidth / displayedWidth;
      final double scaleY = originalHeight / displayedHeight;
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);
      canvas.drawImage(originalImage, Offset.zero, Paint());
      for (var note in _notes) {
        final Offset notePos = Offset(note.offset.dx * scaleX, note.offset.dy * scaleY);
        final double noteScaleX = (note.size.width / note.baseSize.width) * scaleX;
        final double noteScaleY = (note.size.height / note.baseSize.height) * scaleY;
        for (int i = 0; i < note.points.length - 1; i++) {
          final DrawPoint? current = note.points[i];
          final DrawPoint? next = note.points[i + 1];
          if (current != null && next != null) {
            final Offset p1 = notePos + Offset(current.offset.dx * noteScaleX, current.offset.dy * noteScaleY);
            final Offset p2 = notePos + Offset(next.offset.dx * noteScaleX, next.offset.dy * noteScaleY);
            final double scaledStroke = note.strokeWidth * ((noteScaleX + noteScaleY) / 2);
            final Paint paint = Paint()
              ..strokeCap = StrokeCap.round
              ..strokeWidth = scaledStroke;
            if (current.isEraser || next.isEraser) {
              paint.blendMode = ui.BlendMode.clear;
            } else {
              paint.blendMode = ui.BlendMode.srcOver;
              paint.color = note.color;
            }
            canvas.drawLine(p1, p2, paint);
          }
        }
      }
      final ui.Picture picture = recorder.endRecording();
      final ui.Image finalImage = await picture.toImage(originalWidth, originalHeight);
      final ByteData? finalByteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);
      if (finalByteData == null) return;
      final Uint8List finalBytes = finalByteData.buffer.asUint8List();
      await file.writeAsBytes(finalBytes);
      imageCache.clear();
      imageCache.clearLiveImages();
      final FileImage fileImage = FileImage(file);
      await fileImage.evict();
      setState(() {
        imageKey = UniqueKey();
      });
    } catch (e) {
      debugPrint('Ошибка при сохранении аннотированного изображения: $e');
    }
  }
}
