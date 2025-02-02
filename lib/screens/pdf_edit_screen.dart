// PdfEditScreen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:owl_tech_pdf_scaner/models/scan_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';
import '../app/app_colors.dart';
import '../app/app_text_style.dart';
import '../gen/assets.gen.dart';
import '../services/navigation_service.dart';
import '../widgets/crop_widget.dart';
import '../widgets/custom_circular_button.dart';
import '../widgets/pen_edit_widget.dart';
import '../widgets/text_edit_widget.dart';
import '../widgets/toggle_menu.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfEditScreen extends StatefulWidget {
  final ScanFile file;

  const PdfEditScreen({super.key, required this.file});

  @override
  State<PdfEditScreen> createState() => _PdfEditScreenState();
}

class _PdfEditScreenState extends State<PdfEditScreen> {
  int _selectedIndex = 0;
  int _oldIndex = 0;
  // Флаг подписки пользователя (можно заменить логикой проверки подписки)
  bool _hasSubscription = false;
  late int _penModeCount; // Счётчик использования режима Pen

  // Глобальные ключи для вызова функций сохранения в каждом режиме
  final GlobalKey<CropWidgetState> _cropKey = GlobalKey<CropWidgetState>();
  final GlobalKey<TextEditWidgetState> _textKey = GlobalKey<TextEditWidgetState>();
  final GlobalKey<PenEditWidgetState> _penKey = GlobalKey<PenEditWidgetState>();

  late List<Widget> _pages = [];

  @override
  void initState() {
    _penModeCount = 0;
    _pages = [
      // 0. Режим обрезки
      CropWidget(
        key: _cropKey,
        file: widget.file,
      ),

      // 1. Режим текста
      TextEditWidget(
        key: _textKey,
        file: widget.file,
      ),

      // 2. Режим pen
      PenEditWidget(
        key: _penKey,
        file: widget.file,
      ),
    ];
    super.initState();
  }

  Future<bool?> _showSubscriptionDialogOrShare() async {
    final bool isSubscriptionHave = true;

    if (isSubscriptionHave) {
      await _sharePdfFile();
      return false;
    }

    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Ограничение доступа"),
          content: const Text(
              "Для продолжения использования режима Pen подпишитесь или поделитесь файлом в формате PDF."),
          actions: [
            TextButton(
              onPressed: () {
                // Здесь можно добавить логику подписки.
                Navigator.of(context).pop(true);
              },
              child: const Text("Подписаться"),
            ),
            TextButton(
              onPressed: () async {
                await _sharePdfFile();
                Navigator.of(context).pop(true);
              },
              child: const Text("Поделиться"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text("Отмена"),
            ),
          ],
        );
      },
    );
  }

  /// Функция для создания PDF-файла из аннотированного изображения и его шаринга
  Future<void> _sharePdfFile() async {
    try {
      // Создаём PDF документ
      final pdf = pw.Document();

      // Получаем путь к изображению из файла
      // Предполагается, что ScanFile содержит путь к изображению в свойстве path
      final imageFile = File(widget.file.path);
      if (!await imageFile.exists()) {
        debugPrint("Файл не найден: ${widget.file.path}");
        return;
      }

      // Читаем байты изображения
      final imageBytes = await imageFile.readAsBytes();

      // Загружаем изображение в PDF формате
      final pdfImage = pw.MemoryImage(imageBytes);

      // Добавляем страницу с изображением в PDF-документ
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(pdfImage, fit: pw.BoxFit.contain),
            );
          },
        ),
      );

      // Сохраняем PDF во временный файл
      final tempDir = await getTemporaryDirectory();
      final pdfPath = '${tempDir.path}/shared_file.pdf';
      final pdfFile = File(pdfPath);
      await pdfFile.writeAsBytes(await pdf.save());

      // Шарим PDF-файл через share_plus
      await Share.shareXFiles([XFile(pdfPath)], text: 'Вот ваш PDF файл');

    } catch (e) {
      debugPrint("Ошибка при создании или шаринге PDF: $e");
    }
  }

  /// Обработчик изменения выбранного пункта меню.
  void _onIndexChanged(int newIndex) async {
    print("Выбранный индекс: $_selectedIndex, Старый индекс: $_oldIndex");

    // Если мы покидаем текущий режим, сохраняем изменения
    if (_oldIndex == 0 && newIndex != 0) {
      await _cropKey.currentState?.saveCrop();
      _textKey.currentState?.updateImage(UniqueKey());
      _penKey.currentState?.updateImage(UniqueKey());
      setState(() {});
    }
    if (_oldIndex == 1 && newIndex != 1) {
      await _textKey.currentState?.saveTextInImage();
      _penKey.currentState?.updateImage(UniqueKey());
      _cropKey.currentState?.updateImage(UniqueKey());
      setState(() {});
    }
    if (_oldIndex == 2 && newIndex != 2) {
      await _penKey.currentState?.saveAnnotatedImage();
      _textKey.currentState?.updateImage(UniqueKey());
      _cropKey.currentState?.updateImage(UniqueKey());
      setState(() {});
    }

    // Если выбран режим Pen
    if (newIndex == 2) {
      _penModeCount++;

      if (_penModeCount > 1 && !_hasSubscription) {
        _penModeCount = 0;
        await _penKey.currentState?.saveAnnotatedImage();
        setState(() {});
        bool? allowed = await _showSubscriptionDialogOrShare();
        if (allowed != true) {
          return; // Не обновляем состояние, остаёмся в предыдущем режиме
        }
      }
    }

    // Обновляем состояние экрана
    setState(() {
      _selectedIndex = newIndex;
      _oldIndex = newIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    final navigation = NavigationService();
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      body: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            children: [
              const SizedBox(height: 60),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomCircularButton(
                      onTap: () {
                        navigation.pop(context);
                      },
                      child: Assets.images.arrowLeft.image(
                        width: 22,
                        height: 18,
                        color: AppColors.black,
                      ),
                    ),
                    Text('Crop', style: AppTextStyle.nunito32),
                    CustomCircularButton(
                      onTap: () async {
                        bool? allowed = await _showSubscriptionDialogOrShare();
                        if (allowed != true) {
                          return; // Не обновляем состояние, остаёмся в предыдущем режиме
                        }
                      },
                      child: Assets.images.share.image(
                        width: 19,
                        height: 22,
                        color: AppColors.black,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: _pages,
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 12,
            child: ToggleMenu(
              onIndexChanged: _onIndexChanged,
            ),
          ),
        ],
      ),
    );
  }
}
