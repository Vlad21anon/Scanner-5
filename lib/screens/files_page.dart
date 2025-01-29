import 'package:flutter/material.dart';
import 'package:owl_tech_pdf_scaner/app/app_text_style.dart';
import 'package:owl_tech_pdf_scaner/gen/assets.gen.dart';
import 'package:owl_tech_pdf_scaner/models/scan_file.dart';

import '../widgets/custom_circular_button.dart';
import '../widgets/file_card.dart';
import '../widgets/filter_popup.dart';

class FilesPage extends StatefulWidget {
  const FilesPage({super.key});

  @override
  State<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage> {
  bool isSelectedMode = false;

  final List<ScanFile> files = [
    ScanFile(
      name: 'Scan 070225_card activdsfsdf',
      id: '',
      created: DateTime.now(),
      size: 1.2,
      path: '12212',
    ),
    ScanFile(
      name: 'Scan 070225_card activsdfsdfsdfsdf',
      id: '',
      created: DateTime.now(),
      size: 1.2,
      path: '12212',
    ),
    ScanFile(
      name: 'Scan 070225_card activsdfsdf',
      id: '',
      created: DateTime.now(),
      size: 1.2,
      path: '12212',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 60),
        SizedBox(height: 16),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
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
                            setState(() {
                              files.removeWhere((file) => file.isSelected);
                              isSelectedMode = files.any(
                                (file) => file.isSelected,
                              );
                            });
                          },
                          child:
                              Assets.images.delete.image(width: 24, height: 24),
                        ),
                        SizedBox(width: 8),
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
                    child: Assets.images.filter.image(width: 24, height: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: files.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Assets.images.imagePhotoroom.image(
                          width: 261,
                          height: 217,
                        ),
                        SizedBox(height: 8),
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
                        file: files[index],
                        onTap: () {
                          if (isSelectedMode) {
                            setState(() {
                              files[index] = files[index].copyWith(
                                  isSelected: !files[index].isSelected);
                              isSelectedMode =
                                  files.any((file) => file.isSelected);
                            });
                          } else {
                            // navigateToFile(files[index]);
                          }
                        },
                        onLongPress: () {
                          setState(() {
                            files[index] =
                                files[index].copyWith(isSelected: true);
                            isSelectedMode = true;
                          });
                        },
                        isSelectedMode: isSelectedMode,
                      );
                    },
                    itemCount: files.length,
                    separatorBuilder: (BuildContext context, int index) {
                      return SizedBox(height: 16);
                    },
                  ),
          ),
        ),
      ],
    );
  }
}