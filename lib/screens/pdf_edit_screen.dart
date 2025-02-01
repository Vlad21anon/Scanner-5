// PdfEditScreen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:owl_tech_pdf_scaner/models/scan_file.dart';
import '../app/app_colors.dart';
import '../app/app_text_style.dart';
import '../gen/assets.gen.dart';
import '../services/navigation_service.dart';
import '../widgets/crop_widget.dart';
import '../widgets/custom_circular_button.dart';
import '../widgets/pen_edit_widget.dart';
import '../widgets/text_edit_widget.dart';
import '../widgets/toggle_menu.dart';

class PdfEditScreen extends StatefulWidget {
  final ScanFile file;

  const PdfEditScreen({super.key, required this.file});

  @override
  State<PdfEditScreen> createState() => _PdfEditScreenState();
}

class _PdfEditScreenState extends State<PdfEditScreen> {
  int _selectedIndex = 0;
  int _oldIndex = 0;
  int _penModeCount = 0; // Счётчик использования режима Pen

  // Глобальные ключи для вызова функций сохранения в каждом режиме
  final GlobalKey<CropWidgetState> _cropKey = GlobalKey<CropWidgetState>();
  final GlobalKey<TextEditWidgetState> _textKey = GlobalKey<TextEditWidgetState>();
  final GlobalKey<PenEditWidgetState> _penKey = GlobalKey<PenEditWidgetState>();

  late List<Widget> _pages = [];

  @override
  void initState() {
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

  Future<bool?> _showSubscriptionDialog() async {
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

  // Stub‑вариант функции для преобразования и шаринга файла в PDF.
  Future<void> _sharePdfFile() async {
    // Здесь реализуйте преобразование аннотированного изображения в PDF
    // и вызов плагина, например, share_plus.
    debugPrint("Реализуйте логику шаринга PDF-файла");
  }

  void _onIndexChanged(int newIndex) async {
    // При переходе из режима Crop сохраняем изменения.
    if (_oldIndex == 0 && newIndex != 0) {
      await _cropKey.currentState?.saveCrop();
    }
    // При переходе из режима текста сохраняем текст.
    if (_oldIndex == 1 && newIndex != 1) {
      await _textKey.currentState?.saveTextInImage();
    }
    // При переходе из режима Pen сохраняем аннотации.
    if (_oldIndex == 2 && newIndex != 2) {
      await _penKey.currentState?.saveAnnotatedImage();
    }

    // Если переключаемся в режим Pen, учитываем лимит использования.
    if (newIndex == 2) {
      _penModeCount++;
      if (_penModeCount > 2) {
        bool? allowed = await _showSubscriptionDialog();
        if (allowed != true) {
          // Если пользователь отменяет, остаёмся в предыдущем режиме.
          return;
        }
      }
    }

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
                      onTap: () {
                        navigation.pop(context);
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
