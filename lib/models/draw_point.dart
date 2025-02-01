import 'dart:ui';

/// Класс для хранения одной точки рисования с информацией о режиме (рисование или стирание)
class DrawPoint {
  final Offset offset;
  final bool isEraser;

  DrawPoint(this.offset, this.isEraser);
}