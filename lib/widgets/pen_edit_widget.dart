import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:owl_tech_pdf_scaner/widgets/%D1%81ustom_slider.dart';
import 'package:owl_tech_pdf_scaner/widgets/resizable_note.dart';
import 'dart:ui' as ui;

import '../app/app_colors.dart';
import '../app/app_text_style.dart';
import '../gen/assets.gen.dart';
import '../models/draw_point.dart';
import '../models/note_data.dart';
import '../models/scan_file.dart';
import 'custom_circular_button.dart';
import 'handwriting_painter.dart';

/// Виджет для редактирования с возможностью добавления рукописных записей.
/// Параметр [onSave] позволяет через callback вернуть сохранённый итоговый файл.
class PenEditWidget extends StatefulWidget {
  final ScanFile file;
  final Function(File)? onSave; // Callback для сохранения итогового изображения

  const PenEditWidget({super.key, required this.file, this.onSave});

  @override
  State<PenEditWidget> createState() => PenEditWidgetState();
}

class PenEditWidgetState extends State<PenEditWidget> {
  /// Флаг режима добавления рукописной записи
  bool addPenMode = false;

  /// Выбранный цвет для рисования (при обычном режиме)
  Color _textColor = Colors.black;

  /// Толщина линии (также используется как «размер шрифта»)
  double _fontSize = 16.0;

  /// Флаг, отвечающий за режим стирания (если true – включён режим «стиралки»)
  bool isSelectEraser = false;

  /// Ключ для RepaintBoundary (для сохранения итогового изображения)
  final GlobalKey _globalKey = GlobalKey();

  /// Ключ для области рисования (для корректного вычисления локальных координат)
  final GlobalKey _drawingKey = GlobalKey();

  /// Список сохранённых заметок
  final List<NoteData> _notes = [];

