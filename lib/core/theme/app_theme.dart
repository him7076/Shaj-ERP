import 'package:flutter/material.dart';
import 'package:business_sahaj_erp/core/constants/color_constants.dart';
import 'package:business_sahaj_erp/core/constants/app_constants.dart';

class AppTheme {
  // Light Theme Configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: ColorConstants.backgroundLight,
      canvasColor: ColorConstants.backgroundLight,
      dialogBackgroundColor: ColorConstants.surfaceLight,
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
        backgroundColor: Colors.white,
        foregroundColor: ColorConstants.onSurfaceLight,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        color: ColorConstants.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorConstants.primaryLight,
          foregroundColor: ColorConstants.onPrimaryLight,
          minimumSize: const Size(88, 48),
          elevation: 2,
          shadowColor: ColorConstants.primaryLight.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.3),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ColorConstants.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ColorConstants.errorLight, width: 1),
        ),
        labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
        floatingLabelStyle: const TextStyle(color: ColorConstants.primaryLight, fontSize: 13, fontWeight: FontWeight.w700),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  // Dark Theme Configuration
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ColorConstants.backgroundDark,
      canvasColor: ColorConstants.backgroundDark,
      dialogBackgroundColor: ColorConstants.surfaceDark,
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
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        color: ColorConstants.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF1E293B), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorConstants.primaryDark,
          foregroundColor: ColorConstants.onPrimaryDark,
          minimumSize: const Size(88, 48),
          elevation: 2,
          shadowColor: ColorConstants.primaryDark.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.3),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF131B2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E293B), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E293B), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ColorConstants.primaryDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ColorConstants.errorDark, width: 1),
        ),
        labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w500),
        floatingLabelStyle: const TextStyle(color: ColorConstants.primaryDark, fontSize: 13, fontWeight: FontWeight.w700),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

