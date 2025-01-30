import 'package:flutter/material.dart';

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

  /// Переключаем «по кругу» при нажатии на Select.
  void _onSelectPressed() {
    setState(() {
      _selectedIndex = (_selectedIndex + 1) % 3;
    });
    widget.onIndexChanged?.call(_selectedIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 66,
          width: 289,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              AppShadows.grey03b3r1o00,
            ],
          ),
          padding: const EdgeInsets.all(6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSlot(
                index: 0,
                label: 'Crop',
                icon: Assets.images.size,
                iconWidth: 24,
                iconHeight: 20,
              ),
              _buildSlot(
                index: 1,
                label: 'Text',
                icon: Assets.images.text,
                iconWidth: 27,
                iconHeight: 20,
              ),
              _buildSlot(
                index: 2,
                label: 'Pen',
                icon: Assets.images.pen,
                iconWidth: 24,
                iconHeight: 22,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: _onSelectPressed,
          child: Container(
            height: 66,
            width: 66,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                AppShadows.grey03b3r1o00,
              ],
            ),
            child: Assets.images.select.image(width: 26, height: 18),
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
    required AssetGenImage icon,
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
          borderRadius: BorderRadius.circular(100),
        ),
        padding: isSelected
            ? const EdgeInsets.symmetric(horizontal: 22, vertical: 16)
            : EdgeInsets.zero,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              icon.image(
                width: iconWidth - 5,
                height: iconHeight - 5,
                color: isSelected ? AppColors.white : AppColors.greyIcon,
              ),
            if (!isSelected)
              SizedBox(
                width: 59,
                height: 52,
                child: icon.image(
                  width: iconWidth,
                  height: iconHeight,
                  color: isSelected ? AppColors.white : AppColors.greyIcon,
                ),
              ),
            if (isSelected) ...[
              const SizedBox(width: 3),
              Text(
                label,
                style: AppTextStyle.nunito32.copyWith(
                  fontSize: 16,
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
