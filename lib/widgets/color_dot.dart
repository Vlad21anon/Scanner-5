import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../app/app_colors.dart';
import '../app/app_icons.dart';


/// Виджет для отображения цветной точки
class ColorDot extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showBorder;
  const ColorDot({
    super.key,
    required this.color,
    required this.isSelected,
    required this.onTap,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(right: 8.w),
        width: 30.w,
        height: 30.w,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: AppColors.black, width: 3.w)
              : (showBorder ? Border.all(color: AppColors.greyIcon, width: 2.w) : null),
        ),
      ),
    );
  }
}

/// Виджет для отображения кнопки-ластика
class EraserDot extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;
  const EraserDot({
    super.key,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30.w,
        height: 30.w,
        color: Colors.transparent,
        child: Center(
          child: FittedBox(child: AppIcons.eraser28x26),
        ),
      ),
    );
  }
}