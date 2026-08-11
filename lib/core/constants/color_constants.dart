import 'package:flutter/material.dart';
import 'package:business_sahaj_erp/presentation/providers/theme_provider.dart';

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

  // Dual-Tone Gradient Presets Color Resolvers
  static Color getPrimary(AppGradientPreset preset, Brightness brightness) {
    switch (preset) {
      case AppGradientPreset.emeraldTeal: return const Color(0xFF059669);
      case AppGradientPreset.sunsetRose: return const Color(0xFFE11D48);
      case AppGradientPreset.amberGold: return const Color(0xFFD97706);
      case AppGradientPreset.obsidianCyan: return const Color(0xFF0284C7);
      case AppGradientPreset.executiveIndigo:
      default: return const Color(0xFF4F46E5);
    }
  }

  static Color getSecondary(AppGradientPreset preset, Brightness brightness) {
    switch (preset) {
      case AppGradientPreset.emeraldTeal: return const Color(0xFF14B8A6);
      case AppGradientPreset.sunsetRose: return const Color(0xFFC084FC);
      case AppGradientPreset.amberGold: return const Color(0xFFF97316);
      case AppGradientPreset.obsidianCyan: return const Color(0xFF06B6D4);
      case AppGradientPreset.executiveIndigo:
      default: return const Color(0xFF818CF8);
    }
  }

  // Legacy static color compatibility
  static const Color primaryLight = Color(0xFF4F46E5);
  static const Color onPrimaryLight = Colors.white;
  static const Color primaryContainerLight = Color(0xFFEEF2FF);
  static const Color onPrimaryContainerLight = Color(0xFF312E81);

  static const Color primaryDark = Color(0xFF818CF8);
  static const Color onPrimaryDark = Color(0xFF1E1B4B);
  static const Color primaryContainerDark = Color(0xFF3730A3);
  static const Color onPrimaryContainerDark = Color(0xFFEEF2FF);
}

