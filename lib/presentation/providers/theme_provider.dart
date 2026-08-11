import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:business_sahaj_erp/core/constants/app_constants.dart';

enum AppGradientPreset {
  executiveIndigo, // #4F46E5 -> #818CF8
  emeraldTeal,     // #059669 -> #14B8A6
  sunsetRose,      // #E11D48 -> #C084FC
  amberGold,       // #D97706 -> #F97316
  obsidianCyan,    // #0284C7 -> #06B6D4
}

class ThemeState {
  final ThemeMode themeMode;
  final AppGradientPreset gradientPreset;

  const ThemeState({
    this.themeMode = ThemeMode.system,
    this.gradientPreset = AppGradientPreset.executiveIndigo,
  });

  ThemeState copyWith({
    ThemeMode? themeMode,
    AppGradientPreset? gradientPreset,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      gradientPreset: gradientPreset ?? this.gradientPreset,
    );
  }
}

// Provider for SharedPreferences to support synchronous reads in providers.
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
    final gradientString = _prefs.getString('key_gradient_preset');

    ThemeMode mode = ThemeMode.system;
    if (themeString != null) {
      switch (themeString) {
        case 'light': mode = ThemeMode.light; break;
        case 'dark': mode = ThemeMode.dark; break;
        case 'system':
        default: mode = ThemeMode.system; break;
      }
    }

    AppGradientPreset preset = AppGradientPreset.executiveIndigo;
    if (gradientString != null) {
      switch (gradientString) {
        case 'emeraldTeal': preset = AppGradientPreset.emeraldTeal; break;
        case 'sunsetRose': preset = AppGradientPreset.sunsetRose; break;
        case 'amberGold': preset = AppGradientPreset.amberGold; break;
        case 'obsidianCyan': preset = AppGradientPreset.obsidianCyan; break;
        case 'executiveIndigo':
        default: preset = AppGradientPreset.executiveIndigo; break;
      }
    }

    state = ThemeState(themeMode: mode, gradientPreset: preset);
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

  Future<void> setGradientPreset(AppGradientPreset preset) async {
    state = state.copyWith(gradientPreset: preset);
    await _prefs.setString('key_gradient_preset', preset.name);
  }

  Future<void> toggleTheme() async {
    if (state.themeMode == ThemeMode.dark) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }
}
