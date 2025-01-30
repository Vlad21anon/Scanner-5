import 'package:flutter/material.dart';

class EditableMovableText extends StatefulWidget {
  final Offset initialPosition;
  final String initialText;
  final ValueChanged<Offset> onPositionChanged;
  final ValueChanged<String> onTextChanged;

  final Color textColor;
  final double fontSize;

  const EditableMovableText({
    Key? key,
    required this.initialPosition,
    required this.initialText,
    required this.onPositionChanged,
    required this.onTextChanged,
    this.textColor = Colors.black,
    this.fontSize = 16.0,
  }) : super(key: key);

  @override
  _EditableMovableTextState createState() => _EditableMovableTextState();
}

class _EditableMovableTextState extends State<EditableMovableText> {
  late Offset _textOffset;
  late String _text;
  bool _isEditing = false;

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _textOffset = widget.initialPosition;
    _text = widget.initialText;
    _controller.text = _text;

    // Когда фокус пропадает, завершаем редактирование и сохраняем текст
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
  Widget build(BuildContext context) {
    // Занимаем всё доступное пространство родителя
    return SizedBox.expand(
      child: Stack(
        children: [
          // Перетаскиваемый (и редактируемый) текст
          Positioned(
            left: _textOffset.dx,
            top: _textOffset.dy,
            child: GestureDetector(
              // Перетаскивание
              onPanUpdate: (details) {
                setState(() {
                  _textOffset += details.delta;
                });
                widget.onPositionChanged(_textOffset);
              },
              // Нажатие для входа в режим редактирования
              onTap: () {
                setState(() {
                  _isEditing = true;
                  _focusNode.requestFocus();
                });
              },
              child: _isEditing
                  ? Container(
                // Немного «фона» вокруг TextField, чтобы было видно рамку
                width: 200,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(width: 1, color: Colors.blue),
                ),
                // Прокрутка по горизонтали + «огромная» ширина
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    // Устанавливаем очень большую maxWidth, «почти бесконечность»
                    constraints: const BoxConstraints(
                      maxWidth: 1000,
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      // Если хотите многострочный ввод:
                      // maxLines: null, // можно раскомментировать
                      // expands: true,  // вместе с maxLines: null

                      style: TextStyle(
                        fontSize: widget.fontSize,
                        color: widget.textColor,
                      ),
                      cursorColor: Colors.blue,
                      decoration: const InputDecoration(
                        border: InputBorder.none, // убираем двойную рамку
                      ),
                      onSubmitted: (newValue) {
                        setState(() {
                          _text = newValue;
                          _isEditing = false;
                        });
                        widget.onTextChanged(_text);
                      },
                    ),
                  ),
                ),
              )
                  : Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(width: 1, color: Colors.blue),
                ),
                child: Text(
                  _text,
                  style: TextStyle(
                    fontSize: widget.fontSize,
                    color: widget.textColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
