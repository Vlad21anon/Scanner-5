import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:owl_tech_pdf_scaner/app/app_colors.dart';
import 'package:owl_tech_pdf_scaner/app/app_icons.dart';
import 'package:owl_tech_pdf_scaner/app/app_text_style.dart';
import 'package:owl_tech_pdf_scaner/gen/assets.gen.dart';
import 'package:owl_tech_pdf_scaner/screens/subscription_selection_screen.dart';
import 'dart:math' as math;

import 'package:owl_tech_pdf_scaner/services/navigation_service.dart';

/// Кастомная физика, разрешающая только прокрутку вперед.
class OnlyForwardScrollPhysics extends ScrollPhysics {
  const OnlyForwardScrollPhysics({ScrollPhysics? parent}) : super(parent: parent);

  @override
  OnlyForwardScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return OnlyForwardScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    // Если новое значение меньше текущей позиции, значит пользователь пытается листать назад.
    // Возвращаем разницу, чтобы запретить движение назад.
    if (value < position.pixels) {
      return position.pixels - value;
    }
    return 0.0;
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final navigator = NavigationService();

  // Список страниц онбординга (дизайн каждой страницы остаётся без изменений)
  final List<Widget> _pages = const [
    OnboardingPage1(),
    OnboardingPage2(),
    OnboardingPage3(),
  ];

  void _onContinuePressed() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Если это последняя страница, можно выполнить переход на главный экран приложения
      navigator.navigateTo(context, SubscriptionSelectionScreen(),
          replace: true);
    }
  }

  void _onSkipPressed() {
    // Действия по нажатию на "Skip" (например, переход на главный экран приложения)
    navigator.navigateTo(context, SubscriptionSelectionScreen(), replace: true);
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
            child: Assets.images.onboardingBack.image(
              fit: BoxFit.cover,
            ),
          ),
          // Основное содержимое: PageView с экранами онбординга
          Positioned(
            left: 0,
            right: 0,
            child: SizedBox(
              height: 573.h,
              width: double.infinity,
              child: PageView(
                controller: _pageController,
                // Используем кастомную физику, запрещающую прокрутку назад.
                physics: const OnlyForwardScrollPhysics(),
                onPageChanged: (int index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: _pages,
              ),
            ),
          ),
          // Индикатор страницы и кнопка Skip (дизайн сохраняется)
          Positioned(
            top: 70.h,
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Анимированные индикаторы страниц
                  Row(
                    children: List.generate(_pages.length, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: EdgeInsets.only(right: 4.w),
                        width: _currentPage == index ? 34.w : 4.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(
                            alpha: _currentPage == index ? 1.0 : 0.4,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(3.r)),
                        ),
                      );
                    }),
                  ),
                  GestureDetector(
                    onTap: _onSkipPressed,
                    child: Text(
                      'Skip',
                      style: AppTextStyle.exo16.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Кнопка Continue (без изменений дизайна)
          Positioned(
            bottom: 50.h,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: _onContinuePressed,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 16.r),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.all(Radius.circular(28.r)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(width: 44.w),
                    Text(
                      'Continue',
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
}

class OnboardingPage1 extends StatelessWidget {
  const OnboardingPage1({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 573.h,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Assets.images.oImage1.image(),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 300.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.blue.withValues(alpha: 0.0),
                    AppColors.blue,
                  ],
                  stops: const [0.1, 0.7],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 80.h,
            left: 50.w,
            child: AppIcons.startsWhite44x63,
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('PDF Scanner', style: AppTextStyle.exo36),
                  SizedBox(height: 12.h),
                  Text(
                    'Scan documents with your\nmobile phone',
                    style: AppTextStyle.exo20.copyWith(color: AppColors.white),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPage2 extends StatelessWidget {
  const OnboardingPage2({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 573.h,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: Assets.images.oImage2.image(fit: BoxFit.fill),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 300.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.blue.withValues(alpha: 0.0),
                    AppColors.blue,
                  ],
                  stops: const [0.1, 0.7],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Edit & Sign', style: AppTextStyle.exo36),
                  SizedBox(height: 12.h),
                  Text(
                    'Edit and sign documents\ninstantly',
                    style: AppTextStyle.exo20.copyWith(color: AppColors.white),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPage3 extends StatelessWidget {
  const OnboardingPage3({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 573.h,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(right: 60),
            child: Assets.images.oImage3.image(),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 300.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.blue.withValues(alpha: 0.0),
                    AppColors.blue,
                  ],
                  stops: const [0.1, 0.7],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 80.h,
            left: 50.w,
            child: AppIcons.startsWhite44x63,
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Rate Us', style: AppTextStyle.exo36),
                  SizedBox(height: 12.h),
                  Text(
                    'Your feedback helps us\nimprove',
                    style: AppTextStyle.exo20.copyWith(color: AppColors.white),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
