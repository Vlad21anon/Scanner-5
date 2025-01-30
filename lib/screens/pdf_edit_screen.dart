import 'package:flutter/material.dart';
import 'package:owl_tech_pdf_scaner/models/scan_file.dart';

import '../app/app_colors.dart';
import '../app/app_text_style.dart';
import '../gen/assets.gen.dart';
import '../services/navigation_service.dart';
import '../widgets/custom_circular_button.dart';

class PdfEditScreen extends StatelessWidget {
  final ScanFile file;

  const PdfEditScreen({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    final navigation = NavigationService();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SizedBox(height: 60),
          SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                Text('Crop', style: AppTextStyle.nunito32),
                CustomCircularButton(
                  onTap: () {
                    navigation.pop(context);
                  },
                  child: Assets.images.share.image(
                    width: 19,
                    height: 22,
                    color: AppColors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
