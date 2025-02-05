import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:owl_tech_pdf_scaner/app/app_icons.dart';
import 'package:owl_tech_pdf_scaner/blocs/scan_files_cubit.dart';
import 'package:owl_tech_pdf_scaner/models/scan_file.dart';

import '../app/app_shadows.dart';
import '../app/app_text_style.dart';
import '../blocs/files_cubit/files_cubit.dart';
import '../services/file_share_service.dart';

class FilePopup extends StatelessWidget {
  final ScanFile file;

  const FilePopup({super.key, required this.file});

  /// Функция для создания PDF-файла из аннотированного изображения и его шаринга
  Future<void> _sharePdfFile() async {
    try {
      await FileShareService.shareImageAsPdf(file.path, text: 'Ваш PDF файл');

    } catch (e) {
      debugPrint("Ошибка при создании или шаринге PDF: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 158.w,
        height: 136.h,
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
                  context.read<ScanFilesCubit>().removeFile(file.id);
                  context.read<FilesCubit>().removeFile(file.id);
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
                onTap: _sharePdfFile,
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
