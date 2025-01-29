import 'package:flutter/material.dart';
import 'package:owl_tech_pdf_scaner/app/app_colors.dart';
import 'package:owl_tech_pdf_scaner/app/app_text_style.dart';
import 'package:owl_tech_pdf_scaner/models/scan_file.dart';
import 'package:owl_tech_pdf_scaner/screens/scanning_files_screen.dart';
import 'package:owl_tech_pdf_scaner/services/navigation_service.dart';

import '../gen/assets.gen.dart';
import '../widgets/custom_circular_button.dart';
import '../widgets/photo_toggle.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool isMultiPhoto = false;
  final navigation = NavigationService();
  final List<ScanFile> files = [
    ScanFile(
      name: 'sdf0225_card activdsfsdf',
      id: '',
      created: DateTime.now(),
      size: 1.2,
      path: Assets.images.fileImage.path,
    ),
    ScanFile(
      name: '1230225_card activsdfsdfsdfsdf',
      id: '',
      created: DateTime.now(),
      size: 1.2,
      path: Assets.images.fileImage.path,
    ),
    ScanFile(
      name: 'asijhfdgihasdufctivsdfsdf',
      id: '',
      created: DateTime.now(),
      size: 1.2,
      path: Assets.images.fileImage.path,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            color: AppColors.white,
          ),
          Positioned(
            bottom: 0,
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: 203,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.black.withValues(alpha: 0.5),
              ),
              child: Column(
                children: [
                  PhotoToggle(
                    onToggle: (bool isMulti) {
                      isMultiPhoto = isMulti;
                    },
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (files.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            navigation.navigateTo(
                              context,
                              ScanningFilesScreen(files: files),
                            );
                          },
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              ClipRRect(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(3)),
                                child: Image.asset(
                                  files.last.path,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: -13,
                                right: -13,
                                child: Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.white,
                                  ),
                                  child: Center(
                                    child: Text(
                                      files.length.toString(),
                                      style: AppTextStyle.nunito32.copyWith(
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      GestureDetector(
                        onTap: () {},
                        child: Assets.images.shutter.image(
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        ),
                      ),
                      CustomCircularButton(
                        onTap: () {},
                        child: Assets.images.addFiles.image(
                          width: 19,
                          height: 22,
                          color: AppColors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 75,
            left: 16,
            child: CustomCircularButton(
              color: AppColors.black.withValues(alpha: 0.6),
              onTap: () {
                navigation.pop(context);
              },
              child: Assets.images.arrowLeft.image(width: 24, height: 24),
            ),
          ),
        ],
      ),
    );
  }
}
