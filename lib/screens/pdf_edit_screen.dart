import 'package:flutter/material.dart';
import 'package:owl_tech_pdf_scaner/models/scan_file.dart';

import '../app/app_colors.dart';
import '../app/app_text_style.dart';
import '../gen/assets.gen.dart';
import '../services/navigation_service.dart';
import '../widgets/custom_circular_button.dart';
import '../widgets/toggle_menu.dart';

class PdfEditScreen extends StatefulWidget {
  final ScanFile file;

  const PdfEditScreen({super.key, required this.file});

  @override
  State<PdfEditScreen> createState() => _PdfEditScreenState();
}

class _PdfEditScreenState extends State<PdfEditScreen> {
  int _selectedIndex = 0;
  
  final List<Widget> _pages = [
    Column(
      children: [
        Text('crop')
      ],
    ),
    Column(children: [
      Text('text')
    ],),
    Column(children: [
      Text('pen')
    ],),
  ];
  
  @override
  Widget build(BuildContext context) {
    final navigation = NavigationService();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        alignment: Alignment.center,
        children: [
          Column(
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
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: _pages,
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 46,
            child: ToggleMenu(
              onIndexChanged: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
