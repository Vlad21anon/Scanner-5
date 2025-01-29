import 'package:flutter/material.dart';

import '../app/app_text_style.dart';
import '../gen/assets.gen.dart';

class CustomRadioList extends StatelessWidget {
  const CustomRadioList({
    super.key,
    required this.title,
    required this.value,
    required this.groupValue,
    this.onChanged,
  });

  final String title;
  final String value;
  final String? groupValue;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onChanged != null ? () => onChanged!(value) : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyle.exo16),
          SizedBox(
            width: 32,
            height: 32,
            child: isSelected
                ? Assets.images.circleBorderBold.image(width: 24, height: 24)
                : Assets.images.circleBorderless.image(width: 24, height: 24),
          ),
        ],
      ),
    );
  }
}