import 'package:flutter/material.dart';

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
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color ?? AppColors.white,
          boxShadow: [
            if (withShadow) AppShadows.grey03b3r1o00,
          ],
          border: withBorder
              ? Border.all(width: 2, color: AppColors.greyIcon)
              : null,
        ),
        child: child,
      ),
    );
  }
}
