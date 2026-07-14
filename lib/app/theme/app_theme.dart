import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  const AppTheme._();
  static ThemeData light() => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary, secondary: AppColors.secondary, surface: AppColors.lightBackground),
    cardTheme: const CardTheme(elevation: 1, margin: EdgeInsets.all(12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20)))),
  );
  static ThemeData dark() => ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: AppColors.secondary, brightness: Brightness.dark));
}
