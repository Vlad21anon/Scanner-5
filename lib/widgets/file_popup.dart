import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:owl_tech_pdf_scaner/app/app_icons.dart';
import 'package:owl_tech_pdf_scaner/models/scan_file.dart';
import 'package:owl_tech_pdf_scaner/screens/onboarding_screen.dart';
import 'package:owl_tech_pdf_scaner/services/navigation_service.dart';

import '../app/app_shadows.dart';
import '../app/app_text_style.dart';
import '../blocs/files_cubit.dart';
import '../screens/subscription_selection_screen.dart';
import '../services/file_share_service.dart';
import '../services/revenuecat_service.dart';

class FilePopup extends StatelessWidget {
  final ScanFile file;
  final int? index;

  const FilePopup({super.key, required this.file, this.index});


  Future<bool> _showSubscriptionDialog(BuildContext context) async {
    // Проверяем наличие активной подписки через RevenueCat
    bool hasSubscription = await RevenueCatService().isUserSubscribed();

    if (hasSubscription) {
      // Если подписка активна, разрешаем использовать режим Pen
      return true;
    } else {
      // Если подписки нет, переходим на экран подписки
      NavigationService().navigateTo(context, OnboardingScreen(initialPage: 3));
      return false;
    }
  }

  /// Функция для создания PDF-файла из аннотированного изображения и его шаринга
  Future<void> _sharePdfFile() async {
    try {
      await FileShareService.shareFileAsPdf(file, text: 'Ваш PDF файл');
    } catch (e) {
      debugPrint("Ошибка при создании или шаринге PDF: $e");
    }
  }

  /// Функция для создания PDF-файла из аннотированного изображения и его шаринга
  Future<void> _showSubscriptionDialogOrShare(BuildContext context) async {
    try {
      final state = await _showSubscriptionDialog(context);

      if(state) {
        _sharePdfFile();
      }
    } catch (e) {
      debugPrint("Ошибка при создании или шаринге PDF: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 158,
        height: 136,
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: [
            AppShadows.grey03b3r1o00,
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMenuItem(
                onTap: () {
                  Navigator.pop(context);
                  final filesCubit = context.read<FilesCubit>();
                  // Удаляем только страницу по указанному индексу, а не весь файл
                  if (index != null) {
                    filesCubit.removePage(file.id, index!);
                  } else {
                    context.read<FilesCubit>().removeFile(file.id);
                  }
                },
                title: 'Delete',
                icon: AppIcons.deleteBlack14x16,
              ),
               SizedBox(height: 16.h),
              _buildMenuItem(
                onTap: () {},
                title: 'Download',
                icon: AppIcons.download16x16,
              ),
               SizedBox(height: 16.h),
              _buildMenuItem(
                onTap: () => _showSubscriptionDialogOrShare(context),
                title: 'Share',
                icon: AppIcons.share14x16,
              ),
            ],
          ),
        ));
  }

  Widget _buildMenuItem({
    required VoidCallback onTap,
    required String title,
    required Widget icon,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTextStyle.exo16.copyWith(
              fontSize: 18.sp,
            ),
          ),
          icon,
        ],
      ),
    );
  }
}
