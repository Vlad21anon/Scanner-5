import 'package:flutter/material.dart';

import '../app/app_colors.dart';
import '../app/app_shadows.dart';

class CustomCircularButton extends StatelessWidget {
  final Color? color;
  final Widget? child;
  final VoidCallback onTap;

  const CustomCircularButton(
      {super.key, this.color, this.child, required this.onTap});

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
            AppShadows.grey03b3r1o00,
          ],
        ),
        child: child,
      ),
    );
  }
}