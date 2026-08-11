import 'package:flutter/material.dart';
import 'package:business_sahaj_erp/core/constants/color_constants.dart';
import 'package:business_sahaj_erp/presentation/providers/theme_provider.dart';

class AppTheme {
  static ThemeData get lightTheme => getLightTheme(AppGradientPreset.executiveIndigo);
  static ThemeData get darkTheme => getDarkTheme(AppGradientPreset.executiveIndigo);

  // Light Theme Builder
  static ThemeData getLightTheme(AppGradientPreset preset) {
    final primary = ColorConstants.getPrimary(preset, Brightness.light);
    final secondary = ColorConstants.getSecondary(preset, Brightness.light);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: ColorConstants.backgroundLight,
      canvasColor: ColorConstants.backgroundLight,
      dialogBackgroundColor: ColorConstants.surfaceLight,
      colorScheme: ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        primaryContainer: primary.withOpacity(0.12),
        onPrimaryContainer: primary,
        secondary: secondary,
        onSecondary: Colors.white,
        secondaryContainer: secondary.withOpacity(0.12),
        onSecondaryContainer: secondary,
        tertiary: const Color(0xFF8B5CF6),
        onTertiary: Colors.white,
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
        outlineVariant: const Color(0xFFCBD5E1),
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
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: ColorConstants.outlineLight, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: ColorConstants.surfaceLight,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(88, 48),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.2),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ColorConstants.onSurfaceLight,
          minimumSize: const Size(88, 48),
          side: const BorderSide(color: ColorConstants.outlineLight, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColorConstants.surfaceVariantLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ColorConstants.outlineLight, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ColorConstants.outlineLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ColorConstants.errorLight, width: 1),
        ),
        labelStyle: const TextStyle(color: ColorConstants.onSurfaceVariantLight, fontSize: 13, fontWeight: FontWeight.w500),
        floatingLabelStyle: TextStyle(color: primary, fontSize: 13, fontWeight: FontWeight.w700),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  // Dark Theme Builder
  static ThemeData getDarkTheme(AppGradientPreset preset) {
    final primary = ColorConstants.getPrimary(preset, Brightness.dark);
    final secondary = ColorConstants.getSecondary(preset, Brightness.dark);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: ColorConstants.backgroundDark,
      canvasColor: ColorConstants.backgroundDark,
      dialogBackgroundColor: ColorConstants.surfaceDark,
      colorScheme: ColorScheme.dark(
        primary: primary,
        onPrimary: Colors.white,
        primaryContainer: primary.withOpacity(0.2),
        onPrimaryContainer: primary,
        secondary: secondary,
        onSecondary: Colors.white,
        secondaryContainer: secondary.withOpacity(0.2),
        onSecondaryContainer: secondary,
        tertiary: const Color(0xFFA78BFA),
        onTertiary: const Color(0xFF4C1D95),
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
        outlineVariant: const Color(0xFF475569),
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
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: ColorConstants.outlineDark, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: ColorConstants.surfaceDark,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: const Color(0xFF0F172A),
          minimumSize: const Size(88, 48),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.2),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ColorConstants.onSurfaceDark,
          minimumSize: const Size(88, 48),
          side: const BorderSide(color: ColorConstants.outlineDark, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColorConstants.surfaceVariantDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ColorConstants.outlineDark, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ColorConstants.outlineDark, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ColorConstants.errorDark, width: 1),
        ),
        labelStyle: const TextStyle(color: ColorConstants.onSurfaceVariantDark, fontSize: 13, fontWeight: FontWeight.w500),
        floatingLabelStyle: TextStyle(color: primary, fontSize: 13, fontWeight: FontWeight.w700),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

