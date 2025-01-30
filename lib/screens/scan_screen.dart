import 'dart:io';
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:owl_tech_pdf_scaner/app/app_colors.dart';
import 'package:owl_tech_pdf_scaner/app/app_text_style.dart';
import 'package:owl_tech_pdf_scaner/blocs/files_cubit/files_cubit.dart';
import 'package:owl_tech_pdf_scaner/blocs/scan_files_cubit/scan_files_cubit.dart';
import 'package:owl_tech_pdf_scaner/models/scan_file.dart';
import 'package:owl_tech_pdf_scaner/screens/pdf_edit_screen.dart';
import 'package:owl_tech_pdf_scaner/screens/scanning_files_screen.dart';
import 'package:owl_tech_pdf_scaner/services/navigation_service.dart';
import '../gen/assets.gen.dart';
import '../widgets/custom_circular_button.dart';
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

  @override
  void initState() {
    super.initState();
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

  /// Метод для съёмки фото
  Future<void> _takePhoto(BuildContext context) async {
    try {
      // Ждём инициализации контроллера
      await _initializeControllerFuture;

      // Делаем снимок и сохраняем во временный файл
      final xFile = await _cameraController.takePicture();
      final filePath = xFile.path;

      // Добавляем файл через Cubit
      context.read<ScanFilesCubit>().addFile(filePath);
      context.read<FilesCubit>().addFile(filePath);

      // Если одиночный режим — сразу уходим на экран сканирования
      if (!isMultiPhoto) {
        final files = context.read<ScanFilesCubit>().state;
        navigation.navigateTo(
          context,
          PdfEditScreen(file: files.first),
        );
      }
    } catch (e) {
      debugPrint('Ошибка при съёмке фото: $e');
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
          // Тут вместо контейнера - превью камеры
          // Используем FutureBuilder, чтобы дождаться инициализации камеры
          Positioned.fill(
            child: FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  // Если инициализировалась — показываем превью
                  return Column(
                    children: [
                      CameraPreview(_cameraController),
                      Expanded(child: Container(color: AppColors.black)),
                    ],
                  );
                } else {
                  // Иначе показываем лоадер
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),

          // Кнопки управления (внизу)
          Positioned(
            bottom: 0,
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: 203,
              padding: const EdgeInsets.all(16),
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
                  const SizedBox(height: 10),

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
                                        borderRadius: const BorderRadius.all(
                                            Radius.circular(3)),
                                        child: Image.file(
                                          File(files.last.path),
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: -13,
                                        right: -13,
                                        child: Container(
                                          width: 26,
                                          height: 26,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppColors.white,
                                          ),
                                          child: Center(
                                            child: Text(
                                              files.length.toString(),
                                              style: AppTextStyle.nunito32
                                                  .copyWith(
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox(width: 60),

                          // Кнопка "сделать снимок"
                          GestureDetector(
                            onTap: () => _takePhoto(context),
                            child: Assets.images.shutter.image(
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                            ),
                          ),

                          // Кнопка "добавить файл"
                          CustomCircularButton(
                            onTap: () => _pickFile(context),
                            child: Assets.images.addFiles.image(
                              width: 19,
                              height: 22,
                              color: AppColors.blue,
                            ),
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
            top: 75,
            left: 16,
            child: CustomCircularButton(
              color: AppColors.black.withValues(alpha: 0.6),
              onTap: () {
                navigation.pop(context);
              },
              child: Assets.images.arrowLeft.image(width: 24, height: 24),
            ),
          ),
        ],
      ),
    );
  }
}
