import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:owl_tech_pdf_scaner/app/app_icons.dart';
import 'package:owl_tech_pdf_scaner/app/app_text_style.dart';
import 'package:owl_tech_pdf_scaner/gen/assets.gen.dart';
import 'package:owl_tech_pdf_scaner/models/scan_file.dart';
import 'package:owl_tech_pdf_scaner/screens/pdf_edit_screen.dart';
import 'package:owl_tech_pdf_scaner/services/navigation_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../blocs/files_cubit.dart';
import '../blocs/filter_cubit.dart';
import '../services/revenuecat_service.dart';
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
                SizedBox(height: 60.h),
                SizedBox(height: 16.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
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
                                  child: AppIcons.deleteBlue24x24,
                                ),
                                SizedBox(width: 8.w),
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
                                      right: 16.w,
                                      top: 137.h,
                                      child: Material(
                                        color: Colors.transparent,
                                        child: FilterPopup(),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: AppIcons.filterBlack24x12,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: sortedFiles.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // ElevatedButton(
                                //   onPressed: () {
                                //     navigation.navigateTo(
                                //         context, DocumentScannerTest());
                                //   },
                                //   child: Text('DocumentScannerTest'),
                                // ),
                                ElevatedButton(
                                  onPressed: () {
                                    navigation.navigateTo(
                                        context, SubscriptionTestPage());
                                  },
                                  child: Text('OnboardingScreen'),
                                ),
                                Assets.images.imagePhotoroom2
                                    .image(width: 261.w, height: 217.h),
                                SizedBox(height: 8.h),
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
                                    SizedBox(height: 16.h),
                          ),
                  ),
                ),
                SizedBox(height: 16.h),
              ],
            );
          },
        );
      },
    );
  }
}

class SubscriptionTestPage extends StatefulWidget {
  const SubscriptionTestPage({Key? key}) : super(key: key);

  @override
  _SubscriptionTestPageState createState() => _SubscriptionTestPageState();
}

class _SubscriptionTestPageState extends State<SubscriptionTestPage> {
  String _info = "Загрузка данных...";

  @override
  void initState() {
    super.initState();
    _loadSubscriptionData();
  }

  Future<void> _loadSubscriptionData() async {
    // Инициализируем RevenueCat
    await RevenueCatService().init();

    try {
      // Получаем информацию о покупателе
      final customerInfo = await Purchases.getCustomerInfo();
      final bool isSubscribed = customerInfo.entitlements.active.isNotEmpty;

      // Получаем офферы (пакеты подписок)
      final offerings = await Purchases.getOfferings();
      String offeringsText = "";
      if (offerings.current != null &&
          offerings.current!.availablePackages.isNotEmpty) {
        for (var pkg in offerings.current!.availablePackages) {
          offeringsText += "Пакет: ${pkg.identifier}\n";
          offeringsText += "Название: ${pkg.presentedOfferingContext.offeringIdentifier}\n";
          offeringsText += "Описание: ${pkg.storeProduct.title}\n";
          offeringsText += "Цена: ${pkg.storeProduct.priceString}\n\n";
        }
      } else {
        offeringsText = "Офферы недоступны";
      }

      setState(() {
        _info = "Статус подписки: ${isSubscribed ? "активна" : "не активна"}\n\nОфферы:\n$offeringsText";
      });
    } catch (e) {
      setState(() {
        _info = "Ошибка при загрузке данных: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Тест подписок RevenueCat")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          _info,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
