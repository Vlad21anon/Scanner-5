import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:owl_tech_pdf_scaner/app/app_colors.dart';
import 'package:owl_tech_pdf_scaner/models/scan_file.dart';

import '../app/app_text_style.dart';
import '../blocs/files_cubit/files_cubit.dart';
import '../gen/assets.gen.dart';

class FilePopup extends StatelessWidget {
  final ScanFile file;

  const FilePopup({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 158,
        height: 129,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.3),
              spreadRadius: 1,
              blurRadius: 3,
              offset: Offset(0, 0),
            )
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
                  context.read<FilesCubit>().removeFile(file.id);
                },
                title: 'Delete',
                icon: Assets.images.delete.image(
                  width: 14,
                  height: 16,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 16),
              _buildMenuItem(
                onTap: () {},
                title: 'Download',
                icon: Assets.images.download.image(
                  width: 16,
                  height: 16,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 16),
              _buildMenuItem(
                onTap: () {},
                title: 'Share',
                icon: Assets.images.share.image(
                  width: 14,
                  height: 16,
                  color: AppColors.black,
                ),
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
              fontSize: 18,
            ),
          ),
          icon,
        ],
      ),
    );
  }
}
