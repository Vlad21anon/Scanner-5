import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app_colors.dart';

class AppTextStyle {
  AppTextStyle._();

  static TextStyle nunito32 = TextStyle(
    fontFamily: 'Nunito',
    color: AppColors.black,
    fontSize: 32.sp,
  );

  static TextStyle exo36 = TextStyle(
    fontFamily: 'Exo',
    color: AppColors.white,
    fontSize: 36.sp,
    fontWeight: FontWeight.bold,
  );

  static TextStyle exo20 = TextStyle(
    fontFamily: 'Exo',
    color: AppColors.black,
    fontSize: 20.sp,
  );

  static TextStyle exo16 = TextStyle(
    fontFamily: 'Exo',
    color: AppColors.greyText,
    fontSize: 16.sp,
  );

  static TextStyle exo14 = TextStyle(
    fontFamily: 'Exo',
    color: AppColors.white,
    fontSize: 14.sp,
  );
}
