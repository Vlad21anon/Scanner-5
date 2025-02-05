import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../app/app_icons.dart';
import '../app/app_shadows.dart';
import '../app/app_text_style.dart';
import '../models/scan_file.dart';
import 'file_popup.dart';

class FileCard extends StatelessWidget {
  final ScanFile file;

  /// Новый параметр для передачи конкретного пути к изображению (например, для мультистраничного файла)
  final String? imagePath;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool? isSelectedMode;

  const FileCard({
    super.key,
    required this.file,
    required this.onTap,
    this.onLongPress,
    this.isSelectedMode,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    // Если imagePath передан и не пустой, используем его, иначе берем file.path
    final displayImagePath = (imagePath != null && imagePath!.isNotEmpty)
        ? imagePath!
        : file.pages.first;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: SizedBox(
        width: double.infinity,
        height: 90.h,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 64.w,
              height: 87.h,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.r),
                      boxShadow: [
                        AppShadows.grey03b3r1o00,
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: Image.file(
                        File(displayImagePath),
                        fit: BoxFit.fill,
                        width: 64.w,
                        height: 87.h,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 5.h,
                    right: 5.w,
                    child: AppIcons.pdfIcon29x30,
                  ),
                ],
              ),
            ),
            SizedBox(width: 26.w),
            Expanded(
              child: Container(
                color: Colors.transparent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      file.name,
                      style: AppTextStyle.exo20,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      '${DateFormat('dd MMM yyyy').format(file.created)} ${file.size.toStringAsFixed(1)}MB',
                      style: AppTextStyle.exo16,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 26.w),
            GestureDetector(
              onTap: () {
                final RenderBox button =
                    context.findRenderObject() as RenderBox;
                final Offset position = button.localToGlobal(Offset.zero);

                showDialog(
                  context: context,
                  barrierColor: Colors.transparent,
                  builder: (context) => Stack(
                    children: [
                      Positioned(
                        right: position.dx,
                        top: position.dy + position.dx + 16.h,
                        child: Material(
                          color: Colors.transparent,
                          child: FilePopup(file: file),
                        ),
                      ),
                    ],
                  ),
                );
              },
              child: Container(
                height: 54.w,
                width: 54.w,
                color: Colors.transparent,
                child: Center(
                  child: FittedBox(
                    child: AppIcons.menu3x24,
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            if (isSelectedMode ?? false)
              file.isSelected
                  ? Container(
                      height: 40.h,
                      width: 40.w,
                      color: Colors.transparent,
                      child: Center(
                        child: FittedBox(
                          child: AppIcons.circleBlue24x24,
                        ),
                      ),
                    )
                  : Container(
                      width: 40.w,
                      height: 40.h,
                      color: Colors.transparent,
                      child: Center(
                        child: FittedBox(
                          child: AppIcons.circleBorderlessGreyIcon24x24,
                        ),
                      ),
                    ),
          ],
        ),
      ),
    );
  }
}
