import 'package:flutter/material.dart';
import 'package:business_sahaj_erp/core/constants/color_constants.dart';
import 'package:business_sahaj_erp/core/constants/app_constants.dart';

class AppTheme {
  // Light Theme Configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: ColorConstants.primaryLight,
        onPrimary: ColorConstants.onPrimaryLight,
        primaryContainer: ColorConstants.primaryContainerLight,
        onPrimaryContainer: ColorConstants.onPrimaryContainerLight,
        secondary: ColorConstants.secondaryLight,
        onSecondary: ColorConstants.onSecondaryLight,
        secondaryContainer: ColorConstants.secondaryContainerLight,
        onSecondaryContainer: ColorConstants.onSecondaryContainerLight,
        tertiary: ColorConstants.tertiaryLight,
        onTertiary: ColorConstants.onTertiaryLight,
        tertiaryContainer: ColorConstants.tertiaryContainerLight,
        onTertiaryContainer: ColorConstants.onTertiaryContainerLight,
        error: ColorConstants.errorLight,
        onError: ColorConstants.onErrorLight,
        errorContainer: ColorConstants.errorContainerLight,
        onErrorContainer: ColorConstants.onErrorContainerLight,
        background: ColorConstants.backgroundLight,
        onBackground: ColorConstants.onBackgroundLight,
        surface: ColorConstants.surfaceLight,
        onSurface: ColorConstants.onSurfaceLight,
        surfaceVariant: ColorConstants.surfaceVariantLight,
        onSurfaceVariant: ColorConstants.onSurfaceVariantLight,
        outline: ColorConstants.outlineLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: ColorConstants.primaryLight,
        foregroundColor: ColorConstants.onPrimaryLight,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: ColorConstants.surfaceLight,
        elevation: AppConstants.defaultCardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          side: const BorderSide(color: ColorConstants.surfaceVariantLight, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorConstants.primaryLight,
          foregroundColor: ColorConstants.onPrimaryLight,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          ),
          elevation: 1,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColorConstants.backgroundLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          borderSide: const BorderSide(color: ColorConstants.outlineLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          borderSide: const BorderSide(color: ColorConstants.surfaceVariantLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          borderSide: const BorderSide(color: ColorConstants.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          borderSide: const BorderSide(color: ColorConstants.errorLight),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  // Dark Theme Configuration
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: ColorConstants.primaryDark,
        onPrimary: ColorConstants.onPrimaryDark,
        primaryContainer: ColorConstants.primaryContainerDark,
        onPrimaryContainer: ColorConstants.onPrimaryContainerDark,
        secondary: ColorConstants.secondaryDark,
        onSecondary: ColorConstants.onSecondaryDark,
        secondaryContainer: ColorConstants.secondaryContainerDark,
        onSecondaryContainer: ColorConstants.onSecondaryContainerDark,
        tertiary: ColorConstants.tertiaryDark,
        onTertiary: ColorConstants.onTertiaryDark,
        tertiaryContainer: ColorConstants.tertiaryContainerDark,
        onTertiaryContainer: ColorConstants.onTertiaryContainerDark,
        error: ColorConstants.errorDark,
        onError: ColorConstants.onErrorDark,
        errorContainer: ColorConstants.errorContainerDark,
        onErrorContainer: ColorConstants.onErrorContainerDark,
        background: ColorConstants.backgroundDark,
        onBackground: ColorConstants.onBackgroundDark,
        surface: ColorConstants.surfaceDark,
        onSurface: ColorConstants.onSurfaceDark,
        surfaceVariant: ColorConstants.surfaceVariantDark,
        onSurfaceVariant: ColorConstants.onSurfaceVariantDark,
        outline: ColorConstants.outlineDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: ColorConstants.surfaceDark,
        foregroundColor: ColorConstants.onSurfaceDark,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: ColorConstants.surfaceDark,
        elevation: AppConstants.defaultCardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          side: const BorderSide(color: ColorConstants.surfaceVariantDark, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorConstants.primaryDark,
          foregroundColor: ColorConstants.onPrimaryDark,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          ),
          elevation: 1,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF1E2025),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          borderSide: const BorderSide(color: ColorConstants.outlineDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          borderSide: const BorderSide(color: ColorConstants.surfaceVariantDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          borderSide: const BorderSide(color: ColorConstants.primaryDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          borderSide: const BorderSide(color: ColorConstants.errorDark),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
