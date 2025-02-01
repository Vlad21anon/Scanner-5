import 'package:flutter/material.dart';

import '../models/draw_point.dart';

/// Класс для группировки штрихов с сохранением информации о типе и порядке
class Stroke {
  final bool isEraser;
  final List<DrawPoint> points;
  bool erased; // флаг: был ли этот штрих стерт (если drawn)
  Stroke({required this.isEraser, required this.points, this.erased = false});
}

/// CustomPainter для отрисовки рукописных записей с поддержкой режима стирания.
/// При пересечении любого штриха в режиме рисования с штрихом-ластиком весь штрих не отрисовывается.
class HandwritingPainter extends CustomPainter {
  final List<DrawPoint?> points;
  final Color color;
  final double strokeWidth;
  final Size baseSize;

  HandwritingPainter({
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.baseSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Масштабирование относительно базового размера
    final double scaleX = size.width / baseSize.width;
    final double scaleY = size.height / baseSize.height;
    canvas.save();
    canvas.scale(scaleX, scaleY);

    // Группируем точки в штрихи, разделяя их по null.
    List<Stroke> strokes = [];
    List<DrawPoint> currentPoints = [];
    for (var point in points) {
      if (point == null) {
        if (currentPoints.isNotEmpty) {
          strokes.add(Stroke(
            isEraser: currentPoints.first.isEraser,
            points: List.from(currentPoints),
          ));
          currentPoints.clear();
        }
      } else {
        currentPoints.add(point);
      }
    }
    if (currentPoints.isNotEmpty) {
      strokes.add(Stroke(
        isEraser: currentPoints.first.isEraser,
        points: List.from(currentPoints),
      ));
    }

    // Функция для проверки пересечения двух отрезков.
    bool doLineSegmentsIntersect(Offset p, Offset p2, Offset q, Offset q2) {
      double orientation(Offset a, Offset b, Offset c) {
        return (b.dx - a.dx) * (c.dy - a.dy) - (b.dy - a.dy) * (c.dx - a.dx);
      }
      double o1 = orientation(p, p2, q);
      double o2 = orientation(p, p2, q2);
      double o3 = orientation(q, q2, p);
      double o4 = orientation(q, q2, p2);
      if (o1 * o2 < 0 && o3 * o4 < 0) return true;
      return false;
    }

    // Функция для проверки пересечения двух штрихов.
    bool strokesIntersect(List<DrawPoint> stroke1, List<DrawPoint> stroke2) {
      for (int i = 0; i < stroke1.length - 1; i++) {
        for (int j = 0; j < stroke2.length - 1; j++) {
          if (doLineSegmentsIntersect(
              stroke1[i].offset, stroke1[i + 1].offset,
              stroke2[j].offset, stroke2[j + 1].offset)) {
            return true;
          }
        }
      }
      return false;
    }

    // Для каждого штриха (который рисуется) проверяем, есть ли позже нарисованный штрих-ластик,
    // который пересекается с ним. Если да, то помечаем его как стёртый.
    for (int i = 0; i < strokes.length; i++) {
      Stroke stroke = strokes[i];
      // Если это штрих для рисования
      if (!stroke.isEraser) {
        // Проверяем штрихи, созданные после него
        for (int j = i + 1; j < strokes.length; j++) {
          Stroke laterStroke = strokes[j];
          if (laterStroke.isEraser &&
              strokesIntersect(stroke.points, laterStroke.points)) {
            stroke.erased = true;
            break;
          }
        }
      }
    }

    // Настраиваем Paint для обычного рисования.
    final Paint drawPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..blendMode = BlendMode.srcOver
      ..color = color;

    // Отрисовываем только те штрихи, которые относятся к рисованию и не помечены как стертые.
    for (Stroke stroke in strokes) {
      if (!stroke.isEraser && !stroke.erased) {
        for (int i = 0; i < stroke.points.length - 1; i++) {
          canvas.drawLine(
              stroke.points[i].offset, stroke.points[i + 1].offset, drawPaint);
        }
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant HandwritingPainter oldDelegate) {
    return true;
  }
}