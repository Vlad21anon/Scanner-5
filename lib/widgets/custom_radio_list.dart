import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:owl_tech_pdf_scaner/app/app_icons.dart';

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
          Container(
            padding: EdgeInsets.all(4.w),
            color: Colors.transparent,
            child: isSelected
                ? AppIcons.circleBorderBoldBlue24x24
                : AppIcons.circleBorderlessGreyIcon24x24,
          ),
        ],
      ),
    );
  }
}