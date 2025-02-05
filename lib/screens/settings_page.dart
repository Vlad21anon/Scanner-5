import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:owl_tech_pdf_scaner/app/app_colors.dart';
import 'package:owl_tech_pdf_scaner/app/app_icons.dart';
import 'package:owl_tech_pdf_scaner/app/app_text_style.dart';
import 'package:owl_tech_pdf_scaner/gen/assets.gen.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Не удалось открыть $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 83.h),
            Text('Settings', style: AppTextStyle.nunito32),
            SizedBox(height: 16.h),
            GestureDetector(
              onTap: () async {
                // Переход на страницу поддержки
                await _openUrl('https://pdf-scanner.lovable.app/');
              },
              child: Assets.images.unlock.image(
                height: 143.h,
                width: 361.w,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: 16.h),
            _buildSettingsItem(
              onTap: () async {
                // Переход на страницу контактов/поддержки
                await _openUrl('https://pdf-scanner.lovable.app/');
              },
              icon: AppIcons.message22x22,
              title: 'Contact us',
            ),
            SizedBox(height: 21.h),
            _buildSettingsItem(
              onTap: () async {
                // Переход на страницу условий использования
                await _openUrl('https://pdf-scanner.lovable.app/terms');
              },
              icon: AppIcons.warning22x22,
              title: 'Terms Of Use',
            ),
            SizedBox(height: 21.h),
            _buildSettingsItem(
              onTap: () async {
                // Переход на страницу политики конфиденциальности
                await _openUrl('https://pdf-scanner.lovable.app/privacy');
              },
              icon: AppIcons.lock20x22,
              title: 'Privacy Policy',
            ),
            SizedBox(height: 21.h),
            _buildSettingsItem(
              onTap: () {
                // Здесь можно добавить логику шаринга приложения
              },
              icon: AppIcons.arrowRight22x18,
              title: 'Share App',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required VoidCallback onTap,
    required Widget icon,
    required String title,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          icon,
          SizedBox(width: 12.w),
          Text(title, style: AppTextStyle.exo20),
        ],
      ),
    );
  }
}
