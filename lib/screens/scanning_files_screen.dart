import 'package:flutter/material.dart';
import 'package:owl_tech_pdf_scaner/screens/pdf_edit_screen.dart';

import '../app/app_colors.dart';
import '../app/app_text_style.dart';
import '../gen/assets.gen.dart';
import '../models/scan_file.dart';
import '../services/navigation_service.dart';
import '../widgets/custom_circular_button.dart';
import '../widgets/file_card.dart';

class ScanningFilesScreen extends StatelessWidget {
  final List<ScanFile> files;

  const ScanningFilesScreen({super.key, required this.files});

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
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: ListView.separated(
                itemBuilder: (context, index) {
                  return FileCard(
                    file: files[index],
                    onTap: () {
                      navigation.navigateTo(
                        context,
                        PdfEditScreen(
                          imagePath: files[index].path,
                        ),
                      );
                    },
                    onLongPress: () {},
                    isSelectedMode: false,
                  );
                },
                itemCount: files.length,
                separatorBuilder: (BuildContext context, int index) {
                  return SizedBox(height: 16);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
