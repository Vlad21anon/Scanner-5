import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app/app_colors.dart';
import '../app/app_text_style.dart';
import '../gen/assets.gen.dart';
import '../models/scan_file.dart';

class FileCard extends StatelessWidget {
  final ScanFile file;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool isSelectedMode;

  const FileCard({
    super.key,
    required this.file,
    required this.onTap,
    required this.onLongPress,
    required this.isSelectedMode,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 64,
            height: 87,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Assets.images.fileImage.image(fit: BoxFit.cover),
                ),
                Positioned(
                  top: 3,
                  right: 3,
                  child: Container(
                    width: 19,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: EdgeInsets.all(3),
                    child: Assets.images.pdfIcon.image(
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 26),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: AppTextStyle.exo20,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 12),
                Text(
                  '${DateFormat('dd MMM yyyy').format(file.created)} ${file.size.toStringAsFixed(1)}MB',
                  style: AppTextStyle.exo16,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 26),
          GestureDetector(
            onTap: () {},
            child: SizedBox(
              height: 54,
              width: 54,
              child: Assets.images.menu.image(width: 3, height: 24),
            ),
          ),
          SizedBox(width: 8),
          if (isSelectedMode)
            file.isSelected
                ? Assets.images.circleBlue.image(
                    width: 24,
                    height: 24,
                    fit: BoxFit.cover,
                  )
                : Assets.images.circleBorderless.image(
                    width: 24,
                    height: 24,
                    fit: BoxFit.cover,
                  ),
        ],
      ),
    );
  }
}
