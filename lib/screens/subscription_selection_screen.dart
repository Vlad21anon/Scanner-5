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
import '../services/revenuecat_service.dart'; // Импортируем сервис RevenueCat

enum SelectedSubType { year, week }

class SubscriptionSelectionScreen extends StatefulWidget {
  const SubscriptionSelectionScreen({super.key});

  @override
  State<SubscriptionSelectionScreen> createState() =>
      _SubscriptionSelectionScreenState();
}

class _SubscriptionSelectionScreenState
    extends State<SubscriptionSelectionScreen> {
  SelectedSubType selectedSub = SelectedSubType.year;
  final navigator = NavigationService();

  /// Метод для открытия URL
  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Не удалось открыть $url');
    }
  }

  /// Метод для совершения покупки подписки с выбранным пакетом
  Future<void> _purchaseSubscription() async {
    // Здесь необходимо указать правильный идентификатор пакета, как настроено в RevenueCat.
    // Например, для годовой подписки используем "year_package", а для недельной "week_package".
    String packageIdentifier = selectedSub == SelectedSubType.year
        ? "year_package"  // Замените на реальный идентификатор пакета для годовой подписки
        : "week_package"; // Замените на реальный идентификатор пакета для недельной подписки

    await RevenueCatService().purchaseSubscription(packageIdentifier);

    // После покупки проверяем активна ли подписка
    bool subscribed = await RevenueCatService().isUserSubscribed();
    if (subscribed) {
      debugPrint("Подписка оформлена, обновляем UI");
      // Здесь можно выполнить дополнительные действия (например, обновить состояние приложения)
      // Например, перейти на основной экран приложения:
      navigator.navigateTo(context, MainScreen(), replace: true);
    } else {
      debugPrint("Подписка не оформлена");
      // Можно показать сообщение пользователю
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Подписка не оформлена, попробуйте еще раз.")),
      );
    }
  }

  /// Метод для восстановления покупок
  Future<void> _restorePurchases() async {
    await RevenueCatService().restorePurchases(); // Если данный метод добавлен в сервис
    bool subscribed = await RevenueCatService().isUserSubscribed();
    if (subscribed) {
      debugPrint("Подписка восстановлена, обновляем UI");
      navigator.navigateTo(context, MainScreen(), replace: true);
    } else {
      debugPrint("Подписка не восстановлена");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Не удалось восстановить подписку.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Фоновое изображение
          SizedBox(
            width: double.infinity,
            child: Assets.images.subPayBack.image(
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            bottom: 180.h,
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
                    isSelected: selectedSub == SelectedSubType.year,
                    titleSecondLast: ' per week',
                    onTap: () {
                      setState(() {
                        selectedSub = SelectedSubType.year;
                      });
                    },
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
                    isSelected: selectedSub == SelectedSubType.week,
                    titleSecondLast: ' per week',
                    onTap: () {
                      setState(() {
                        selectedSub = SelectedSubType.week;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 140.h,
            child: Text(
              'No payment now',
              style: AppTextStyle.exo14.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Positioned(
            bottom: 12.h,
            left: 16.w,
            right: 16.w,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () async {
                    await _restorePurchases();
                  },
                  child: Text(
                    'Restore',
                    style: AppTextStyle.exo16.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    // Переход на страницу условий использования
                    await _openUrl('https://pdf-scanner.lovable.app/terms');
                  },
                  child: Text(
                    'Terms',
                    style: AppTextStyle.exo16.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    // Переход на страницу политики конфиденциальности
                    await _openUrl('https://pdf-scanner.lovable.app/privacy');
                  },
                  child: Text(
                    'Privacy',
                    style: AppTextStyle.exo16.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      navigator.pop(context);
                    } else {
                      navigator.navigateTo(
                        context,
                        MainScreen(),
                        replace: true,
                      );
                    }
                  },
                  child: Text(
                    'Not now',
                    style: AppTextStyle.exo16.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 60.h,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: () async {
                await _purchaseSubscription();
              },
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 16.w),
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.all(Radius.circular(28.r)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(width: 44.w),
                    Text(
                      selectedSub == SelectedSubType.year
                          ? 'Continue'
                          : 'Try for Free',
                      style: AppTextStyle.exo20.copyWith(color: AppColors.blue),
                    ),
                    Container(
                      padding: EdgeInsets.all(15.r),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.blue,
                      ),
                      child: Transform.rotate(
                        angle: -math.pi,
                        child: AppIcons.arrowLeftWhite14x14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
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
