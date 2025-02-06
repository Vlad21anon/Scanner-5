import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:owl_tech_pdf_scaner/app/app_colors.dart';
import 'package:owl_tech_pdf_scaner/app/app_icons.dart';
import 'package:owl_tech_pdf_scaner/app/app_text_style.dart';
import 'package:owl_tech_pdf_scaner/models/draw_point.dart';
import 'package:owl_tech_pdf_scaner/models/note_data.dart';
import 'package:owl_tech_pdf_scaner/models/scan_file.dart';
import 'package:owl_tech_pdf_scaner/widgets/custom_circular_button.dart';
import 'package:owl_tech_pdf_scaner/widgets/handwriting_painter.dart';
import 'package:owl_tech_pdf_scaner/widgets/сustom_slider.dart';
import 'package:owl_tech_pdf_scaner/widgets/resizable_note.dart';
import 'package:image/image.dart' as img;

import '../blocs/signatures_cubit.dart';

class PenEditWidget extends StatefulWidget {
  // Для поддержки нескольких файлов (или страниц) можно использовать поле pages,
  // а если файлов один, то используется path.
  final ScanFile file;
  final int? index;

  const PenEditWidget({super.key, required this.file, this.index});

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
  final List<DrawPoint?> _currentDrawing = [];

  // Локальный список для хранения подписей, добавленных на экран (отображаемых поверх изображения)
  List<NoteData> _placedSignatures = [];
  double? _displayedWidth;
  double? _displayedHeight;

  // Объявляем размеры изображения.
  int _imageWidth = 0;
  int _imageHeight = 0;

  // Для поддержки нескольких файлов/страниц
  int _currentPageIndex = 0;
  late PageController _pageController;

  bool get multiPage =>
      widget.file.pages.isNotEmpty && widget.file.pages.length > 1;

