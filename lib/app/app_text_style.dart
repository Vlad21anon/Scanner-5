import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyle {
  AppTextStyle._();

  static TextStyle nunito32 = TextStyle(
    fontFamily: 'Nunito',
    color: AppColors.black,
    fontSize: 32,
  );

  static TextStyle exo36 = TextStyle(
    fontFamily: 'Exo',
    color: AppColors.white,
    fontSize: 36,
    fontWeight: FontWeight.bold,
  );

  static TextStyle exo20 = TextStyle(
    fontFamily: 'Exo',
    color: AppColors.black,
    fontSize: 20,
  );

  static TextStyle exo16 = TextStyle(
    fontFamily: 'Exo',
    color: AppColors.greyText,
    fontSize: 16,
  );
}
