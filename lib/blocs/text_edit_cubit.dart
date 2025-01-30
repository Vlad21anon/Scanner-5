import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

class TextEditState {
  final double fontSize;
  final Color color;
  final Offset textOffset; // Позиция текста на экране
  final String text;

  const TextEditState({
    required this.fontSize,
    required this.color,
    required this.textOffset,
    required this.text,
  });

  TextEditState copyWith({
    double? fontSize,
    Color? color,
    Offset? textOffset,
    String? text,
  }) {
    return TextEditState(
      fontSize: fontSize ?? this.fontSize,
      color: color ?? this.color,
      textOffset: textOffset ?? this.textOffset,
      text: text ?? this.text,
    );
  }
}

class TextEditCubit extends Cubit<TextEditState> {
  TextEditCubit()
      : super(const TextEditState(
    fontSize: 16.0,
    color: Colors.black,
    textOffset: Offset(100, 100),
    text: 'Ваш текст',
  ));

  void changeFontSize(double newSize) {
    emit(state.copyWith(fontSize: newSize));
  }

  void changeColor(Color newColor) {
    emit(state.copyWith(color: newColor));
  }

  void changeText(String newText) {
    emit(state.copyWith(text: newText));
  }

  void updateTextOffset(Offset newOffset) {
    emit(state.copyWith(textOffset: newOffset));
  }
}