import 'dart:math' as math;
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../app/app_colors.dart';

/// CustomPainter, который получает список 4 углов (в исходных координатах), размер кадра и параметры поворота.
/// Если платформа не iOS, то при rotateClockwise == true применяется формула:
///     newX = (cameraImageSize.height - y)
///     newY = x
/// Если платформа iOS – точки не меняются.
class PaperBorderPainter extends CustomPainter {
  final List<Offset> corners;
  final Size cameraImageSize;
  final bool rotateClockwise;
  final double offsetAdjustmentX;
  final double offsetAdjustmentY;

  // Размер угловой ручки (аналог cornerSize)
  static final double handleCornerSize = 11.w;

  PaperBorderPainter({
    required this.corners,
    required this.cameraImageSize,
    this.rotateClockwise = false,
    this.offsetAdjustmentX = 0,
    this.offsetAdjustmentY = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (corners.length != 4) return;

    // Для iOS не выполняем поворот – используем исходные точки,
    // для остальных платформ применяем преобразование в зависимости от rotateClockwise.
    List<Offset> transformedCorners;
    if (Platform.isIOS) {
      transformedCorners = corners;
    } else {
      transformedCorners = corners.map((pt) {
        if (rotateClockwise) {
          // Поворот по часовой стрелке: (x, y) -> (cameraImageSize.height - y, x)
          return Offset(cameraImageSize.height - pt.dy, pt.dx);
        } else {
          // Поворот против часовой стрелки: (x, y) -> (pt.dy, cameraImageSize.width - pt.dx)
          return Offset(pt.dy, cameraImageSize.width - pt.dx);
        }
      }).toList();
    }

    // Новый размер изображения после преобразования.
    final newImageSize = (!Platform.isIOS)
        ? (rotateClockwise
        ? Size(cameraImageSize.height, cameraImageSize.width)
        : Size(cameraImageSize.width, cameraImageSize.height))
        : cameraImageSize;

    // Вычисляем коэффициент масштабирования (сохраняя пропорции) и отступы для центрирования
    final scale = math.min(size.width / newImageSize.width, size.height / newImageSize.height);
    final drawWidth = newImageSize.width * scale;
    final drawHeight = newImageSize.height * scale;
    final offsetX = (size.width - drawWidth) / 2;
    final offsetY = (size.height - drawHeight) / 2;

    // Масштабируем и смещаем точки, добавляя корректирующие смещения
    final List<Offset> scaledCorners = transformedCorners.map((pt) {
      return Offset(
        pt.dx * scale + offsetX + offsetAdjustmentX,
        pt.dy * scale + offsetY + offsetAdjustmentY,
      );
    }).toList();

    // Рисуем рамку с тонкой синей линией
    final linePaint = Paint()
      ..color = AppColors.blueLight
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(scaledCorners[0].dx, scaledCorners[0].dy);
    for (int i = 1; i < scaledCorners.length; i++) {
      path.lineTo(scaledCorners[i].dx, scaledCorners[i].dy);
    }
    path.close();
    canvas.drawPath(path, linePaint);

    // Рисуем угловые ручки (белые кружки с синей обводкой)
    for (int i = 0; i < scaledCorners.length; i++) {
      final handleFillPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      final handleBorderPaint = Paint()
        ..color = AppColors.blueLight
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(scaledCorners[i], handleCornerSize / 2, handleFillPaint);
      canvas.drawCircle(scaledCorners[i], handleCornerSize / 2, handleBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant PaperBorderPainter oldDelegate) {
    return oldDelegate.corners != corners ||
        oldDelegate.cameraImageSize != cameraImageSize ||
        oldDelegate.rotateClockwise != rotateClockwise ||
        oldDelegate.offsetAdjustmentX != offsetAdjustmentX ||
        oldDelegate.offsetAdjustmentY != offsetAdjustmentY;
  }
}
