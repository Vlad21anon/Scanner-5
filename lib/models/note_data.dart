import 'dart:ui';
import 'draw_point.dart';

/// Класс для хранения данных рукописной записи.
/// Добавлено поле [id] для уникальной идентификации заметки.
class NoteData {
  /// Уникальный идентификатор заметки.
  final String id;

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
    String? id,
    required this.points,
    required this.offset,
    required this.color,
    required this.strokeWidth,
    required this.size,
    required this.baseSize,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  /// Преобразование объекта в Map для сохранения (например, в HydratedCubit)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'points': points.map((p) => p?.toMap()).toList(),
      'offset': {'dx': offset.dx, 'dy': offset.dy},
      'color': color.value,
      'strokeWidth': strokeWidth,
      'size': {'width': size.width, 'height': size.height},
      'baseSize': {'width': baseSize.width, 'height': baseSize.height},
    };
  }

  /// Создание объекта из Map
  factory NoteData.fromMap(Map<String, dynamic> map) {
    return NoteData(
      id: map['id'] as String,
      points: List<DrawPoint?>.from((map['points'] as List).map((e) {
        if (e == null) return null;
        return DrawPoint.fromMap(e as Map<String, dynamic>);
      })),
      offset: Offset(
        (map['offset'] as Map)['dx'] as double,
        (map['offset'] as Map)['dy'] as double,
      ),
      color: Color(map['color'] as int),
      strokeWidth: (map['strokeWidth'] as num).toDouble(),
      size: Size(
        (map['size'] as Map)['width'] as double,
        (map['size'] as Map)['height'] as double,
      ),
      baseSize: Size(
        (map['baseSize'] as Map)['width'] as double,
        (map['baseSize'] as Map)['height'] as double,
      ),
    );
  }

  /// Метод для создания изменённой копии заметки
  NoteData copyWith({
    String? id,
    List<DrawPoint?>? points,
    Offset? offset,
    Color? color,
    double? strokeWidth,
    Size? size,
    Size? baseSize,
  }) {
    return NoteData(
      id: id ?? this.id,
      points: points ?? this.points,
      offset: offset ?? this.offset,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      size: size ?? this.size,
      baseSize: baseSize ?? this.baseSize,
    );
  }
}