  /// Список точек для текущего штриха (null – разделитель штриха)
  final List<DrawPoint?> _currentDrawing = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RepaintBoundary(
        key: _globalKey,
        child: SizedBox.expand(
          child: Stack(
            children: [
              /// (1) Отображение исходного изображения
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: SizedBox(
                    width: 361,
                    height: 491,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                      child: Image.file(
                        File(widget.file.path),
                        //key: UniqueKey(),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),

              /// (1.1) Отображение сохранённых рукописных записей на изображении
              /// Используем виджет ResizableNote для возможности изменения размеров (по 8 сторонам)
              ..._notes.map((note) {
                return ResizableNote(
                  note: note,
                  onUpdate: () {
                    setState(() {});
                  },
                );
              }),

              /// (2) Нижняя панель (DraggableScrollableSheet)
              DraggableScrollableSheet(
                // При режиме редактирования панель раскрывается почти на всю высоту.
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
                    // В режиме редактирования отключаем скроллинг.
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

                        // Заголовок панели зависит от режима
                        addPenMode
                            ? Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Add sign',
                                    style: AppTextStyle.exo20,
                                  ),
                                  // При подтверждении рисунка сохраняем текущий штрих в список заметок
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
                                              // Задаём дефолтный размер для отображения заметки
                                              size: const Size(150, 100),
                                              // Базовый размер – размер области, где происходило рисование
                                              baseSize: const Size(361, 203),
                                            ),
                                          );
                                          _currentDrawing.clear();
                                          // Сбрасываем режим стирания при подтверждении
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
                            : Text(
                                'Saved sign',
                                style: AppTextStyle.exo20,
                              ),
                        const SizedBox(height: 18),

                        // Если включён режим редактирования – показываем область для рисования
                        addPenMode
                            ? Container(
                                key: _drawingKey,
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
                                width: 361,
                                height: 203,
                                child: GestureDetector(
                                  onPanStart: (details) {
                                    setState(() {
                                      RenderBox box = _drawingKey
                                          .currentContext!
                                          .findRenderObject() as RenderBox;
                                      Offset localPosition = box.globalToLocal(
                                          details.globalPosition);
                                      _currentDrawing.add(DrawPoint(
                                          localPosition, isSelectEraser));
                                    });
                                  },
                                  onPanUpdate: (details) {
                                    setState(() {
                                      RenderBox box = _drawingKey
                                          .currentContext!
                                          .findRenderObject() as RenderBox;
                                      Offset localPosition = box.globalToLocal(
                                          details.globalPosition);
                                      _currentDrawing.add(DrawPoint(
                                          localPosition, isSelectEraser));
                                    });
                                  },
                                  onPanEnd: (details) {
                                    _currentDrawing.add(null); // Разрыв штриха
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
                            :
                            // Если не в режиме редактирования – отображаем превью сохранённых заметок
                            Wrap(
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
                                          // Кнопка удаления заметки
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
                                  // Кнопка для перехода в режим добавления записи
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

                        // Дополнительные настройки (только в режиме редактирования)
                        if (addPenMode)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 24),
                              Text(
                                'Font Size',
                                style: AppTextStyle.exo20,
                              ),
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

                              // Выбор цвета для рисования
                              Text(
                                'Color',
                                style: AppTextStyle.exo20,
                              ),
                              const SizedBox(height: 16),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _eraserDot(),
                                    SizedBox(width: 8),
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

  /// Виджет для выбора цвета
  Widget _colorDot(Color color, {bool showBorder = true}) {
    final bool isSelected = (_textColor == color);
    return GestureDetector(
      onTap: () {
        setState(() {
          _textColor = color;
          // Если выбран обычный цвет, отключаем режим стирания
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

  /// Виджет для кнопки «Стиралка»
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

  /// Функция сохранения итогового изображения (скриншот с наложенными записями).
  /// При успешном сохранении вызывается callback [widget.onSave], если он передан.
  /// Функция сохранения аннотированного изображения для PenEditWidget.
  Future<void> saveAnnotatedImage() async {
    final path = widget.file.path;
    if (path.isEmpty) {
      debugPrint('Файл не задан или путь пуст');
      return;
    }
    final file = File(path);
    if (!await file.exists()) {
      debugPrint('Файл не найден: $path');
      return;
    }
    try {
      // 1. Чтение исходного файла и декодирование изображения.
      final fileBytes = await file.readAsBytes();
      final ui.Codec codec = await ui.instantiateImageCodec(fileBytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image originalImage = frameInfo.image;
      final int originalWidth = originalImage.width;
      final int originalHeight = originalImage.height;

      // 2. Задаём размеры отображаемого изображения в UI (например, 361×491).
      const double displayedWidth = 361;
      const double displayedHeight = 491;
      final double scaleX = originalWidth / displayedWidth;
      final double scaleY = originalHeight / displayedHeight;

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      // Рисуем исходное изображение.
      canvas.drawImage(originalImage, Offset.zero, Paint());

      // 3. Рисуем аннотации.
      // Для каждой заметки пересчитываем позицию и масштабируем координаты точек.
      for (var note in _notes) {
        final Offset notePos =
            Offset(note.offset.dx * scaleX, note.offset.dy * scaleY);
        final double noteScaleX =
            (note.size.width / note.baseSize.width) * scaleX;
        final double noteScaleY =
            (note.size.height / note.baseSize.height) * scaleY;
        for (int i = 0; i < note.points.length - 1; i++) {
          final DrawPoint? current = note.points[i];
          final DrawPoint? next = note.points[i + 1];
          if (current != null && next != null) {
            final Offset p1 = notePos +
                Offset(current.offset.dx * noteScaleX,
                    current.offset.dy * noteScaleY);
            final Offset p2 = notePos +
                Offset(
                    next.offset.dx * noteScaleX, next.offset.dy * noteScaleY);
            final double scaledStroke =
                note.strokeWidth * ((noteScaleX + noteScaleY) / 2);
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

      // 4. Получаем итоговое изображение.
      final ui.Picture picture = recorder.endRecording();
      final ui.Image finalImage =
          await picture.toImage(originalWidth, originalHeight);
      final ByteData? finalByteData =
          await finalImage.toByteData(format: ui.ImageByteFormat.png);
      if (finalByteData == null) {
        debugPrint('Не удалось получить данные итогового изображения');
        return;
      }
      final Uint8List finalBytes = finalByteData.buffer.asUint8List();

      // 5. Перезаписываем файл.
      await file.writeAsBytes(finalBytes);
      debugPrint('Аннотированное изображение сохранено в тот же файл: $path');
      imageCache.clear();
      imageCache.clearLiveImages();
      final FileImage fileImage = FileImage(file);
      await fileImage.evict();
      setState(() {});
    } catch (e) {
      debugPrint('Ошибка при сохранении аннотированного изображения: $e');
    }
  }
}
