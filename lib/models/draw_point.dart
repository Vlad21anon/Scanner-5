import 'dart:ui';

/// Класс для хранения одной точки рисования с информацией о режиме (рисование или стирание)
class DrawPoint {
  final Offset offset;
  final bool isEraser;

  DrawPoint(this.offset, this.isEraser);

  /// Преобразует объект DrawPoint в Map для сериализации.
  Map<String, dynamic> toMap() {
    return {
      'offset': {'dx': offset.dx, 'dy': offset.dy},
      'isEraser': isEraser,
    };
  }

  /// Создаёт объект DrawPoint из Map.
  factory DrawPoint.fromMap(Map<String, dynamic> map) {
    final offsetMap = map['offset'] as Map<String, dynamic>;
    return DrawPoint(
      Offset(offsetMap['dx'] as double, offsetMap['dy'] as double),
      map['isEraser'] as bool,
    );
  }
}
