import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  static final light = ThemeData(
    primaryColor: AppColors.primary,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.background,
    useMaterial3: true,
    // Set initial background to splash color to avoid white flash
    canvasColor: AppColors.splash,
  );

  static final dark = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.primary,
    useMaterial3: true,
    // Set initial background to splash color to avoid white flash
    canvasColor: AppColors.splash,
  );
}
