import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:owl_tech_pdf_scaner/app/app_colors.dart';
import 'package:owl_tech_pdf_scaner/app/app_icons.dart';
import 'package:owl_tech_pdf_scaner/app/app_text_style.dart';
import 'package:owl_tech_pdf_scaner/blocs/files_cubit.dart';
import 'package:owl_tech_pdf_scaner/models/scan_file.dart';
import 'package:owl_tech_pdf_scaner/screens/pdf_edit_screen.dart';
import 'package:owl_tech_pdf_scaner/screens/scanning_files_screen.dart';
import 'package:owl_tech_pdf_scaner/services/navigation_service.dart';
import 'package:uuid/uuid.dart';
import '../gen/assets.gen.dart';
import '../services/permission_service.dart';
import '../widgets/custom_circular_button.dart';
import '../widgets/document_scanner_widget.dart';
import '../widgets/photo_toggle.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  /// Режим мульти/одиночного фото
  bool isMultiPhoto = false;

  final navigation = NavigationService();

  final GlobalKey<DocumentScannerWidgetState> scannerKey =
      GlobalKey<DocumentScannerWidgetState>();

  @override
  void initState() {
    super.initState();
    // Запрашиваем разрешения на камеру и микрофон
    PermissionService().requestCameraAndMicrophonePermissions();
  }

  /// Обработка фотографии, снятой камерой
  Future<void> _takePhoto(BuildContext context) async {
    final croppedPath = await scannerKey.currentState?.cropImage();
    if (croppedPath != null && croppedPath.isNotEmpty) {
      final file = File(croppedPath);
      final bytes = file.lengthSync();
      final sizeInMb = bytes / (1024 * 1024);

      final filesCubit = context.read<FilesCubit>();

      if (isMultiPhoto) {
        // Если уже есть активный файл для сканирования, обновляем его,
        // иначе создаём новый файл и назначаем его как текущий
        if (filesCubit.lastScanFile != null) {
          final currentFile = filesCubit.lastScanFile!;
          final updatedFile = currentFile.addPage(croppedPath, sizeInMb);
          filesCubit.editFile(currentFile.id, updatedFile);
          filesCubit.lastScanFile = updatedFile;
        } else {
          // Создаем новый мультистраничный файл
          final uuid = const Uuid().v4();
          final formattedDate = DateFormat('ddMMyy').format(DateTime.now());
          final newFile = ScanFile(
            id: uuid,
            name: 'Scan $formattedDate',
            created: DateTime.now(),
            size: sizeInMb,
            pages: [croppedPath],
          );
          filesCubit.addFile(newFile);
          filesCubit.lastScanFile = newFile;
        }
      } else {
        // Одиночный режим – создаем файл с одной страницей
        final uuid = const Uuid().v4();
        final formattedDate = DateFormat('ddMMyy').format(DateTime.now());
        final newFile = ScanFile(
          id: uuid,
          name: 'Scan $formattedDate',
          created: DateTime.now(),
          size: sizeInMb,
          pages: [croppedPath],
        );
        filesCubit.addFile(newFile);

        // Останавливаем сканер и переходим к экрану редактирования
        scannerKey.currentState?.stopScanner();
        navigation.navigateTo(
          context,
          PdfEditScreen(file: newFile),
        );
      }
    }
  }

  /// Обработка выбора файла из галереи
  Future<void> _pickFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final filePath = result.files.single.path;
      if (filePath != null) {
        final file = File(filePath);
        final bytes = file.lengthSync();
        final sizeInMb = bytes / (1024 * 1024);
        final filesCubit = context.read<FilesCubit>();

        if (isMultiPhoto) {
          // Если уже есть активный файл для сканирования, обновляем его,
          // иначе создаём новый файл и назначаем его как текущий
          if (filesCubit.lastScanFile != null) {
            final currentFile = filesCubit.lastScanFile!;
            final updatedFile = currentFile.addPage(filePath, sizeInMb);
            filesCubit.editFile(currentFile.id, updatedFile);
            filesCubit.lastScanFile = updatedFile;
          } else {
            final uuid = const Uuid().v4();
            final formattedDate = DateFormat('ddMMyy').format(DateTime.now());
            final newFile = ScanFile(
              id: uuid,
              name: 'Scan $formattedDate',
              created: DateTime.now(),
              size: sizeInMb,
              pages: [filePath],
            );
            filesCubit.addFile(newFile);
            filesCubit.lastScanFile = newFile;
          }
        } else {
          // Одиночный режим – создаём файл и сразу переходим на экран редактирования
          final uuid = const Uuid().v4();
          final formattedDate = DateFormat('ddMMyy').format(DateTime.now());
          final newFile = ScanFile(
            id: uuid,
            name: 'Scan $formattedDate',
            created: DateTime.now(),
            size: sizeInMb,
            pages: [filePath],
          );
          filesCubit.addFile(newFile);
          scannerKey.currentState?.stopScanner();
          navigation.navigateTo(
            context,
            PdfEditScreen(file: newFile),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DocumentScannerWidget(key: scannerKey),
          ),

          // Нижняя панель с кнопками управления
          Positioned(
            bottom: 0,
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: 203.h,
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: AppColors.black.withValues(alpha: 0.5),
              ),
              child: Column(
                children: [
                  // Переключатель режима (одиночное / мульти)
                  PhotoToggle(
                    onToggle: (bool isMulti) {
                      isMultiPhoto = isMulti;
                    },
                  ),
                  SizedBox(height: 10.h),

                  // Виджет предпросмотра файла: показываем превью последнего изображения и количество файлов
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Если есть файлы – показываем превью последнего добавленного изображения
                      BlocBuilder<FilesCubit, List<ScanFile>>(
                        builder: (BuildContext context, files) {
                          final lastScanFile =
                              context.read<FilesCubit>().lastScanFile;
                          return lastScanFile != null &&
                                  lastScanFile.pages.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    navigation.navigateTo(
                                      context,
                                      ScanningFilesScreen(file: lastScanFile),
                                    );
                                  },
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(3.r)),
                                        child: Image.file(
                                          File(
                                            lastScanFile.pages.last,
                                          ),
                                          width: 60.w,
                                          height: 60.w,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: -13.h,
                                        right: -13.w,
                                        child: Container(
                                          width: 26.w,
                                          height: 26.w,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppColors.white,
                                          ),
                                          child: Center(
                                            child: Text(
                                              lastScanFile.pages.length
                                                  .toString(),
                                              style: AppTextStyle.nunito32
                                                  .copyWith(
                                                fontSize: 14.sp,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : SizedBox(width: 60.w);
                        },
                      ),

                      // Кнопка "сделать снимок"
                      GestureDetector(
                        onTap: () => _takePhoto(context),
                        child: Container(
                          padding: EdgeInsets.all(6.w),
                          color: Colors.transparent,
                          child: Assets.images.shutter.image(
                            width: 72.w,
                            height: 72.w,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      // Кнопка "добавить файл" (из галереи)
                      CustomCircularButton(
                        onTap: () => _pickFile(context),
                        child: AppIcons.addFiles19x22,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Кнопка "назад" вверху слева
          Positioned(
            top: 75.h,
            left: 16.w,
            child: CustomCircularButton(
              withShadow: false,
              color: AppColors.black.withValues(alpha: 0.6),
              onTap: () {
                context.read<FilesCubit>().lastScanFile = null;
                navigation.pop(context);
              },
              child: AppIcons.arrowLeftWhite14x14,
            ),
          ),
        ],
      ),
    );
  }
}
