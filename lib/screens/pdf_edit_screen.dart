import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:owl_tech_pdf_scaner/app/app_icons.dart';
import 'package:owl_tech_pdf_scaner/models/scan_file.dart';
import 'package:owl_tech_pdf_scaner/screens/subscription_selection_screen.dart';
import '../app/app_colors.dart';
import '../app/app_text_style.dart';
import '../blocs/files_cubit.dart';
import '../services/file_share_service.dart';
import '../services/navigation_service.dart';
import '../services/revenuecat_service.dart';
import '../widgets/crop_widget.dart';
import '../widgets/custom_circular_button.dart';
import '../widgets/pen_edit_widget.dart';
import '../widgets/text_edit_widget.dart';
import '../widgets/toggle_menu.dart';

class PdfEditScreen extends StatefulWidget {
  final ScanFile file;
  final int? index;

  const PdfEditScreen({super.key, required this.file, this.index});

  @override
  State<PdfEditScreen> createState() => _PdfEditScreenState();
}

class _PdfEditScreenState extends State<PdfEditScreen> {
  int _selectedIndex = 0;
  int _oldIndex = 0;

  // Флаг подписки пользователя (можно заменить логикой проверки подписки)
  bool _hasSubscription = true;
  bool _isShareSelected = false;

  // Глобальные ключи для вызова функций сохранения в каждом режиме
  final GlobalKey<MultiPageCropWidgetState> _cropKey =
      GlobalKey<MultiPageCropWidgetState>();
  final GlobalKey<TextEditWidgetState> _textKey =
      GlobalKey<TextEditWidgetState>();
  final GlobalKey<PenEditWidgetState> _penKey = GlobalKey<PenEditWidgetState>();

  final navigation = NavigationService();

  late List<Widget> _pages = [];

  @override
  void initState() {
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

  Future<bool> _showSubscriptionDialog() async {
    // Проверяем наличие активной подписки через RevenueCat
    bool hasSubscription = await RevenueCatService().isUserSubscribed();

    if (hasSubscription) {
      // Если подписка активна, разрешаем использовать режим Pen
      return true;
    } else {
      // Если подписки нет, переходим на экран подписки
      navigation.navigateTo(context, SubscriptionSelectionScreen());
      return false;
    }
  }

  /// Функция для создания PDF-файла из аннотированного изображения и его шаринга
  Future<void> _sharePdfFile() async {
    setState(() {
      _isShareSelected = true;
    });
    try {
      await FileShareService.shareFileAsPdf(widget.file, text: 'Ваш PDF файл');
    } catch (e) {
      debugPrint("Ошибка при создании или шаринге PDF: $e");
    }
    setState(() {
      _isShareSelected = false;
    });
  }

  /// Обработчик изменения выбранного пункта меню.
  void _onIndexChanged(int newIndex) async {
    print("Выбранный индекс: $_selectedIndex, Старый индекс: $_oldIndex");

    // Если мы покидаем текущий режим, сохраняем изменения
    if (_oldIndex == 0 && newIndex != 0) {
      await _cropKey.currentState?.saveCrop();
      _textKey.currentState?.updateImage(UniqueKey());
      _penKey.currentState?.updateImage(UniqueKey());
    }
    if (_oldIndex == 1 && newIndex != 1) {
      await _textKey.currentState?.saveTextInImage();
      _penKey.currentState?.updateImage(UniqueKey());
      _cropKey.currentState?.updateImage(UniqueKey());
    }
    if (_oldIndex == 2 && newIndex != 2) {
      await _penKey.currentState?.saveAnnotatedImage();
      _textKey.currentState?.updateImage(UniqueKey());
      _cropKey.currentState?.updateImage(UniqueKey());
    }

    if (_oldIndex == 2 && newIndex == 2) {
      await _penKey.currentState?.saveAnnotatedImage();
      final state = await _showSubscriptionDialog();
      if (state) {
        _sharePdfFile();
      }
    }

    // Просто обновляем выбранный индекс, без проверки подписки
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

  /// Функция для выбора заголовка экрана в зависимости от выбранного режима и флага share.
  String _getTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Crop';
      case 1:
        return 'Add Text';
      case 2:
        return _isShareSelected ? 'Share' : 'Sign';
      default:
        return '';
    }
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
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: _pages,
                ),
              ),
            ],
          ),
          Positioned(
            top: 60.h,
            left: 16.w,
            right: 16.w,
            child: Padding(
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
                  Text(
                    _getTitle(),
                    style: AppTextStyle.nunito32,
                  ),
                  CustomCircularButton(
                    onTap: () async {
                      final state = await _showSubscriptionDialog();
                      if (state == true) {
                        _sharePdfFile();
                      }
                    },
                    child: AppIcons.share19x22,
                  ),
                ],
              ),
            ),
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
