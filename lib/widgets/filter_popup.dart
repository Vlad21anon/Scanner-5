import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../app/app_text_style.dart';
import '../blocs/filter_cubit.dart';
import '../gen/assets.gen.dart';
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
        height: 317,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.3),
              spreadRadius: 1,
              blurRadius: 3,
              offset: Offset(0, 0),
            )
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
                    style: AppTextStyle.exo20.copyWith(fontSize: 24),
                  ),
                  const Spacer(),
                  Assets.images.filter.image(width: 24, height: 12),
                ],
              ),
              const SizedBox(height: 16),
              Text("Name", style: AppTextStyle.exo20),
              const SizedBox(height: 12),
              CustomRadioList(
                title: "A to Z",
                value: "A to Z",
                groupValue: context.watch<FilterCubit>().state.nameFilter,
                onChanged: (value) => context.read<FilterCubit>().updateNameFilter(value!),
              ),
              const SizedBox(height: 8),
              CustomRadioList(
                title: "Z to A",
                value: "Z to A",
                groupValue: context.watch<FilterCubit>().state.nameFilter,
                onChanged: (value) => context.read<FilterCubit>().updateNameFilter(value!),
              ),
              const SizedBox(height: 16),
              Text("Date", style: AppTextStyle.exo20),
              const SizedBox(height: 12),
              CustomRadioList(
                title: "New files",
                value: "New files",
                groupValue: context.watch<FilterCubit>().state.dateFilter,
                onChanged: (value) => context.read<FilterCubit>().updateDateFilter(value!),
              ),
              const SizedBox(height: 8),
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



