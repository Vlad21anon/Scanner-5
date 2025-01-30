import 'dart:io';

import 'package:flutter/material.dart';
import 'package:owl_tech_pdf_scaner/models/scan_file.dart';

import '../app/app_colors.dart';
import '../app/app_text_style.dart';
import '../gen/assets.gen.dart';
import '../services/navigation_service.dart';
import '../widgets/crop_widget.dart';
import '../widgets/custom_circular_button.dart';
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

  // Ключ, чтобы обращаться к состоянию CropWidget и вызывать сохранение
  final GlobalKey<CropWidgetState> _cropKey = GlobalKey<CropWidgetState>();

  late List<Widget> _pages = [];

  @override
  void initState() {
    _pages = [
      // 0. Режим обрезки
      CropWidget(
        key: _cropKey,
        file: widget.file,
      ),

      // 1. Режим текста — передаём ScanFile
      TextEditWidget(file: widget.file),

      // 2. Режим pen
      const Center(child: Text('Pen page')),
    ];
    super.initState();
  }

  void _onIndexChanged(int newIndex) async {
    /// Если выходим из режима Crop (был 0, стало не 0), то делаем обрезку
    if (_oldIndex == 0 && newIndex != 0) {
      await _cropKey.currentState?.saveCrop(); // вызываем метод сохранения
    }

    // Если уходим с режима текста (1) на что-то другое,
    // то "сохраняем" или фиксируем изменения текста
    if (_oldIndex == 1 && newIndex != 1) {
      // При необходимости можно вызвать тут метод cubit'а,
      // но обычно состояние уже хранится. Для примера:
      // context.read<TextEditCubit>().saveTextChanges();
    }
    // Обновляем состояние
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
      body: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            children: [
              SizedBox(height: 60),
              SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
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
            bottom: 46,
            child: ToggleMenu(
              onIndexChanged: _onIndexChanged,
            ),
          ),
        ],
      ),
    );
  }
}
