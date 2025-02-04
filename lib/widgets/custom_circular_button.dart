import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../app/app_colors.dart';
import '../app/app_shadows.dart';

class CustomCircularButton extends StatelessWidget {
  final Color? color;
  final Widget? child;
  final VoidCallback onTap;
  final bool withShadow;
  final bool withBorder;

  const CustomCircularButton({
    super.key,
    this.color,
    this.child,
    required this.onTap,
    this.withShadow = true,
    this.withBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 54.w,
        height: 54.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color ?? AppColors.white,
          boxShadow: [
            if (withShadow) AppShadows.grey03b3r1o00,
          ],
          border: withBorder
              ? Border.all(width: 2.w, color: AppColors.greyIcon)
              : null,
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.none, // не масштабировать дочерний элемент
            child: child,
          ),
        ),
      ),
    );
  }
}
