import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:owl_tech_pdf_scaner/app/app_colors.dart';
import 'package:owl_tech_pdf_scaner/app/app_icons.dart';
import 'package:owl_tech_pdf_scaner/screens/scan_screen.dart';

import '../app/app_shadows.dart';
import '../gen/assets.gen.dart';
import '../services/navigation_service.dart';

class CustomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomNavigationBar(
      {super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          height: 59.h,
          width: 203.w,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(100.r),
            boxShadow: [
              AppShadows.grey03b3r1o00,
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => onTap(0),
                  child: Container(
                      padding: EdgeInsets.all(16.w),
                      color: Colors.transparent,
                      child: SvgPicture.asset(
                        Assets.icons.files,
                        width: 19.w,
                        height: 22.w,
                        color: currentIndex == 0
                            ? AppColors.blue
                            : AppColors.greyIcon,
                      )),
                ),
                GestureDetector(
                  onTap: () => onTap(1),
                  child: Container(
                    padding: EdgeInsets.all(16.w),
                    color: Colors.transparent,
                    child: SvgPicture.asset(
                      Assets.icons.settings,
                      width: 22.w,
                      height: 20.w,
                      color: currentIndex == 1
                          ? AppColors.blue
                          : AppColors.greyIcon,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 12.h,
          child: GestureDetector(
            onTap: () {
              final navigator = NavigationService();

              navigator.navigateTo(context, ScanScreen());
            },
            child: Container(
              padding: EdgeInsets.all(21.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.blue,
              ),
              child: AppIcons.plusWhite22x22,
            ),
          ),
        ),
      ],
    );
  }
}
