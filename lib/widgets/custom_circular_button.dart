import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../app/app_colors.dart';

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
    return Material(
      color: color ?? AppColors.white,
      shape: const CircleBorder(),
      elevation: withShadow ? 4.0 : 0.0,
      shadowColor: Colors.grey.withValues(alpha: 0.3),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 54.w,
          height: 54.w,
          decoration: withBorder
              ? BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(width: 2.w, color: AppColors.greyIcon),
          )
              : null,
          child: Center(
            child: FittedBox(
              fit: BoxFit.none, // не масштабировать дочерний элемент
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
