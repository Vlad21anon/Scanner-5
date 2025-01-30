import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:owl_tech_pdf_scaner/app/app_colors.dart';
import 'package:owl_tech_pdf_scaner/app/app_text_style.dart';
import 'package:owl_tech_pdf_scaner/widgets/%D1%81ustom_slider.dart';

import '../models/scan_file.dart';
import 'editable_movable_text.dart';

/// Виджет редактирования текста поверх изображения
class TextEditWidget extends StatefulWidget {
  final ScanFile file;

  const TextEditWidget({Key? key, required this.file}) : super(key: key);

  @override
  State<TextEditWidget> createState() => _TextEditWidgetState();
}

class _TextEditWidgetState extends State<TextEditWidget> {
  /// Текущее содержимое текста (при желании связываем с EditableMovableText)
  String _text = 'Нажмите для редактирования';

  /// Текущий цвет текста
  Color _textColor = Colors.black;

  /// Текущий размер шрифта
  double _fontSize = 16.0;

  /// Текущая позиция текста (если хотим её отслеживать сверху)
  Offset _textOffset = const Offset(100, 100);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Scaffold сам по себе занимает весь экран.
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
              maxChildSize: 0.5,
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
                      const SizedBox(height: 16),

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
              child: EditableMovableText(
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

  /// Пример сохранения текста на само изображение (если нужно)
  Future<void> saveTextInImage() async {
    try {
      final originalFile = File(widget.file.path);

      // 1. Считываем исходное изображение
      final bytes = await originalFile.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        throw Exception('Не удалось декодировать изображение');
      }

      // 2. Переводим координаты в целые пиксели (упрощённый вариант)
      final int xPos = _textOffset.dx.toInt();
      final int yPos = _textOffset.dy.toInt();

      // 3. Рисуем строку (встроенный шрифт подходит только для латиницы)
      img.drawString(
        decoded,
        _text,
        x: xPos,
        y: yPos,
        font: img.arial14,
      );

      // 4. Кодируем обратно
      final newBytes = img.encodePng(decoded);

      // 5. Перезаписываем файл
      await originalFile.writeAsBytes(newBytes);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Изображение перезаписано успешно')),
      );
    } catch (e) {
      debugPrint('Ошибка при сохранении: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при сохранении: $e')),
      );
    }
  }
}
