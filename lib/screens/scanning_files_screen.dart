import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:owl_tech_pdf_scaner/app/app_colors.dart';
import 'package:owl_tech_pdf_scaner/app/app_text_style.dart';
import 'package:owl_tech_pdf_scaner/blocs/scan_files_cubit/scan_files_cubit.dart';
import 'package:owl_tech_pdf_scaner/gen/assets.gen.dart';
import 'package:owl_tech_pdf_scaner/models/scan_file.dart';
import 'package:owl_tech_pdf_scaner/screens/pdf_edit_screen.dart';
import 'package:owl_tech_pdf_scaner/services/navigation_service.dart';
import 'package:owl_tech_pdf_scaner/widgets/custom_circular_button.dart';
import 'package:owl_tech_pdf_scaner/widgets/file_card.dart';

class ScanningFilesScreen extends StatelessWidget {
  const ScanningFilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final navigation = NavigationService();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const SizedBox(height: 60),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Кнопка "Назад"
                CustomCircularButton(
                  onTap: () {
                    navigation.pop(context);
                  },
                  child: Assets.images.arrowLeft.image(
                    width: 22,
                    height: 18,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(width: 27),
                Text(
                  'Scanning files',
                  style: AppTextStyle.nunito32,
                ),
              ],
            ),
          ),

          // Основная часть, в которой отображаем список файлов из кубита
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: BlocBuilder<ScanFilesCubit, List<ScanFile>>(
                builder: (context, files) {
                  if (files.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Assets.images.imagePhotoroom
                              .image(width: 261, height: 217),
                          const SizedBox(height: 8),
                          Text(
                            "Oops, nothing here yet!\nTap \"+\" to add something new!",
                            style: AppTextStyle.exo16,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  // Иначе показываем список
                  return ListView.separated(
                    itemCount: files.length,
                    separatorBuilder: (context, _) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final file = files[index];
                      return FileCard(
                        file: file,
                        onTap: () {
                          navigation.navigateTo(
                            context,
                            PdfEditScreen(file: file),
                          );
                        },
                        onLongPress: () {
                          // Логика для долгого нажатия (например, меню удаления/редактирования)
                        },
                        isSelectedMode: false,
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
