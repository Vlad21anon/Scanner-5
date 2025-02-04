import 'package:flutter/material.dart';
import 'package:owl_tech_pdf_scaner/app/app_colors.dart';
import 'package:owl_tech_pdf_scaner/app/app_text_style.dart';
import 'package:owl_tech_pdf_scaner/gen/assets.gen.dart';
import 'package:owl_tech_pdf_scaner/main.dart';
import 'dart:math' as math;

import 'package:owl_tech_pdf_scaner/services/navigation_service.dart';

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
      navigator.navigateTo(context, MainScreen(), replace: true);
    }
  }

  void _onSkipPressed() {
    // Действия по нажатию на "Skip" (например, переход на главный экран приложения)
    navigator.navigateTo(context, MainScreen(), replace: true);
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
              height: 573,
              width: double.infinity,
              child: PageView(
                controller: _pageController,
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
            top: 70,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Анимированные индикаторы страниц
                  Row(
                    children: List.generate(_pages.length, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 4),
                        width: _currentPage == index ? 34 : 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(
                            alpha: _currentPage == index ? 1.0 : 0.4,
                          ),
                          borderRadius: const BorderRadius.all(Radius.circular(3)),
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
            bottom: 50,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: _onContinuePressed,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: const BorderRadius.all(Radius.circular(28)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 44),
                    Text(
                      'Continue',
                      style: AppTextStyle.exo20.copyWith(color: AppColors.blue),
                    ),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.blue,
                      ),
                      child: Transform.rotate(
                        angle: -math.pi,
                        child: Assets.images.arrowLeft.image(
                          width: 14,
                          height: 14,
                          color: AppColors.white,
                        ),
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
      height: 573,
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
              height: 300,
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
            bottom: 80,
            left: 50,
            child: Assets.images.starts.image(
              width: 44,
              height: 63,
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
                  Text('PDF Scanner', style: AppTextStyle.exo36),
                  const SizedBox(height: 12),
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
      height: 573,
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
              height: 300,
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
                  const SizedBox(height: 12),
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
      height: 573,
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
              height: 300,
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
            bottom: 80,
            left: 50,
            child: Assets.images.starts.image(
              width: 44,
              height: 63,
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
                  Text('Rate Us', style: AppTextStyle.exo36),
                  const SizedBox(height: 12),
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
