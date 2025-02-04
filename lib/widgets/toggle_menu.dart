import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:owl_tech_pdf_scaner/app/app_icons.dart';

import '../app/app_colors.dart';
import '../app/app_shadows.dart';
import '../app/app_text_style.dart';
import '../gen/assets.gen.dart';

class ToggleMenu extends StatefulWidget {
  final ValueChanged<int>? onIndexChanged;

  const ToggleMenu({
    super.key,
    this.onIndexChanged,
  });

  @override
  State<ToggleMenu> createState() => _ToggleMenuState();
}

class _ToggleMenuState extends State<ToggleMenu> {
  int _selectedIndex = 0;

  /// При нажатии на кнопку "Select" переключаем пункты.
  /// Если выбран последний элемент (Pen, индекс 2), переключение не происходит.
  void _onSelectPressed() {
    setState(() {
      if (_selectedIndex < 2) {
        _selectedIndex++;
        widget.onIndexChanged?.call(_selectedIndex);
      } else {
        // Если уже выбран Pen, можно повторно вызвать onIndexChanged
        // чтобы, например, инициировать проверку подписки.
        widget.onIndexChanged?.call(_selectedIndex);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 66.h,
          width: 289.w,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(100.r),
            boxShadow: [
              AppShadows.grey03b3r1o00,
            ],
          ),
          padding: EdgeInsets.all(6.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSlot(
                index: 0,
                label: 'Crop',
                icon: Assets.icons.size,
                iconWidth: 24.w,
                iconHeight: 20.h,
              ),
              _buildSlot(
                index: 1,
                label: 'Text',
                icon: Assets.icons.text,
                iconWidth: 27.w,
                iconHeight: 20.h,
              ),
              _buildSlot(
                index: 2,
                label: 'Pen',
                icon: Assets.icons.pen,
                iconWidth: 24.w,
                iconHeight: 22.h,
              ),
            ],
          ),
        ),
        SizedBox(width: 6.w),
        GestureDetector(
          onTap: _onSelectPressed,
          child: Container(
            height: 66.w,
            width: 66.w,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                AppShadows.grey03b3r1o00,
              ],
            ),
            child: Center(
              child: FittedBox(
                child: AppIcons.select26x18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Универсальный виджет для каждого «слота».
  /// При выборе (isSelected = true) элемент подсвечивается синим цветом,
  /// увеличивается и показывает текст.
  Widget _buildSlot({
    required int index,
    required String label,
    required String icon,
    required double iconWidth,
    required double iconHeight,
  }) {
    final bool isSelected = index == _selectedIndex;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        widget.onIndexChanged?.call(_selectedIndex);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(100.r),
        ),
        padding: isSelected
            ? EdgeInsets.symmetric(horizontal: 22.w, vertical: 16.h)
            : EdgeInsets.zero,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              SvgPicture.asset(
                icon,
                width: iconWidth - 5.w,
                height: iconHeight - 5.w,
                color: AppColors.white,
              ),
            if (!isSelected)
              SizedBox(
                width: 59,
                height: 52,
                child: SvgPicture.asset(
                  icon,
                  fit: BoxFit.none,
                  width: iconWidth,
                  height: iconHeight,
                  color: AppColors.greyIcon,
                ),
              ),
            if (isSelected) ...[
              SizedBox(width: 3.w),
              Text(
                label,
                style: AppTextStyle.nunito32.copyWith(
                  fontSize: 16.sp,
                  color: AppColors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
