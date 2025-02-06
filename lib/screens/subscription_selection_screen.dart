import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:owl_tech_pdf_scaner/main.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/app_colors.dart';
import '../app/app_icons.dart';
import '../app/app_text_style.dart';
import '../gen/assets.gen.dart';
import 'dart:math' as math;

import '../services/navigation_service.dart';
import '../services/revenuecat_service.dart';
import 'onboarding_screen.dart'; // Импортируем сервис RevenueCat

class SubscriptionSelectionScreen extends StatefulWidget {
  final SelectedSubType selectedSub;
  final Function(SelectedSubType selectedSub) onTapItem;
  const SubscriptionSelectionScreen({super.key, required this.onTapItem, required this.selectedSub});

  @override
  State<SubscriptionSelectionScreen> createState() =>
      _SubscriptionSelectionScreenState();
}

class _SubscriptionSelectionScreenState
    extends State<SubscriptionSelectionScreen> {

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          bottom: 30.h,
          left: 0,
          right: 0,
          child: Column(
            children: [
              _buildInfo(),
              SizedBox(height: 16.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: _buildSubItem(
                  titleFirst: '1 year ',
                  priceFirst: '\$59.99',
                  titleSecond: 'only ',
                  priceSecond: '\$4.99',
                  isSelected: widget.selectedSub == SelectedSubType.year,
                  titleSecondLast: ' per week',
                  onTap: () => widget.onTapItem(SelectedSubType.year),
                ),
              ),
              SizedBox(height: 16.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: _buildSubItem(
                  titleFirst: '3-day free',
                  priceFirst: ' trial!',
                  titleSecond: 'then ',
                  priceSecond: '\$7.99',
                  isSelected: widget.selectedSub == SelectedSubType.week,
                  titleSecondLast: ' per week',
                  onTap: () => widget.onTapItem(SelectedSubType.week),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubItem({
    required String titleFirst,
    required String priceFirst,
    required String titleSecond,
    required String titleSecondLast,
    required String priceSecond,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(18.r)),
          border: Border.all(
            color: isSelected
                ? AppColors.white
                : AppColors.white.withValues(alpha: 0.3),
            width: 2.w,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      titleFirst,
                      style: AppTextStyle.exo16.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                    Text(
                      priceFirst,
                      style: AppTextStyle.exo16.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Text(
                      titleSecond,
                      style: AppTextStyle.exo16.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                    Text(
                      priceSecond,
                      style: AppTextStyle.exo16.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                    Text(
                      titleSecondLast,
                      style: AppTextStyle.exo16.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (!isSelected) AppIcons.circleBorderlessWhite24x24,
            if (isSelected) AppIcons.circleWhite24x24,
          ],
        ),
      ),
    );
  }

  Widget _buildInfo() {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'The Smartest\nScanner',
            style: AppTextStyle.exo36,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          Padding(
            padding: EdgeInsets.only(left: 108.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SvgPicture.asset(Assets.icons.quad),
                    SizedBox(width: 16.w),
                    Row(
                      children: [
                        Text(
                          'Unlimited',
                          style: AppTextStyle.exo16.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                        ),
                        Text(
                          ' scans',
                          style: AppTextStyle.exo16.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SvgPicture.asset(Assets.icons.penBlue),
                    SizedBox(width: 16.w),
                    Row(
                      children: [
                        Text(
                          'Powerful',
                          style: AppTextStyle.exo16.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                        ),
                        Text(
                          ' editing tools',
                          style: AppTextStyle.exo16.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SvgPicture.asset(Assets.icons.stop),
                    SizedBox(width: 16.w),
                    Row(
                      children: [
                        Text(
                          'Ad-free',
                          style: AppTextStyle.exo16.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                        ),
                        Text(
                          ' experience',
                          style: AppTextStyle.exo16.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