  @override
  void didChangeDependencies() {
    _currentPageIndex = widget.index ?? 0;
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

  /// Возвращает путь к изображению для текущей страницы.
  String get currentPagePath {
    if (multiPage) {
      return widget.file.pages[_currentPageIndex];
    } else {
      return widget.file.pages.first;
    }
  }

  /// При смене страницы сохраняем изменения и очищаем размещённые на экране подписи.
  Future<void> _onPageChanged(int newPage) async {
    await saveAnnotatedImage();
    setState(() {
      _currentPageIndex = newPage;
      _currentDrawing.clear();
      // Очистка подписей, добавленных на экран
      _placedSignatures = [];
      imageKey = UniqueKey();
    });
  }

  double getInitialChildSize(BuildContext context, bool addPenMode) {
    final screenHeight = MediaQuery.of(context).size.height;
    if (screenHeight >= 800) {
      return addPenMode ? 0.85 : 0.6;
    } else {
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

  void updateImage(LocalKey key) {
    setState(() {
      imageKey = key;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Определим размеры области рисования (должны совпадать с размерами контейнера)
    final double drawingWidth = 361.w;
    final double drawingHeight = 203.h;
    // Размеры контейнера для изображения и подписей
    final double containerWidth = 361.w;
    final double containerHeight = 491.h;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.background,
      body: RepaintBoundary(
        key: _globalKey,
        child: SizedBox.expand(
          child: Stack(
            children: [
              // Если файлов несколько, используем PageView, иначе просто отображаем одно изображение
              multiPage
                  ? PageView.builder(
                      controller: _pageController,
                      scrollDirection: Axis.vertical,
                      itemCount: widget.file.pages.length,
                      onPageChanged: _onPageChanged,
                      itemBuilder: (context, index) {
                        return _buildImageArea(widget.file.pages[index]);
                      },
                    )
                  : _buildImageArea(widget.file.pages.first),
              // Размещаем подписанные записи (ResizableNote) поверх изображения.
              // Оборачиваем их в Align+ClipRRect, чтобы они не выходили за рамки изображения.
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.only(top: 24.h),
                  child: SizedBox(
                    width: containerWidth,
                    height: containerHeight,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      child: Stack(
                        children: _placedSignatures.map((note) {
                          return ResizableNote(
                            note: note,
                            onUpdate: () {
                              setState(() {});
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
              // Отображение индекса текущей страницы (если файлов несколько)
              if (multiPage)
                Positioned(
                  bottom: 90.h,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
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
              // Панель настроек и сохранённых подписей
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
                                      // При завершении рисования добавляем новую подпись через кубит,
                                      // если их количество меньше 4.
                                      if (_currentDrawing.isNotEmpty) {
                                        final newSignature = NoteData(
                                          // Предполагается, что NoteData генерирует уникальный id
                                          points: List.from(_currentDrawing),
                                          offset: Offset(100.w, 100.w),
                                          color: _textColor,
                                          strokeWidth: _fontSize,
                                          size: Size(150.w, 100.h),
                                          baseSize: Size(361.w, 203.h),
                                        );
                                        final success = context
                                            .read<SignaturesCubit>()
                                            .addSignature(newSignature);
                                        if (success) {
                                          _currentDrawing.clear();
                                          isSelectEraser = false;
                                          setState(() {});
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Максимальное количество подписей достигнуто'),
                                            ),
                                          );
                                        }
                                      }
                                      setState(() {
                                        addPenMode = false;
                                      });
                                    },
                                    child: AppIcons.selectBlack22x15,
                                  ),
                                ],
                              )
                            : Text('Saved sign', style: AppTextStyle.exo20),
                        SizedBox(height: 18.h),
                        // Если режим добавления подписи активен, показываем область для рисования
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
                                padding: EdgeInsets.all(8.w),
                                width: drawingWidth,
                                height: drawingHeight,
                                child: ClipRect(
                                  child: GestureDetector(
                                    onPanStart: (details) {
                                      setState(() {
                                        RenderBox box = _drawingKey
                                            .currentContext!
                                            .findRenderObject() as RenderBox;
                                        Offset localPosition =
                                            box.globalToLocal(
                                                details.globalPosition);
                                        // Обеспечиваем, что точка находится внутри области рисования
                                        localPosition = Offset(
                                          localPosition.dx
                                              .clamp(0.0, drawingWidth),
                                          localPosition.dy
                                              .clamp(0.0, drawingHeight),
                                        );
                                        _currentDrawing.add(DrawPoint(
                                            localPosition, isSelectEraser));
                                      });
                                    },
                                    onPanUpdate: (details) {
                                      setState(() {
                                        RenderBox box = _drawingKey
                                            .currentContext!
                                            .findRenderObject() as RenderBox;
                                        Offset localPosition =
                                            box.globalToLocal(
                                                details.globalPosition);
                                        localPosition = Offset(
                                          localPosition.dx
                                              .clamp(0.0, drawingWidth),
                                          localPosition.dy
                                              .clamp(0.0, drawingHeight),
                                        );
                                        _currentDrawing.add(DrawPoint(
                                            localPosition, isSelectEraser));
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
                                        baseSize:
                                            Size(drawingWidth, drawingHeight),
                                      ),
                                      child: Container(),
                                    ),
                                  ),
                                ),
                              )
                            // Если режим добавления выключен, выводим Wrap со всеми сохранёнными подписями
                            : BlocBuilder<SignaturesCubit, List<NoteData>>(
                                builder: (context, signatures) {
                                  if (signatures.isEmpty) {
                                    // Если список пустой, показываем кнопку по центру.
                                    return Center(
                                      child: CustomCircularButton(
                                        withBorder: true,
                                        withShadow: false,
                                        onTap: () {
                                          setState(() {
                                            addPenMode = true;
                                          });
                                        },
                                        child: AppIcons.plusBlack22x22,
                                      ),
                                    );
                                  } else {
                                    // Если список не пустой, отображаем Wrap со списком подписей и кнопкой добавления.
                                    return Wrap(
                                      alignment: WrapAlignment.start,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      spacing: 16.w,
                                      runSpacing: 8.w,
                                      children: [
                                        ...signatures.map((note) {
                                          return GestureDetector(
                                            onTap: () {
                                              // При нажатии на подпись добавляем её в локальный список для отображения на экране.
                                              setState(() {
                                                // Если такая подпись уже добавлена, можно не добавлять повторно.
                                                if (!_placedSignatures.any(
                                                    (e) => e.id == note.id)) {
                                                  _placedSignatures.add(note);
                                                }
                                              });
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(12.r)),
                                                color: AppColors.white,
                                                border: Border.all(
                                                  width: 2.w,
                                                  color: AppColors.greyIcon,
                                                ),
                                              ),
                                              padding: EdgeInsets.all(8.w),
                                              width: 148.w,
                                              height: 95.h,
                                              child: Stack(
                                                children: [
                                                  CustomPaint(
                                                    painter: HandwritingPainter(
                                                      points: note.points,
                                                      color: note.color,
                                                      strokeWidth:
                                                          note.strokeWidth,
                                                      baseSize: note.baseSize,
                                                    ),
                                                    child: Container(),
                                                  ),
                                                  Positioned(
                                                    top: 0,
                                                    right: 0,
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        context
                                                            .read<
                                                                SignaturesCubit>()
                                                            .removeSignature(
                                                                note.id);
                                                      },
                                                      child: AppIcons.x22x15,
                                                    ),
                                                  ),
                                                ],
                                              ),
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
                                    );
                                  }
                                },
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

  /// Метод для сохранения аннотированного изображения для текущей страницы.
  /// Метод для сохранения аннотированного изображения для текущей страницы.
  Future<void> saveAnnotatedImage() async {
    final path = currentPagePath;
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

      // Задаём размеры контейнера, в котором изображение отображается.
      final double containerWidth = 361.w;
      final double containerHeight = 491.h;
      final Size containerSize = Size(containerWidth, containerHeight);

      // Вычисляем прямоугольник, в котором реально отрисовывается изображение с BoxFit.contain.
      final Rect imageRect = _getImageRect(containerSize);

      // Вычисляем коэффициенты масштабирования относительно отрисованного изображения.
      final double scaleX = originalWidth / imageRect.width;
      final double scaleY = originalHeight / imageRect.height;

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      // Рисуем исходное изображение (на всю его область).
      canvas.drawImage(originalImage, Offset.zero, Paint());

      // Устанавливаем clipRect равным размерам исходного изображения.
      // Таким образом, всё, что выходит за его пределы, будет обрезано.
      canvas.clipRect(Rect.fromLTWH(0, 0, originalWidth.toDouble(), originalHeight.toDouble()));

      // Получаем подписанные записи (signatures), размещённые поверх изображения.
      final signatures = _placedSignatures;
      for (var note in signatures) {
        // Смещаем позицию подписи: note.offset задаётся относительно контейнера,
        // поэтому вычитаем imageRect.topLeft, чтобы получить координаты относительно изображения.
        final Offset adjustedOffset = note.offset - imageRect.topLeft;
        final Offset notePos = Offset(
          adjustedOffset.dx * scaleX,
          adjustedOffset.dy * scaleY,
        );

        // Вычисляем масштаб подписи относительно изображения.
        final double noteScaleX = (note.size.width / note.baseSize.width) * scaleX;
        final double noteScaleY = (note.size.height / note.baseSize.height) * scaleY;

        // Рисуем линии подписи.
        for (int i = 0; i < note.points.length - 1; i++) {
          final DrawPoint? current = note.points[i];
          final DrawPoint? next = note.points[i + 1];
          if (current != null && next != null) {
            final Offset p1 = notePos +
                Offset(
                  current.offset.dx * noteScaleX,
                  current.offset.dy * noteScaleY,
                );
            final Offset p2 = notePos +
                Offset(
                  next.offset.dx * noteScaleX,
                  next.offset.dy * noteScaleY,
                );
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

      final ui.Picture picture = recorder.endRecording();
      final ui.Image finalImage =
      await picture.toImage(originalWidth, originalHeight);
      final ByteData? finalByteData =
      await finalImage.toByteData(format: ui.ImageByteFormat.png);
      if (finalByteData == null) return;
      final Uint8List finalBytes = finalByteData.buffer.asUint8List();

      // Перезаписываем файл итоговым изображением.
      await file.writeAsBytes(finalBytes);
      imageCache.clear();
      imageCache.clearLiveImages();
      final FileImage fileImage = FileImage(file);
      await fileImage.evict();
      setState(() {
        // После сохранения очищаем временные данные и генерируем новый ключ для обновления превью.
        _currentDrawing.clear();
        _placedSignatures.clear();
        imageKey = UniqueKey();
      });
    } catch (e) {
      debugPrint('Ошибка при сохранении аннотированного изображения: $e');
    }
  }

  /// Метод для загрузки размеров изображения (например, из файла)
  Future<void> _loadImageSize() async {
    final String path = widget.file.pages[_currentPageIndex]; // или другой способ получения пути
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

  // Вычисляет прямоугольник, в котором фактически отрисовывается изображение
  /// внутри контейнера (с учетом BoxFit.contain).
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
      // Изображение шире контейнера: масштабируем по ширине.
      scale = containerSize.width / _imageWidth;
      final double realHeight = _imageHeight * scale;
      offsetY = (containerSize.height - realHeight) / 2;
      return Rect.fromLTWH(0, offsetY, containerSize.width, realHeight);
    } else {
      // Изображение выше контейнера: масштабируем по высоте.
      scale = containerSize.height / _imageHeight;
      final double realWidth = _imageWidth * scale;
      offsetX = (containerSize.width - realWidth) / 2;
      return Rect.fromLTWH(offsetX, 0, realWidth, containerSize.height);
    }
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
        margin: EdgeInsets.only(right: 8.w),
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
        child: Center(
          child: FittedBox(
            child: AppIcons.eraser28x26,
          ),
        ),
      ),
    );
  }
}
