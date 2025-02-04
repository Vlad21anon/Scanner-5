import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../app/app_text_style.dart';

class PhotoToggle extends StatefulWidget {
  final ValueChanged<bool> onToggle; // Колбэк для передачи состояния

  const PhotoToggle({super.key, required this.onToggle});

  @override
  State<PhotoToggle> createState() => _PhotoToggleState();
}

class _PhotoToggleState extends State<PhotoToggle> {
  bool isMultiPhoto = false;

  void toggleSelection() {
    setState(() {
      isMultiPhoto = !isMultiPhoto;
    });
    widget.onToggle(isMultiPhoto); // Вызываем колбэк с новым значением
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200, // Общая ширина контейнера
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Левая кнопка (невыбранный вариант)
          if (isMultiPhoto)
            Positioned(left: 0, child: _buildOption('PHOTO', false)),

          // Центральная кнопка (выбранный вариант)
          _buildOption(isMultiPhoto ? 'MULTI' : 'PHOTO', true),

          // Правая кнопка (невыбранный вариант)
          if (!isMultiPhoto)
            Positioned(right: 0, child: _buildOption('MULTI', false)),
        ],
      ),
    );
  }

  Widget _buildOption(String text, bool isSelected) {
    return GestureDetector(
      onTap: toggleSelection,
      child: SizedBox(
        width: 60,
        height: 30,
        child: Center(
          child: Text(
            text,
            style: AppTextStyle.exo16.copyWith(
              color: isSelected ? AppColors.white : AppColors.greyText,
            ),
          ),
        ),
      ),
    );
  }
}
