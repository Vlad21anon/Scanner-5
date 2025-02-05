import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:owl_tech_pdf_scaner/app/app_colors.dart';
import 'package:owl_tech_pdf_scaner/app/app_icons.dart';
import 'package:owl_tech_pdf_scaner/app/app_text_style.dart';
import 'package:owl_tech_pdf_scaner/models/scan_file.dart';
import 'package:owl_tech_pdf_scaner/screens/pdf_edit_screen.dart';
import 'package:owl_tech_pdf_scaner/services/navigation_service.dart';
import 'package:owl_tech_pdf_scaner/widgets/custom_circular_button.dart';
import 'package:owl_tech_pdf_scaner/widgets/file_card.dart';

class ScanningFilesScreen extends StatelessWidget {
  /// Обязательный параметр – файл, страницы которого будут показаны на экране.
  final ScanFile file;

  const ScanningFilesScreen({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    final navigation = NavigationService();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SizedBox(height: 60.h),
          SizedBox(height: 16.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                // Кнопка "Назад"
                CustomCircularButton(
                  onTap: () {
                    navigation.pop(context);
                  },
                  child: AppIcons.arrowLeftBlack22x18,
                ),
                SizedBox(width: 27.w),
                Text(
                  'Scanning files',
                  style: AppTextStyle.nunito32,
                ),
              ],
            ),
          ),
          SizedBox(height: 26.h),
          // Список страниц выбранного файла
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: file.pages.length,
              separatorBuilder: (context, _) => SizedBox(height: 16.h),
              itemBuilder: (context, index) {
                final pagePath = file.pages[index];
                return GestureDetector(
                  onTap: () {
                    // При нажатии переходим на экран редактирования PDF для всего файла
                    navigation.navigateTo(
                      context,
                      PdfEditScreen(file: file, index: index),
                    );
                  },
                  child: FileCard(
                    file: file,
                    // Для предпросмотра используем конкретную страницу
                    imagePath: pagePath,
                    onTap: () {
                      navigation.navigateTo(
                        context,
                        PdfEditScreen(file: file),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }
}
