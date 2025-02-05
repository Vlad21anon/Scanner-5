import 'dart:io';
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:owl_tech_pdf_scaner/app/app_colors.dart';
import 'package:owl_tech_pdf_scaner/app/app_icons.dart';
import 'package:owl_tech_pdf_scaner/app/app_text_style.dart';
import 'package:owl_tech_pdf_scaner/blocs/files_cubit/files_cubit.dart';
import 'package:owl_tech_pdf_scaner/blocs/scan_files_cubit.dart';
import 'package:owl_tech_pdf_scaner/models/scan_file.dart';
import 'package:owl_tech_pdf_scaner/screens/pdf_edit_screen.dart';
import 'package:owl_tech_pdf_scaner/screens/scanning_files_screen.dart';
import 'package:owl_tech_pdf_scaner/services/navigation_service.dart';
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
  /// Отвечает за использование режима мульти/одиночного фото
  bool isMultiPhoto = false;

  /// Контроллер для камеры
  late CameraController _cameraController;
  Future<void>? _initializeControllerFuture;

  final navigation = NavigationService();

  final GlobalKey<DocumentScannerWidgetState> scannerKey =
      GlobalKey<DocumentScannerWidgetState>();

  @override
  void initState() {
    super.initState();
    // Запрашиваем разрешения на камеру и микрофон при запуске экрана
    PermissionService().requestCameraAndMicrophonePermissions();
    _initCamera();
  }

  /// Метод для инициализации камеры
  Future<void> _initCamera() async {
    // Получаем список доступных камер
    final cameras = await availableCameras();

    // Для простоты берём первую доступную (обычно задняя камера)
    final firstCamera = cameras.first;

    // Создаём контроллер
    _cameraController = CameraController(
      firstCamera,
      ResolutionPreset.medium,
      enableAudio: false, // выключим аудио
    );

    // Инициализируем контроллер
    _initializeControllerFuture = _cameraController.initialize();
    setState(() {});
  }

  @override
  void dispose() {
    // Освобождаем ресурсы
    _cameraController.dispose();
    super.dispose();
  }

  /// Метод для ото
  Future<void> _takePhoto(BuildContext context) async {
    final croppedPath =
    await scannerKey.currentState?.cropImage();
    if (croppedPath != null &&
        croppedPath.isNotEmpty) {
      // Добавляем файл через Cubit или другой механизм
      context
          .read<ScanFilesCubit>()
          .addFile(croppedPath);
      context.read<FilesCubit>().addFile(croppedPath);

      // Если одиночный режим — сразу уходим на экран сканирования
      if (!isMultiPhoto) {
        // Останавливаем работу сканера, чтобы камера не работала в фоне
        scannerKey.currentState?.stopScanner();

        final files =
            context.read<ScanFilesCubit>().state;
        navigation.navigateTo(
          context,
          PdfEditScreen(file: files.last),
        );
      }
    }
  }

  /// Метод для выбора файла из памяти
  Future<void> _pickFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image, // только изображения
      allowMultiple: false, // один файл
    );

    if (result != null && result.files.isNotEmpty) {
      final filePath = result.files.single.path;
      if (filePath != null) {
        // Добавляем файл в cubit
        context.read<ScanFilesCubit>().addFile(filePath);
        context.read<FilesCubit>().addFile(filePath);

        // Если одиночный режим — сразу уходим на экран сканирования
        if (!isMultiPhoto) {
          // Останавливаем работу сканера, чтобы камера не работала в фоне
          scannerKey.currentState?.stopScanner();

          final files = context.read<ScanFilesCubit>().state;
          navigation.navigateTo(
            context,
            PdfEditScreen(file: files.single),
          );
        }
      }
    }
  }

  @override
  void didChangeDependencies() {
    context.read<ScanFilesCubit>().clearState();
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DocumentScannerWidget(key: scannerKey),
          ),

          // Кнопки управления (внизу)
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
                  // Тоггл для переключения режима фото
                  PhotoToggle(
                    onToggle: (bool isMulti) {
                      isMultiPhoto = isMulti;
                    },
                  ),
                   SizedBox(height: 10.h),

                  // Отображение миниатюры последних файлов и кнопок
                  BlocBuilder<ScanFilesCubit, List<ScanFile>>(
                    builder: (BuildContext context, files) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Если есть файлы — показываем последний добавленный
                          files.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    // Переходим на экран со всеми файлами
                                    navigation.navigateTo(
                                      context,
                                      ScanningFilesScreen(),
                                    );
                                  },
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      ClipRRect(
                                        borderRadius:  BorderRadius.all(
                                            Radius.circular(3.r)),
                                        child: Image.file(
                                          File(files.last.path),
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
                                              files.length.toString(),
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
                              :  SizedBox(width: 60.w),

                          // Кнопка "сделать снимок"
                          GestureDetector(
                            onTap: () => _takePhoto(context),
                            child: Assets.images.shutter.image(
                              width: 72.w,
                              height: 72.w,
                              fit: BoxFit.cover,
                            ),
                          ),

                          // Кнопка "добавить файл"
                          CustomCircularButton(
                            onTap: () => _pickFile(context),
                            child: AppIcons.addFiles19x22,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Кнопка "назад" (вверху слева)
          Positioned(
            top: 75.h,
            left: 16.w,
            child: CustomCircularButton(
              withShadow: false,
              color: AppColors.black.withValues(alpha: 0.6),
              onTap: () {
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
