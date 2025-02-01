import 'dart:ui';

import 'draw_point.dart';

/// Класс для хранения данных рукописной записи.
/// Добавлено поле [baseSize] – базовый размер области, в которой изначально рисовалась заметка.
class NoteData {
  /// Список точек (с разделителями null, обозначающими разрыв штриха)
  List<DrawPoint?> points;

  /// Начальная позиция заметки на изображении
  Offset offset;

  /// Цвет линии (используется для обычного рисования)
  Color color;

  /// Толщина линии
  double strokeWidth;

  /// Текущий размер заметки (ширина и высота)
  Size size;

  /// Базовый размер (размер области, где была зафиксирована рукопись)
  Size baseSize;

  NoteData({
    required this.points,
    required this.offset,
    required this.color,
    required this.strokeWidth,
    required this.size,
    required this.baseSize,
  });
}