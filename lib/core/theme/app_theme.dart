import 'package:flutter/material.dart';
import 'package:business_sahaj_erp/core/constants/color_constants.dart';

class AppTheme {
  static ThemeData get lightTheme => getLightTheme(AccentColorPreset.indigo);
  static ThemeData get darkTheme => getDarkTheme(AccentColorPreset.indigo);

  // Light Theme Builder
  static ThemeData getLightTheme(AccentColorPreset preset) {
    final primary = ColorConstants.getPrimary(preset, Brightness.light);
    final primaryContainer = ColorConstants.getPrimaryContainer(preset, Brightness.light);
    final onPrimaryContainer = ColorConstants.getOnPrimaryContainer(preset, Brightness.light);

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
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: const Color(0xFF0EA5E9),
        onSecondary: Colors.white,
        secondaryContainer: const Color(0xFFE0F2FE),
        onSecondaryContainer: const Color(0xFF0369A1),
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
  static ThemeData getDarkTheme(AccentColorPreset preset) {
    final primary = ColorConstants.getPrimary(preset, Brightness.dark);
    final primaryContainer = ColorConstants.getPrimaryContainer(preset, Brightness.dark);
    final onPrimaryContainer = ColorConstants.getOnPrimaryContainer(preset, Brightness.dark);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Inter',
      scaffoldBackgroundColor: ColorConstants.backgroundDark,
      canvasColor: ColorConstants.backgroundDark,
      dialogBackgroundColor: ColorConstants.surfaceDark,
      colorScheme: ColorScheme.dark(
        primary: primary,
        onPrimary: const Color(0xFF0F172A),
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: const Color(0xFF38BDF8),
        onSecondary: const Color(0xFF0C4A6E),
        secondaryContainer: const Color(0xFF0369A1),
        onSecondaryContainer: const Color(0xFFE0F2FE),
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

