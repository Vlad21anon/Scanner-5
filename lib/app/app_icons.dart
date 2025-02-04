import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:owl_tech_pdf_scaner/app/app_colors.dart';
import 'package:owl_tech_pdf_scaner/gen/assets.gen.dart';

class AppIcons {
  AppIcons._();

  static Widget circleBorderlessWhite24x24 = SvgPicture.asset(
    Assets.icons.circleBorderless,
    color: AppColors.white,
    width: 24.w,
    height: 24.w,
  );

  static Widget circleWhite24x24 = SvgPicture.asset(
    Assets.icons.circleWhite,
    width: 24.w,
    height: 24.w,
  );

  static Widget arrowLeftWhite14x14 = SvgPicture.asset(
    Assets.icons.arrowLeft,
    width: 14.w,
    height: 14.w,
    color: AppColors.white,
  );

  static Widget startsWhite44x63 = SvgPicture.asset(
    Assets.icons.starts,
    width: 44.w,
    height: 63.w,
    color: AppColors.white,
  );

  static Widget plusWhite22x22 = SvgPicture.asset(
    Assets.icons.plus,
    width: 22.w,
    height: 22.w,
    color: AppColors.white,
  );
}
