import 'package:flutter/material.dart';
import 'package:defer_pointer/defer_pointer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math' as math;

import '../app/app_colors.dart';
import '../models/note_data.dart';
import 'handwriting_painter.dart';

enum HandleType { corner, horizontal, vertical }

class ResizableNote extends StatefulWidget {
  final NoteData note;
  final VoidCallback onUpdate;

  const ResizableNote({
    super.key,
    required this.note,
    required this.onUpdate,
  });

  @override
  State<ResizableNote> createState() => _ResizableNoteState();
}

class _ResizableNoteState extends State<ResizableNote> {
  // Минимальные размеры заметки
  static final double minWidth = 50.w;
  static final double minHeight = 50.h;

  // Визуальный размер ручек (не hit area)
  static final double cornerSize = 11.w;
  static final Size horizontalSize = Size(17.w, 6.h);
  static final Size verticalSize = Size(6.w, 17.h);

  // Минимальный размер области нажатия (hit area)
  static final double hitSize = 40.w;

  // Для позиционирования используем половину hitSize (15)
  static final double hitOffset = hitSize / 2;

  final _deferredPointerLink = DeferredPointerHandlerLink();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.note.offset.dx,
      top: widget.note.offset.dy,
      child: GestureDetector(
        // Перемещение всей заметки (если нажата не ручка)
        onPanUpdate: (details) {
          setState(() {
            widget.note.offset += details.delta;
          });
          widget.onUpdate();
        },
        child: DeferredPointerHandler(
          link: _deferredPointerLink,
          child: Container(
            width: widget.note.size.width,
            height: widget.note.size.height,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.blueLight, width: 1.w),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Отрисовка заметки (например, через CustomPaint)
                CustomPaint(
                  painter: HandwritingPainter(
                    points: widget.note.points,
                    color: widget.note.color,
                    strokeWidth: widget.note.strokeWidth,
                    baseSize: widget.note.baseSize,
                  ),
                  size: widget.note.size,
                ),
                // Ручки изменения размеров
                // Верхний левый угол
                Positioned(
                  top: -hitOffset,
                  left: -hitOffset,
                  child: _buildHandle(HandleType.corner, (details) {
                    setState(() {
                      final delta = details.delta;
                      final newWidth = widget.note.size.width - delta.dx;
                      final newHeight = widget.note.size.height - delta.dy;
                      if (newWidth >= minWidth && newHeight >= minHeight) {
                        widget.note.offset += Offset(delta.dx, delta.dy);
                        widget.note.size = Size(newWidth, newHeight);
                      }
                    });
                    widget.onUpdate();
                  }),
                ),
                // Верхний центр
                Positioned(
                  top: -hitOffset,
                  left: widget.note.size.width / 2 - hitOffset,
                  child: _buildHandle(HandleType.horizontal, (details) {
                    setState(() {
                      final delta = details.delta;
                      final newHeight = widget.note.size.height - delta.dy;
                      if (newHeight >= minHeight) {
                        widget.note.offset += Offset(0, delta.dy);
                        widget.note.size =
                            Size(widget.note.size.width, newHeight);
                      }
                    });
                    widget.onUpdate();
                  }),
                ),
                // Верхний правый угол
                Positioned(
                  top: -hitOffset,
                  left: widget.note.size.width - hitOffset,
                  child: _buildHandle(HandleType.corner, (details) {
                    setState(() {
                      final delta = details.delta;
                      final newWidth = widget.note.size.width + delta.dx;
                      final newHeight = widget.note.size.height - delta.dy;
                      if (newWidth >= minWidth && newHeight >= minHeight) {
                        widget.note.offset += Offset(0, delta.dy);
                        widget.note.size = Size(newWidth, newHeight);
                      }
                    });
                    widget.onUpdate();
                  }),
                ),
                // Средний правый (вертикальная)
                Positioned(
                  top: widget.note.size.height / 2 - hitOffset,
                  left: widget.note.size.width - hitOffset,
                  child: _buildHandle(HandleType.vertical, (details) {
                    setState(() {
                      final delta = details.delta;
                      final newWidth = widget.note.size.width + delta.dx;
                      if (newWidth >= minWidth) {
                        widget.note.size =
                            Size(newWidth, widget.note.size.height);
                      }
                    });
                    widget.onUpdate();
                  }),
                ),
                // Нижний правый угол
                Positioned(
                  top: widget.note.size.height - hitOffset,
                  left: widget.note.size.width - hitOffset,
                  child: _buildHandle(HandleType.corner, (details) {
                    setState(() {
                      final delta = details.delta;
                      final newWidth = widget.note.size.width + delta.dx;
                      final newHeight = widget.note.size.height + delta.dy;
                      if (newWidth >= minWidth && newHeight >= minHeight) {
                        widget.note.size = Size(newWidth, newHeight);
                      }
                    });
                    widget.onUpdate();
                  }),
                ),
                // Нижний центр
                Positioned(
                  top: widget.note.size.height - hitOffset,
                  left: widget.note.size.width / 2 - hitOffset,
                  child: _buildHandle(HandleType.horizontal, (details) {
                    setState(() {
                      final delta = details.delta;
                      final newHeight = widget.note.size.height + delta.dy;
                      if (newHeight >= minHeight) {
                        widget.note.size =
                            Size(widget.note.size.width, newHeight);
                      }
                    });
                    widget.onUpdate();
                  }),
                ),
                // Нижний левый угол
                Positioned(
                  top: widget.note.size.height - hitOffset,
                  left: -hitOffset,
                  child: _buildHandle(HandleType.corner, (details) {
                    setState(() {
                      final delta = details.delta;
                      final newWidth = widget.note.size.width - delta.dx;
                      final newHeight = widget.note.size.height + delta.dy;
                      if (newWidth >= minWidth && newHeight >= minHeight) {
                        widget.note.offset += Offset(delta.dx, 0);
                        widget.note.size = Size(newWidth, newHeight);
                      }
                    });
                    widget.onUpdate();
                  }),
                ),
                // Средний левый (вертикальная)
                Positioned(
                  top: widget.note.size.height / 2 - hitOffset,
                  left: -hitOffset,
                  child: _buildHandle(HandleType.vertical, (details) {
                    setState(() {
                      final delta = details.delta;
                      final newWidth = widget.note.size.width - delta.dx;
                      if (newWidth >= minWidth) {
                        widget.note.offset += Offset(delta.dx, 0);
                        widget.note.size =
                            Size(newWidth, widget.note.size.height);
                      }
                    });
                    widget.onUpdate();
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Функция для создания виджета-ручки с заданным типом.
  /// Внешний контейнер гарантирует, что область нажатия будет не меньше hitSize x hitSize.
  Widget _buildHandle(HandleType type, Function(DragUpdateDetails) onDrag) {
    Size visualSize;
    BoxDecoration decoration;
    switch (type) {
      case HandleType.corner:
        visualSize = Size(cornerSize, cornerSize);
        decoration = BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.blueLight),
          shape: BoxShape.circle,
        );
        break;
      case HandleType.horizontal:
        visualSize = horizontalSize;
        decoration = BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.blueLight),
          borderRadius: BorderRadius.circular(11.r),
        );
        break;
      case HandleType.vertical:
        visualSize = verticalSize;
        decoration = BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.blueLight),
          borderRadius: BorderRadius.circular(11.r),
        );
        break;
    }
    // Hit area всегда не меньше hitSize x hitSize
    final double hitW = math.max(visualSize.width, hitSize);
    final double hitH = math.max(visualSize.height, hitSize);

    return DeferPointer(
      link: _deferredPointerLink,
      paintOnTop: true,
      child: GestureDetector(
        onPanUpdate: onDrag,
        child: Container(
          width: hitW,
          height: hitH,
          alignment: Alignment.center,
          color: Colors.transparent,
          child: Container(
            width: visualSize.width,
            height: visualSize.height,
            decoration: decoration,
          ),
        ),
      ),
    );
  }
}