import 'package:flutter/material.dart';
import 'package:owl_tech_pdf_scaner/app/app_colors.dart';

import '../gen/assets.gen.dart';

class CustomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomNavigationBar(
      {super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          height: 59,
          width: 203,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.3),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => onTap(0),
                  child: SizedBox(
                    width: 54,
                    height: 54,
                    child: Assets.images.files.image(
                      width: 19,
                      height: 22,
                      color: currentIndex == 0
                          ? AppColors.blue
                          : AppColors.greyIcon,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => onTap(1),
                  child: SizedBox(
                    width: 54,
                    height: 54,
                    child: Assets.images.settings.image(
                      width: 22,
                      height: 20,
                      color: currentIndex == 1
                          ? AppColors.blue
                          : AppColors.greyIcon,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 12,
          child: GestureDetector(
            onTap: () {

            },
            child: Container(
              width: 64,
              height: 64,
              decoration:
              BoxDecoration(shape: BoxShape.circle, color: AppColors.blue),
              child: Assets.images.plus.image(
                width: 22,
                height: 22,
              ),
            ),
          )
        ),
      ],
    );
  }
}
