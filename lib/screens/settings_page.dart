import 'package:flutter/material.dart';
import 'package:owl_tech_pdf_scaner/app/app_colors.dart';
import 'package:owl_tech_pdf_scaner/app/app_text_style.dart';
import 'package:owl_tech_pdf_scaner/gen/assets.gen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 83),
            Text('Settings', style: AppTextStyle.nunito32),
            SizedBox(height: 16),
            GestureDetector(
              onTap: () {},
              child: Assets.images.unlock.image(
                height: 141,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 16),
            _buildSettingsItem(
              onTap: () {},
              icon: Assets.images.message.image(
                width: 22,
                height: 22,
              ),
              title: 'Contact us',
            ),
            SizedBox(height: 21),
            _buildSettingsItem(
              onTap: () {},
              icon: Assets.images.warning.image(
                width: 22,
                height: 22,
              ),
              title: 'Terms Of Use',
            ),
            SizedBox(height: 21),
            _buildSettingsItem(
              onTap: () {},
              icon: Assets.images.lock.image(
                width: 20,
                height: 22,
              ),
              title: 'Privacy Policy',
            ),
            SizedBox(height: 21),
            _buildSettingsItem(
              onTap: () {},
              icon: Assets.images.arrowRight.image(
                width: 22,
                height: 18,
              ),
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
          SizedBox(width: 12),
          Text(title, style: AppTextStyle.exo20),
        ],
      ),
    );
  }
}
