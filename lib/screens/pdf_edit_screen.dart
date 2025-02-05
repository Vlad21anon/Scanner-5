import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:owl_tech_pdf_scaner/app/app_icons.dart';
import 'package:owl_tech_pdf_scaner/models/scan_file.dart';
import '../app/app_colors.dart';
import '../app/app_text_style.dart';
import '../blocs/files_cubit.dart';
import '../services/file_share_service.dart';
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
  // Флаг подписки пользователя (можно заменить логикой проверки подписки)
  bool _hasSubscription = false;
  late int _penModeCount; // Счётчик использования режима Pen

  // Глобальные ключи для вызова функций сохранения в каждом режиме
  final GlobalKey<MultiPageCropWidgetState> _cropKey = GlobalKey<MultiPageCropWidgetState>();
  final GlobalKey<TextEditWidgetState> _textKey = GlobalKey<TextEditWidgetState>();
  final GlobalKey<PenEditWidgetState> _penKey = GlobalKey<PenEditWidgetState>();

  late List<Widget> _pages = [];

  @override
  void initState() {
    _penModeCount = 0;
    _pages = [
      // 0. Режим обрезки
      MultiPageCropWidget(
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
      //await FileShareService.shareImageAsPdf(widget.file.path, text: 'Ваш PDF файл');

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
  void didChangeDependencies() {
    context.read<FilesCubit>().lastScanFile = null;
    super.didChangeDependencies();
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
              SizedBox(height: 60.h),
              SizedBox(height: 16.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomCircularButton(
                      onTap: () {
                        navigation.pop(context);
                      },
                      child: AppIcons.arrowLeftBlack22x18,
                    ),
                    Text('Crop', style: AppTextStyle.nunito32),
                    CustomCircularButton(
                      onTap: () async {
                        bool? allowed = await _showSubscriptionDialogOrShare();
                        if (allowed != true) {
                          return; // Не обновляем состояние, остаёмся в предыдущем режиме
                        }
                      },
                      child:AppIcons.share19x22,
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
            bottom: 12.h,
            child: ToggleMenu(
              onIndexChanged: _onIndexChanged,
            ),
          ),
        ],
      ),
    );
  }
}
