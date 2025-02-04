import 'package:flutter/material.dart';
import 'package:owl_tech_pdf_scaner/app/app_colors.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.blue),
      ),
    );
  }
}
