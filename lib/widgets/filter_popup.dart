import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:owl_tech_pdf_scaner/app/app_icons.dart';

import '../app/app_shadows.dart';
import '../app/app_text_style.dart';
import '../blocs/filter_cubit.dart';
import 'custom_radio_list.dart';


class FilterPopup extends StatefulWidget {
  const FilterPopup({super.key});

  @override
  State<FilterPopup> createState() => _FilterPopupState();
}

class _FilterPopupState extends State<FilterPopup> {
  String nameFilter = "A to Z";
  String dateFilter = "New files";

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 260,
        height: 320,
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: [
            AppShadows.grey03b3r1o00,
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    "Filter",
                    style: AppTextStyle.exo20.copyWith(fontSize: 24.sp),
                  ),
                  const Spacer(),
                  AppIcons.filterBlack24x12,
                ],
              ),
              SizedBox(height: 16.h),
              Text("Name", style: AppTextStyle.exo20),
              SizedBox(height: 12.h),
              CustomRadioList(
                title: "A to Z",
                value: "A to Z",
                groupValue: context.watch<FilterCubit>().state.nameFilter,
                onChanged: (value) => context.read<FilterCubit>().updateNameFilter(value!),
              ),
              SizedBox(height: 8.h),
              CustomRadioList(
                title: "Z to A",
                value: "Z to A",
                groupValue: context.watch<FilterCubit>().state.nameFilter,
                onChanged: (value) => context.read<FilterCubit>().updateNameFilter(value!),
              ),
              SizedBox(height: 16.h),
              Text("Date", style: AppTextStyle.exo20),
              SizedBox(height: 12.h),
              CustomRadioList(
                title: "New files",
                value: "New files",
                groupValue: context.watch<FilterCubit>().state.dateFilter,
                onChanged: (value) => context.read<FilterCubit>().updateDateFilter(value!),
              ),
              SizedBox(height: 8.h),
              CustomRadioList(
                title: "Old files",
                value: "Old files",
                groupValue: context.watch<FilterCubit>().state.dateFilter,
                onChanged: (value) => context.read<FilterCubit>().updateDateFilter(value!),
              ),
            ],
          ),
        )
    );
  }
}



