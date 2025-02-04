import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:owl_tech_pdf_scaner/app/app_text_style.dart';
import 'package:owl_tech_pdf_scaner/gen/assets.gen.dart';
import 'package:owl_tech_pdf_scaner/models/scan_file.dart';
import 'package:owl_tech_pdf_scaner/screens/onboarding_screen.dart';
import 'package:owl_tech_pdf_scaner/screens/pdf_edit_screen.dart';
import 'package:owl_tech_pdf_scaner/services/navigation_service.dart';

import '../blocs/files_cubit/files_cubit.dart';
import '../blocs/filter_cubit.dart';
import '../widgets/custom_circular_button.dart';
import '../widgets/file_card.dart';
import '../widgets/filter_popup.dart';
import 'document_scanner_test.dart';

class FilesPage extends StatefulWidget {
  const FilesPage({super.key});

  @override
  State<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage> {
  bool isSelectedMode = false;
  final navigation = NavigationService();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FilterCubit, FilterState>(
      builder: (context, filterState) {
        return BlocBuilder<FilesCubit, List<ScanFile>>(
          builder: (context, files) {
            isSelectedMode =
                context.read<FilesCubit>().state.any((file) => file.isSelected);
            final sortedFiles = context.read<FilterCubit>().applyFilter(files);
            return Column(
              children: [
                const SizedBox(height: 60),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Files', style: AppTextStyle.nunito32),
                      Row(
                        children: [
                          if (isSelectedMode)
                            Row(
                              children: [
                                CustomCircularButton(
                                  onTap: () {
                                    files
                                        .where((file) => file.isSelected)
                                        .forEach((file) {
                                      context
                                          .read<FilesCubit>()
                                          .removeFile(file.id);
                                    });
                                  },
                                  child: Assets.images.delete
                                      .image(width: 24, height: 24),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                          CustomCircularButton(
                            onTap: () {
                              showDialog(
                                context: context,
                                barrierColor: Colors.transparent,
                                builder: (context) => Stack(
                                  children: [
                                    Positioned(
                                      right: 16,
                                      top: 137,
                                      child: Material(
                                        color: Colors.transparent,
                                        child: FilterPopup(),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Assets.images.filter
                                .image(width: 24, height: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: sortedFiles.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // ElevatedButton(
                                //   onPressed: () {
                                //     navigation.navigateTo(context, DocumentScannerTest());
                                //   },
                                //   child: Text('DocumentScannerTest'),
                                // ),
                                // ElevatedButton(
                                //   onPressed: () {
                                //     navigation.navigateTo(context, OnboardingScreen());
                                //   },
                                //   child: Text('OnboardingScreen'),
                                // ),
                                Assets.images.imagePhotoroom2
                                    .image(width: 261, height: 217),
                                const SizedBox(height: 8),
                                Text(
                                  "Oops, nothing here yet!\nTap \"+\" to add something new!",
                                  style: AppTextStyle.exo16,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemBuilder: (context, index) {
                              return FileCard(
                                file: sortedFiles[index],
                                onTap: () {
                                  if (isSelectedMode) {
                                    setState(() {
                                      context
                                          .read<FilesCubit>()
                                          .toggleSelection(
                                              sortedFiles[index].id);
                                      isSelectedMode = sortedFiles
                                          .any((file) => file.isSelected);
                                    });
                                  } else {
                                    navigation.navigateTo(
                                      context,
                                      PdfEditScreen(file: files[index]),
                                    );
                                  }
                                },
                                onLongPress: () {
                                  setState(() {
                                    context
                                        .read<FilesCubit>()
                                        .toggleSelection(sortedFiles[index].id);
                                    isSelectedMode = true;
                                  });
                                },
                                isSelectedMode: isSelectedMode,
                              );
                            },
                            itemCount: sortedFiles.length,
                            separatorBuilder:
                                (BuildContext context, int index) =>
                                    const SizedBox(height: 16),
                          ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
