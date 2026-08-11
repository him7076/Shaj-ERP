import 'package:flutter/material.dart';

enum AccentColorPreset {
  indigo,  // Indigo SaaS (#6366F1)
  cyan,    // Ocean Cyan (#0EA5E9)
  emerald, // Emerald Pro (#10B981)
  purple,  // Royal Sunset (#8B5CF6)
}

class ColorConstants {
  // Slate/Zinc Neutral Surfaces
  static const Color backgroundLight = Color(0xFFF8FAFC); // Slate 50
  static const Color onBackgroundLight = Color(0xFF0F172A); // Slate 900
  static const Color surfaceLight = Colors.white;
  static const Color onSurfaceLight = Color(0xFF0F172A);
  static const Color surfaceVariantLight = Color(0xFFF1F5F9); // Slate 100
  static const Color onSurfaceVariantLight = Color(0xFF64748B); // Slate 500
  static const Color outlineLight = Color(0xFFE2E8F0); // Slate 200

  static const Color backgroundDark = Color(0xFF0B0F19); // Obsidian Slate
  static const Color onBackgroundDark = Color(0xFFF8FAFC); // Slate 50
  static const Color surfaceDark = Color(0xFF131B2E); // Card Surface
  static const Color onSurfaceDark = Color(0xFFF8FAFC);
  static const Color surfaceVariantDark = Color(0xFF1E293B); // Slate 800
  static const Color onSurfaceVariantDark = Color(0xFF94A3B8); // Slate 400
  static const Color outlineDark = Color(0xFF334155); // Slate 700

  // Status & WCAG 2.1 Compliant Badges
  static const Color success = Color(0xFF10B981); // Emerald
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color info = Color(0xFF0EA5E9); // Sky
  static const Color offlineGrey = Color(0xFF64748B);

  static const Color errorLight = Color(0xFFE11D48); // Rose 600
  static const Color onErrorLight = Colors.white;
  static const Color errorContainerLight = Color(0xFFFFE4E6); // Rose 100
  static const Color onErrorContainerLight = Color(0xFF9F1239); // Rose 800

  static const Color errorDark = Color(0xFFFB7185); // Rose 400
  static const Color onErrorDark = Color(0xFF4C0519); // Rose 950
  static const Color errorContainerDark = Color(0xFF881337); // Rose 900
  static const Color onErrorContainerDark = Color(0xFFFFE4E6); // Rose 100

  // Accent Presets Color Maps
  static Color getPrimary(AccentColorPreset preset, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    switch (preset) {
      case AccentColorPreset.cyan:
        return isDark ? const Color(0xFF38BDF8) : const Color(0xFF0EA5E9);
      case AccentColorPreset.emerald:
        return isDark ? const Color(0xFF34D399) : const Color(0xFF10B981);
      case AccentColorPreset.purple:
        return isDark ? const Color(0xFFA78BFA) : const Color(0xFF8B5CF6);
      case AccentColorPreset.indigo:
      default:
        return isDark ? const Color(0xFF818CF8) : const Color(0xFF6366F1);
    }
  }

  static Color getPrimaryContainer(AccentColorPreset preset, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    switch (preset) {
      case AccentColorPreset.cyan:
        return isDark ? const Color(0xFF0369A1) : const Color(0xFFE0F2FE);
      case AccentColorPreset.emerald:
        return isDark ? const Color(0xFF047857) : const Color(0xFFD1FAE5);
      case AccentColorPreset.purple:
        return isDark ? const Color(0xFF6D28D9) : const Color(0xFFF3E8FF);
      case AccentColorPreset.indigo:
      default:
        return isDark ? const Color(0xFF3730A3) : const Color(0xFFEEF2FF);
    }
  }

  static Color getOnPrimaryContainer(AccentColorPreset preset, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    switch (preset) {
      case AccentColorPreset.cyan:
        return isDark ? const Color(0xFFE0F2FE) : const Color(0xFF0369A1);
      case AccentColorPreset.emerald:
        return isDark ? const Color(0xFFD1FAE5) : const Color(0xFF065F46);
      case AccentColorPreset.purple:
        return isDark ? const Color(0xFFF3E8FF) : const Color(0xFF581C87);
      case AccentColorPreset.indigo:
      default:
        return isDark ? const Color(0xFFEEF2FF) : const Color(0xFF312E81);
    }
  }

  // Legacy static color compatibility
  static const Color primaryLight = Color(0xFF6366F1);
  static const Color onPrimaryLight = Colors.white;
  static const Color primaryContainerLight = Color(0xFFEEF2FF);
  static const Color onPrimaryContainerLight = Color(0xFF312E81);

  static const Color primaryDark = Color(0xFF818CF8);
  static const Color onPrimaryDark = Color(0xFF1E1B4B);
  static const Color primaryContainerDark = Color(0xFF3730A3);
  static const Color onPrimaryContainerDark = Color(0xFFEEF2FF);
}

