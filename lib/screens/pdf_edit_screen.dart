import 'package:flutter/material.dart';
import 'package:owl_tech_pdf_scaner/models/scan_file.dart';

import '../app/app_colors.dart';
import '../app/app_text_style.dart';
import '../gen/assets.gen.dart';
import '../services/navigation_service.dart';
import '../widgets/custom_circular_button.dart';

class PdfEditScreen extends StatelessWidget {
  final String imagePath;

  const PdfEditScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    final navigation = NavigationService();
    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: 60),
          SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
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
                SizedBox(width: 27),
                Text('Scanning files', style: AppTextStyle.nunito32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
