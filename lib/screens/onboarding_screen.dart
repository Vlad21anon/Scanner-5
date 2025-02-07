import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:owl_tech_pdf_scaner/app/app_colors.dart';
import 'package:owl_tech_pdf_scaner/app/app_icons.dart';
import 'package:owl_tech_pdf_scaner/app/app_text_style.dart';
import 'package:owl_tech_pdf_scaner/gen/assets.gen.dart';
import 'package:owl_tech_pdf_scaner/services/navigation_service.dart';
import 'package:owl_tech_pdf_scaner/services/revenuecat_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;

// Импортируем экран подписки и его перечисление
import '../main.dart';
import 'subscription_selection_screen.dart';

enum SelectedSubType { year, week }

/// Физика для замедленной прокрутки страниц
class SlowPageScrollPhysics extends ScrollPhysics {
  const SlowPageScrollPhysics({super.parent});

  @override
  SlowPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SlowPageScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    final slowedVelocity = velocity * 0.5;
    return super.createBallisticSimulation(position, slowedVelocity);
  }

  @override
  ScrollPhysics get parent =>
      super.parent ?? const AlwaysScrollableScrollPhysics();
}

/// Экран онбординга с возможностью задать стартовую страницу
class OnboardingScreen extends StatefulWidget {
  final int initialPage;

  const OnboardingScreen({super.key, this.initialPage = 0});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageController;
  late int _currentPage;
  final navigator = NavigationService();

  // Глобальное состояние выбранного типа подписки
  SelectedSubType selectedSub = SelectedSubType.year;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage);
  }

  // Функция оформления подписки
  Future<void> _purchaseSubscription() async {
    String packageIdentifier =
        selectedSub == SelectedSubType.year ? "year_package" : "week_package";

    await RevenueCatService().purchaseSubscription(packageIdentifier);

    bool subscribed = await RevenueCatService().isUserSubscribed();
    if (subscribed) {
      debugPrint("Подписка оформлена, обновляем UI");
      navigator.navigateTo(context, MainScreen(), replace: true);
    } else {
      debugPrint("Подписка не оформлена");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Подписка не оформлена, попробуйте еще раз.")),
      );
    }
  }

  /// Метод для восстановления покупок
  Future<void> _restorePurchases() async {
    await RevenueCatService()
        .restorePurchases(); // Если данный метод добавлен в сервис
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

  // Список страниц онбординга.
  // Четвёртым экраном является экран подписки, которому передаются selectedSub и callback.
  List<Widget> get _pages => [
        const OnboardingPage1(),
        const OnboardingPage2(),
        const OnboardingPage3(),
        SubscriptionSelectionScreen(
          selectedSub: selectedSub,
          onTapItem: (newType) {
            setState(() {
              selectedSub = newType;
            });
          },
        ),
      ];

  // Обработчик нажатия кнопки:
  void _onButtonPressed() {
    setState(() {
      if (_currentPage < _pages.length - 1) {
        _currentPage++; // переходим на следующую страницу
      } else {
        _purchaseSubscription(); // если последняя – оформляем подписку
      }
    });
  }

  /// Метод для открытия URL
  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Не удалось открыть $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Фоновое изображение: для подписки другое изображение
          _currentPage == _pages.length - 1
              ? SizedBox(
                  width: double.infinity,
                  child: Assets.images.subPayBack.image(fit: BoxFit.cover),
                )
              : SizedBox(
                  width: double.infinity,
                  child: Assets.images.onboardingBack.image(fit: BoxFit.fill),
                ),
          // PageView для экранов онбординга
          Positioned(
            left: 0,
            right: 0,
            child: SizedBox(
              height: 573.h,
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollUpdateNotification) {
                    if (_pageController.page != null &&
                        _pageController.page! < _currentPage) {
                      _pageController.jumpToPage(_currentPage);
                    }
                  }
                  return false;
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                    // Пример с эффектом слайда (новая страница заезжает справа)
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1.0, 0.0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    );
                  },
                  // Чтобы AnimatedSwitcher понимал, что контент меняется,
                  // каждому виджету страницы присваиваем уникальный ключ:
                  child: Container(
                    key: ValueKey<int>(_currentPage),
                    child: _pages[_currentPage],
                  ),
                ),
              ),
            ),
          ),
          // Индикатор страниц и кнопка Skip
          if (_currentPage != _pages.length - 1)
            Positioned(
              top: 70.h,
              left: 0,
              right: 0,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
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
                            borderRadius:
                                BorderRadius.all(Radius.circular(3.r)),
                          ),
                        );
                      }),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Пропускаем онбординг
                        navigator.navigateTo(context, MainScreen(),
                            replace: true);
                      },
                      child: Text(
                        'Skip',
                        style:
                            AppTextStyle.exo16.copyWith(color: AppColors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_currentPage == _pages.length - 1)
            Positioned(
              bottom: 130.h,
              child: Text(
                'No payment now',
                style: AppTextStyle.exo14.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (_currentPage == _pages.length - 1)
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
          // Единая нижняя кнопка
          Positioned(
            bottom: 65.h,
            left: 0,
            right: 0,
            child: GestureDetector(
              onTap: _onButtonPressed,
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
                      // Если последний экран – меняем текст кнопки
                      _currentPage == _pages.length - 1 &&
                              selectedSub == SelectedSubType.week
                          ? 'Try for Free'
                          : 'Continue',
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

/// Пример экрана онбординга 1
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
        ],
      ),
    );
  }
}

/// Пример экрана онбординга 2
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
          Assets.images.oImage2.image(fit: BoxFit.fill),
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
        ],
      ),
    );
  }
}

/// Пример экрана онбординга 3
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
            padding: const EdgeInsets.only(right: 60),
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
        ],
      ),
    );
  }
}
