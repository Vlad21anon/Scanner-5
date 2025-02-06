import 'package:flutter/material.dart';
import 'package:defer_pointer/defer_pointer.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum HandleType { corner, horizontal, vertical }

enum _ResizeHandlePosition {
  topLeft,
  topCenter,
  topRight,
  rightCenter,
  bottomRight,
  bottomCenter,
  bottomLeft,
  leftCenter,
}

class EditableMovableResizableText extends StatefulWidget {
  final Offset initialPosition;
  final String initialText;
  final ValueChanged<Offset> onPositionChanged;
  final ValueChanged<String> onTextChanged;
  final ValueChanged<bool> isEditMode;
  final Color textColor;
  final double fontSize;
  final GlobalKey textBoundaryKey;

  const EditableMovableResizableText({
    super.key,
    required this.initialPosition,
    required this.initialText,
    required this.onPositionChanged,
    required this.onTextChanged,
    required this.isEditMode,
    this.textColor = Colors.black,
    this.fontSize = 16.0, required this.textBoundaryKey,
  });

  @override
  State<EditableMovableResizableText> createState() =>
      EditableMovableResizableTextState();
}

class EditableMovableResizableTextState
    extends State<EditableMovableResizableText> {
  // Позиция текста – изначально берётся из родительского параметра,
  // но если ещё не инициализирована, то задаётся по центру доступной области (как в CropWidget).
  late Offset _position;
  late String _text;
  bool _isEditing = false;
  double _width = 200.w;
  double _height = 100.h;
  late double _fontSize;

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // Минимальные размеры контейнера
  static final double minWidth = 50.w;
  static final double minHeight = 30.h;

  // Константы для отрисовки ручек
  static final double cornerSize = 11.w;
  static final Size horizontalSize = Size(17.w, 6.h);
  static final Size verticalSize = Size(6.w, 17.h);
  static final double hitSize = 40.w;
  static final double hitOffset = hitSize / 2;

  final _deferredPointerLink = DeferredPointerHandlerLink();

  // Переменные для обработки жестов ресайза
  late Offset _resizeStartDrag;
  late double _initialWidth;
  late double _initialHeight;
  late double _initialFontSize;
  late Offset _initialPosition;

  bool _positionInitialized = false;

  // // Ключ для RepaintBoundary, оборачивающего только виджет Text
  // final GlobalKey _textBoundaryKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _position = widget.initialPosition;
    _text = widget.initialText;
    _fontSize = widget.fontSize;
    _controller.text = _text;

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditing) {
        setState(() {
          _text = _controller.text;
          _isEditing = false;
        });
        widget.onTextChanged(_text);
      }
    });
  }

  @override
  void didUpdateWidget(covariant EditableMovableResizableText oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Если значение fontSize изменилось (например, через slider), обновляем внутреннее состояние.
    if (widget.fontSize != oldWidget.fontSize) {
      setState(() {
        _fontSize = widget.fontSize;
      });
    }
  }

  /// Функция захвата изображения только текстового виджета
  Future<ui.Image> captureTextImage({double pixelRatio = 3.0}) async {
    RenderRepaintBoundary boundary = widget.textBoundaryKey.currentContext!
        .findRenderObject() as RenderRepaintBoundary;
    return await boundary.toImage(pixelRatio: pixelRatio);
  }

  @override
  Widget build(BuildContext context) {
    // Родитель (TextEditWidget) оборачивает этот виджет в Positioned.fill.
    // Здесь с помощью LayoutBuilder вычисляем доступное пространство и,
    // если позиция ещё не инициализирована, задаём её по центру.
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!_positionInitialized) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _position = Offset(
                (constraints.maxWidth - _width) / 2,
                (constraints.maxHeight - _height) / 2,
              );
              _positionInitialized = true;
            });
            widget.onPositionChanged(_position);
          });
        }
        return Stack(
          children: [
            Positioned(
              left: _position.dx,
              top: _position.dy,
              width: _width,
              height: _height,
              child: GestureDetector(
                // Перемещение всего контейнера
                onPanUpdate: (details) {
                  setState(() {
                    _position += details.delta;
                  });
                  widget.onPositionChanged(_position);
                },
                // По нажатию переходим в режим редактирования
                onTap: () {
                  setState(() {
                    _isEditing = true;
                    _focusNode.requestFocus();
                    widget.isEditMode(true);
                  });
                },
                child: DeferredPointerHandler(
                  link: _deferredPointerLink,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 1.w),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Основной контент: текст или TextField для редактирования
                        Positioned.fill(
                          child: Container(
                            //padding: EdgeInsets.all(6.r),
                            alignment: Alignment.center,
                            child: _isEditing
                                ? TextField(
                                    controller: _controller,
                                    focusNode: _focusNode,
                                    style: TextStyle(
                                      fontSize: _fontSize,
                                      color: widget.textColor,
                                    ),
                                    cursorColor: Colors.blue,
                                    decoration: const InputDecoration(
                                        border: InputBorder.none),
                                    onSubmitted: (newValue) {
                                      setState(() {
                                        _text = newValue;
                                        _isEditing = false;
                                      });
                                      widget.onTextChanged(_text);
                                    },
                                  )
                                : RepaintBoundary(
                                    key: widget.textBoundaryKey,
                                    child: Text(
                                      _text,
                                      style: TextStyle(
                                        fontSize: _fontSize,
                                        color: widget.textColor,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        // 8 ручек для изменения размера (аналог ResizableNote)
                        Positioned(
                          top: -hitOffset,
                          left: -hitOffset,
                          child: _buildHandle(
                              HandleType.corner, _ResizeHandlePosition.topLeft),
                        ),
                        Positioned(
                          top: -hitOffset,
                          left: _width / 2 - hitOffset,
                          child: _buildHandle(HandleType.horizontal,
                              _ResizeHandlePosition.topCenter),
                        ),
                        Positioned(
                          top: -hitOffset,
                          left: _width - hitOffset,
                          child: _buildHandle(HandleType.corner,
                              _ResizeHandlePosition.topRight),
                        ),
                        Positioned(
                          top: _height / 2 - hitOffset,
                          left: _width - hitOffset,
                          child: _buildHandle(HandleType.vertical,
                              _ResizeHandlePosition.rightCenter),
                        ),
                        Positioned(
                          top: _height - hitOffset,
                          left: _width - hitOffset,
                          child: _buildHandle(HandleType.corner,
                              _ResizeHandlePosition.bottomRight),
                        ),
                        Positioned(
                          top: _height - hitOffset,
                          left: _width / 2 - hitOffset,
                          child: _buildHandle(HandleType.horizontal,
                              _ResizeHandlePosition.bottomCenter),
                        ),
                        Positioned(
                          top: _height - hitOffset,
                          left: -hitOffset,
                          child: _buildHandle(HandleType.corner,
                              _ResizeHandlePosition.bottomLeft),
                        ),
                        Positioned(
                          top: _height / 2 - hitOffset,
                          left: -hitOffset,
                          child: _buildHandle(HandleType.vertical,
                              _ResizeHandlePosition.leftCenter),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Создаёт виджет-ручку с заданным типом и позицией.
  /// Внешняя область гарантирует минимальный размер hitSize x hitSize.
  Widget _buildHandle(HandleType type, _ResizeHandlePosition pos) {
    Size visualSize;
    BoxDecoration decoration;
    switch (type) {
      case HandleType.corner:
        visualSize = Size(cornerSize, cornerSize);
        decoration = BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.blue),
          shape: BoxShape.circle,
        );
        break;
      case HandleType.horizontal:
        visualSize = horizontalSize;
        decoration = BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.blue),
          borderRadius: BorderRadius.circular(11.r),
        );
        break;
      case HandleType.vertical:
        visualSize = verticalSize;
        decoration = BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.blue),
          borderRadius: BorderRadius.circular(11.r),
        );
        break;
    }
    final double hitW = math.max(visualSize.width, hitSize);
    final double hitH = math.max(visualSize.height, hitSize);

    return DeferPointer(
      link: _deferredPointerLink,
      paintOnTop: true,
      child: GestureDetector(
        onPanStart: (details) {
          _resizeStartDrag = details.globalPosition;
          _initialWidth = _width;
          _initialHeight = _height;
          _initialFontSize = _fontSize;
          _initialPosition = _position;
        },
        onPanUpdate: (details) {
          final dx = details.globalPosition.dx - _resizeStartDrag.dx;
          final dy = details.globalPosition.dy - _resizeStartDrag.dy;
          setState(() {
            double newWidth = _initialWidth;
            double newHeight = _initialHeight;
            Offset newPosition = _initialPosition;
            double scaleFactor = 1.0;
            switch (pos) {
              case _ResizeHandlePosition.topLeft:
                newWidth =
                    (_initialWidth - dx).clamp(minWidth, double.infinity);
                newHeight =
                    (_initialHeight - dy).clamp(minHeight, double.infinity);
                newPosition = _initialPosition + Offset(dx, dy);
                scaleFactor = ((newWidth / _initialWidth) +
                        (newHeight / _initialHeight)) /
                    2;
                break;
              case _ResizeHandlePosition.topCenter:
                newHeight =
                    (_initialHeight - dy).clamp(minHeight, double.infinity);
                newPosition = _initialPosition + Offset(0, dy);
                scaleFactor = newHeight / _initialHeight;
                break;
              case _ResizeHandlePosition.topRight:
                newWidth =
                    (_initialWidth + dx).clamp(minWidth, double.infinity);
                newHeight =
                    (_initialHeight - dy).clamp(minHeight, double.infinity);
                newPosition = _initialPosition + Offset(0, dy);
                scaleFactor = ((newWidth / _initialWidth) +
                        (newHeight / _initialHeight)) /
                    2;
                break;
              case _ResizeHandlePosition.rightCenter:
                newWidth =
                    (_initialWidth + dx).clamp(minWidth, double.infinity);
                scaleFactor = newWidth / _initialWidth;
                break;
              case _ResizeHandlePosition.bottomRight:
                newWidth =
                    (_initialWidth + dx).clamp(minWidth, double.infinity);
                newHeight =
                    (_initialHeight + dy).clamp(minHeight, double.infinity);
                scaleFactor = ((newWidth / _initialWidth) +
                        (newHeight / _initialHeight)) /
                    2;
                break;
              case _ResizeHandlePosition.bottomCenter:
                newHeight =
                    (_initialHeight + dy).clamp(minHeight, double.infinity);
                scaleFactor = newHeight / _initialHeight;
                break;
              case _ResizeHandlePosition.bottomLeft:
                newWidth =
                    (_initialWidth - dx).clamp(minWidth, double.infinity);
                newHeight =
                    (_initialHeight + dy).clamp(minHeight, double.infinity);
                newPosition = _initialPosition + Offset(dx, 0);
                scaleFactor = ((newWidth / _initialWidth) +
                        (newHeight / _initialHeight)) /
                    2;
                break;
              case _ResizeHandlePosition.leftCenter:
                newWidth =
                    (_initialWidth - dx).clamp(minWidth, double.infinity);
                newPosition = _initialPosition + Offset(dx, 0);
                scaleFactor = newWidth / _initialWidth;
                break;
            }
            _width = newWidth;
            _height = newHeight;
            _position = newPosition;
            _fontSize = _initialFontSize * scaleFactor;
          });
          widget.onPositionChanged(_position);
        },
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
