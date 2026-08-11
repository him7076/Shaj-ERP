import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:business_sahaj_erp/core/constants/app_constants.dart';

enum AppThemePreset {
  // 8 Dual-Tone Gradients
  executiveIndigo, // #4F46E5 -> #818CF8
  emeraldTeal,     // #059669 -> #14B8A6
  sunsetRose,      // #E11D48 -> #C084FC
  amberGold,       // #D97706 -> #F97316
  obsidianCyan,    // #0284C7 -> #06B6D4
  midnightPurple,  // #6D28D9 -> #A855F7
  oceanBlue,       // #2563EB -> #38BDF8
  crimsonFlame,    // #991B1B -> #EF4444

  // 8 Solid Accent Colors
  classicNavy,     // #1E3A8A
  pureEmerald,     // #047857
  darkCharcoal,    // #1F2937
  royalViolet,     // #5B21B6
  deepCrimson,     // #991B1B
  burntOrange,     // #C2410C
  deepCyan,        // #0E7490
  forestGreen,     // #14532D

  // Custom Spectrum User Color
  custom,
}

class ThemeState {
  final ThemeMode themeMode;
  final AppThemePreset themePreset;
  final Color? customPrimaryColor;
  final Color? customSecondaryColor;

  const ThemeState({
    this.themeMode = ThemeMode.system,
    this.themePreset = AppThemePreset.executiveIndigo,
    this.customPrimaryColor,
    this.customSecondaryColor,
  });

  ThemeState copyWith({
    ThemeMode? themeMode,
    AppThemePreset? themePreset,
    Color? customPrimaryColor,
    Color? customSecondaryColor,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      themePreset: themePreset ?? this.themePreset,
      customPrimaryColor: customPrimaryColor ?? this.customPrimaryColor,
      customSecondaryColor: customSecondaryColor ?? this.customSecondaryColor,
    );
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences has not been initialized');
});

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeNotifier(prefs);
});

class ThemeNotifier extends StateNotifier<ThemeState> {
  final SharedPreferences _prefs;

  ThemeNotifier(this._prefs) : super(const ThemeState()) {
    _loadTheme();
  }

  void _loadTheme() {
    final themeString = _prefs.getString(AppConstants.keyThemeMode);
    final presetString = _prefs.getString('key_theme_preset');
    final primaryValue = _prefs.getInt('key_custom_primary_color');
    final secondaryValue = _prefs.getInt('key_custom_secondary_color');

    ThemeMode mode = ThemeMode.system;
    if (themeString != null) {
      switch (themeString) {
        case 'light': mode = ThemeMode.light; break;
        case 'dark': mode = ThemeMode.dark; break;
        case 'system':
        default: mode = ThemeMode.system; break;
      }
    }

    AppThemePreset preset = AppThemePreset.executiveIndigo;
    if (presetString != null) {
      for (var val in AppThemePreset.values) {
        if (val.name == presetString) {
          preset = val;
          break;
        }
      }
    }

    final customPrimary = primaryValue != null ? Color(primaryValue) : null;
    final customSecondary = secondaryValue != null ? Color(secondaryValue) : null;

    state = ThemeState(
      themeMode: mode,
      themePreset: preset,
      customPrimaryColor: customPrimary,
      customSecondaryColor: customSecondary,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    String themeString;
    switch (mode) {
      case ThemeMode.light: themeString = 'light'; break;
      case ThemeMode.dark: themeString = 'dark'; break;
      case ThemeMode.system: themeString = 'system'; break;
    }
    await _prefs.setString(AppConstants.keyThemeMode, themeString);
  }

  Future<void> setThemePreset(AppThemePreset preset) async {
    state = state.copyWith(themePreset: preset);
    await _prefs.setString('key_theme_preset', preset.name);
  }

  Future<void> setCustomColors(Color primary, Color secondary) async {
    state = state.copyWith(
      themePreset: AppThemePreset.custom,
      customPrimaryColor: primary,
      customSecondaryColor: secondary,
    );
    await _prefs.setString('key_theme_preset', AppThemePreset.custom.name);
    await _prefs.setInt('key_custom_primary_color', primary.value);
    await _prefs.setInt('key_custom_secondary_color', secondary.value);
  }

  Future<void> toggleTheme() async {
    if (state.themeMode == ThemeMode.dark) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }
}
