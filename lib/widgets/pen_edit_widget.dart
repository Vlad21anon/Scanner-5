import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:owl_tech_pdf_scaner/app/app_colors.dart';
import 'package:owl_tech_pdf_scaner/app/app_icons.dart';
import 'package:owl_tech_pdf_scaner/app/app_text_style.dart';
import 'package:owl_tech_pdf_scaner/models/draw_point.dart';
import 'package:owl_tech_pdf_scaner/models/note_data.dart';
import 'package:owl_tech_pdf_scaner/models/scan_file.dart';
import 'package:owl_tech_pdf_scaner/widgets/custom_circular_button.dart';
import 'package:owl_tech_pdf_scaner/widgets/handwriting_painter.dart';
import 'package:owl_tech_pdf_scaner/widgets/%D1%81ustom_slider.dart';
import 'package:owl_tech_pdf_scaner/widgets/resizable_note.dart';

import '../services/screen_service.dart';

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
  void initState() {
    super.initState();
  }

  double getInitialChildSize(BuildContext context, bool addPenMode) {
    final screenHeight = MediaQuery.of(context).size.height;
    // Если высота экрана больше (например, iPhone 14), используем "больше" значения
    if (screenHeight >= 800) {
      return addPenMode ? 0.85 : 0.6;
    } else {
      // Для маленьких экранов (например, iPhone 7) немного уменьшаем размеры
      return addPenMode ? 0.95 : 0.55;
    }
  }

  double getMinChildSize(BuildContext context, bool addPenMode) {
    final screenHeight = MediaQuery.of(context).size.height;
    if (screenHeight >= 800) {
      return addPenMode ? 0.85 : 0.1;
    } else {
      return addPenMode ? 0.95 : 0.1;
    }
  }

  double getMaxChildSize(BuildContext context, bool addPenMode) {
    final screenHeight = MediaQuery.of(context).size.height;
    if (screenHeight >= 800) {
      return addPenMode ? 0.85 : 0.6;
    } else {
      return addPenMode ? 0.95 : 0.55;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.background,
      body: RepaintBoundary(
        key: _globalKey,
        child: SizedBox.expand(
          child: Stack(
            children: [
              Align(
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
                      // Фиксированные размеры для изображения, если они требуются
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
              ..._notes.map((note) {
                return ResizableNote(
                  note: note,
                  onUpdate: () {
                    setState(() {});
                  },
                );
              }),
              DraggableScrollableSheet(
                initialChildSize: getInitialChildSize(context, addPenMode),
                minChildSize: getMinChildSize(context, addPenMode),
                maxChildSize: getMaxChildSize(context, addPenMode),
                builder: (context, scrollController) {
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius:
                      BorderRadius.vertical(top: Radius.circular(30.r)),
                    ),
                    child: ListView(
                      controller: scrollController,
                      physics: addPenMode
                          ? const NeverScrollableScrollPhysics()
                          : const BouncingScrollPhysics(),
                      padding: EdgeInsets.all(16.r),
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
                                        offset: Offset(100.w, 100.w),
                                        color: _textColor,
                                        strokeWidth: _fontSize,
                                        size:  Size(150.w, 100.h),
                                        baseSize:  Size(361.w, 203.h),
                                      ),
                                    );
                                    _currentDrawing.clear();
                                    isSelectEraser = false;
                                  }
                                  addPenMode = false;
                                });
                              },
                              child: AppIcons.selectBlack22x15,
                            ),
                          ],
                        )
                            : Text('Saved sign', style: AppTextStyle.exo20),
                        SizedBox(height: 18.h),
                        addPenMode
                            ? Container(
                          key: _drawingKey,
                          decoration: BoxDecoration(
                            borderRadius:
                             BorderRadius.all(Radius.circular(12.r)),
                            color: AppColors.white,
                            border: Border.all(
                              width: 2.w,
                              color: AppColors.greyIcon,
                            ),
                          ),
                          padding:  EdgeInsets.all(8.w),
                          width: 361.w,
                          height: 203.h,
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
                                baseSize: Size(361.w, 203.h),
                              ),
                              child: Container(),
                            ),
                          ),
                        )
                            : Wrap(
                          alignment: WrapAlignment.start,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 16.w,
                          runSpacing: 8.w,
                          children: [
                            ..._notes.map((note) {
                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius:  BorderRadius.all(
                                      Radius.circular(12.r)),
                                  color: AppColors.white,
                                  border: Border.all(
                                    width: 2.w,
                                    color: AppColors.greyIcon,
                                  ),
                                ),
                                padding:  EdgeInsets.all(8.w),
                                width: 148.w,
                                height: 95.h,
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
                                        child: AppIcons.x22x15,
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
                              child: AppIcons.plusBlack22x22,
                            ),
                          ],
                        ),
                        if (addPenMode)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                               SizedBox(height: 24.h),
                              Text('Font Size', style: AppTextStyle.exo20),
                               SizedBox(height: 16.h),
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
                               SizedBox(height: 24.h),
                              Text('Color', style: AppTextStyle.exo20),
                               SizedBox(height: 16.h),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _eraserDot(),
                                     SizedBox(width: 8.w),
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
        margin:  EdgeInsets.only(right: 8.w),
        width: 30.w,
        height: 30.w,
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

  Widget _eraserDot() {
    return GestureDetector(
      onTap: () {
        setState(() {
          isSelectEraser = !isSelectEraser;
        });
      },
      child: Container(
        width: 30.w,
        height: 30.w,
        color: Colors.transparent,
        child: Center(child: FittedBox(child: AppIcons.eraser28x26,),),
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
      final double displayedWidth = _displayedWidth ?? 361.w;
      final double displayedHeight = _displayedHeight ?? 491.h;
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
