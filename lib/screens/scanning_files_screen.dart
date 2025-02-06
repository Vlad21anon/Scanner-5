import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:owl_tech_pdf_scaner/app/app_colors.dart';
import 'package:owl_tech_pdf_scaner/app/app_icons.dart';
import 'package:owl_tech_pdf_scaner/app/app_text_style.dart';
import 'package:owl_tech_pdf_scaner/models/scan_file.dart';
import 'package:owl_tech_pdf_scaner/screens/pdf_edit_screen.dart';
import 'package:owl_tech_pdf_scaner/services/navigation_service.dart';
import 'package:owl_tech_pdf_scaner/widgets/custom_circular_button.dart';
import 'package:owl_tech_pdf_scaner/widgets/file_card.dart';

import '../blocs/files_cubit.dart';

class ScanningFilesScreen extends StatelessWidget {
  /// Обязательный параметр – файл, страницы которого будут показаны на экране.
  final ScanFile file;

  const ScanningFilesScreen({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    final navigation = NavigationService();
    final filesCubit = context.watch<FilesCubit>();
    // Если в cubit хранится обновлённый файл, используем его вместо file
    final currentFile = (filesCubit.lastScanFile?.id == file.id)
        ? filesCubit.lastScanFile!
        : file;

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
              itemCount: currentFile.pages.length,
              separatorBuilder: (context, _) => SizedBox(height: 16.h),
              itemBuilder: (context, index) {
                final pagePath = currentFile.pages[index];
                return GestureDetector(
                  onTap: () {
                    // При нажатии переходим на экран редактирования PDF для всего файла,
                    // передаём актуальный объект currentFile
                    navigation.navigateTo(
                      context,
                      PdfEditScreen(file: currentFile, index: index),
                    );
                  },
                  child: FileCard(
                    file: currentFile,
                    index: index,
                    // Для предпросмотра используем конкретную страницу
                    imagePath: pagePath,
                    onTap: () {
                      navigation.navigateTo(
                        context,
                        PdfEditScreen(file: currentFile),
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
