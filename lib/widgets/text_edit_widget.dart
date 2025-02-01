import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:owl_tech_pdf_scaner/app/app_colors.dart';
import 'package:owl_tech_pdf_scaner/app/app_text_style.dart';
import 'package:owl_tech_pdf_scaner/widgets/%D1%81ustom_slider.dart';
import 'editable_movable_text.dart';
import '../models/scan_file.dart';
import 'dart:typed_data';

/// Виджет редактирования текста поверх изображения
class TextEditWidget extends StatefulWidget {
  final ScanFile file;

  const TextEditWidget({super.key, required this.file});

  @override
  State<TextEditWidget> createState() => TextEditWidgetState();
}

class TextEditWidgetState extends State<TextEditWidget> {
  /// Текущее содержимое текста (при желании связываем с EditableMovableText)
  String _text = 'Tap to edit';

  /// Текущий цвет текста
  Color _textColor = Colors.black;

  /// Текущий размер шрифта
  double _fontSize = 16.0;

  /// Текущая позиция текста (если хотим её отслеживать сверху)
  Offset _textOffset = const Offset(100, 100);

  bool isEditMode = false;

  // Создаём GlobalKey для доступа к состоянию EditableMovableResizableText
  final GlobalKey<EditableMovableResizableTextState> textEditKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SizedBox.expand(
        // SizedBox.expand даст Stack`у и всем вложенным элементам
        // чёткие размеры (ширина/высота экрана).
        child: Stack(
          children: [
            /// (1) Изображение по центру
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
                      key: UniqueKey(),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),

            /// (2) DraggableScrollableSheet (панель снизу)
            /// Помещаем его в Positioned.fill или просто без Positioned,
            /// чтобы занять всё доступное пространство.
            DraggableScrollableSheet(
              initialChildSize: 0.5,
              minChildSize: 0.2,
              maxChildSize: 0.6,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Хендлер (визуальная полоска) для жеста "потянуть"
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

                      // Настройка размера шрифта
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

                      // Выбор цвета
                      Text(
                        'Color',
                        style: AppTextStyle.exo20,
                      ),
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

            /// (3) Текст, который можно перетаскивать и редактировать
            /// Ставим последним в Stack, чтобы был "поверх всего".
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
                isEditMode: (bool value) {
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
              : (showBorder
                  ? Border.all(color: AppColors.greyIcon, width: 2)
                  : null),
        ),
      ),
    );
  }

  /// Функция сохранения текста в изображении.
  /// При сохранении учитываются положение, цвет и размер текста.
  /// Функция сохранения изображения, полученного из виджета Text
  Future<void> saveTextInImage() async {
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
      debugPrint("Начало сохранения изображения с текстом");

      // 1. Чтение исходного файла и декодирование изображения.
      final fileBytes = await file.readAsBytes();
      final ui.Codec codec = await ui.instantiateImageCodec(fileBytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image originalImage = frameInfo.image;
      final int originalWidth = originalImage.width;
      final int originalHeight = originalImage.height;
      debugPrint("Исходное изображение: ${originalWidth}x${originalHeight}");

      // 2. Задаём размеры отображаемого изображения в UI.
      const double displayedWidth = 361;
      const double displayedHeight = 491;
      final double scaleX = originalWidth / displayedWidth;
      final double scaleY = originalHeight / displayedHeight;
      debugPrint("Масштабирование: scaleX = $scaleX, scaleY = $scaleY");

      // 3. Создаём PictureRecorder и Canvas.
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      // Рисуем исходное изображение.
      canvas.drawImage(originalImage, Offset.zero, Paint());

      // 4. Рисуем текст.
      // Масштабируем позицию текста: _textOffset – координаты на экране (displayed),
      // переводим их в координаты исходного изображения.
      final double drawX = _textOffset.dx * scaleX;
      final double drawY = _textOffset.dy * scaleY;
      debugPrint("Позиция текста на изображении: x = $drawX, y = $drawY");

      // Создаём стиль параграфа.
      final ui.ParagraphStyle paragraphStyle = ui.ParagraphStyle(
        textAlign: TextAlign.left,
        // можно задать maxLines, ellipsis и т.д.
      );
      // Масштабируем размер шрифта также (например, по scaleX)
      final ui.TextStyle textStyle = ui.TextStyle(
        color: _textColor,
        fontSize: _fontSize * scaleX, // масштабирование размера шрифта
      );
      final ui.ParagraphBuilder paragraphBuilder = ui.ParagraphBuilder(paragraphStyle)
        ..pushStyle(textStyle)
        ..addText(_text);
      // Задаём ограничение по ширине – здесь можно использовать максимальную ширину текста на изображении.
      final ui.Paragraph paragraph = paragraphBuilder.build();
      paragraph.layout(ui.ParagraphConstraints(width: displayedWidth * scaleX));
      debugPrint("Параграф сформирован, ширина: ${displayedWidth * scaleX}");

      // Рисуем текст на канве.
      canvas.drawParagraph(paragraph, Offset(drawX, drawY));
      debugPrint("Текст отрисован на канве");

      // 5. Получаем итоговое изображение.
      final ui.Picture picture = recorder.endRecording();
      final ui.Image finalImage = await picture.toImage(originalWidth, originalHeight);
      final ByteData? finalByteData =
      await finalImage.toByteData(format: ui.ImageByteFormat.png);
      if (finalByteData == null) {
        debugPrint('Не удалось получить данные итогового изображения');
        return;
      }
      final Uint8List finalBytes = finalByteData.buffer.asUint8List();

      // 6. Перезаписываем файл.
      await file.writeAsBytes(finalBytes);
      debugPrint('Изображение с текстом сохранено в тот же файл: $path');

      // Очистка кэша изображений.
      imageCache.clear();
      imageCache.clearLiveImages();
      final FileImage fileImage = FileImage(file);
      await fileImage.evict();
    } catch (e) {
      debugPrint('Ошибка при сохранении изображения с текстом: $e');
    }
  }



}
