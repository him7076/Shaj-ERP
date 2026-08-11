import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:business_sahaj_erp/core/constants/app_constants.dart';
import 'package:business_sahaj_erp/core/constants/color_constants.dart';

class ThemeState {
  final ThemeMode themeMode;
  final AccentColorPreset accentPreset;

  const ThemeState({
    this.themeMode = ThemeMode.system,
    this.accentPreset = AccentColorPreset.indigo,
  });

  ThemeState copyWith({
    ThemeMode? themeMode,
    AccentColorPreset? accentPreset,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      accentPreset: accentPreset ?? this.accentPreset,
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
    final accentString = _prefs.getString('key_accent_preset');

    ThemeMode mode = ThemeMode.system;
    if (themeString != null) {
      switch (themeString) {
        case 'light': mode = ThemeMode.light; break;
        case 'dark': mode = ThemeMode.dark; break;
        case 'system':
        default: mode = ThemeMode.system; break;
      }
    }

    AccentColorPreset preset = AccentColorPreset.indigo;
    if (accentString != null) {
      switch (accentString) {
        case 'cyan': preset = AccentColorPreset.cyan; break;
        case 'emerald': preset = AccentColorPreset.emerald; break;
        case 'purple': preset = AccentColorPreset.purple; break;
        case 'indigo':
        default: preset = AccentColorPreset.indigo; break;
      }
    }

    state = ThemeState(themeMode: mode, accentPreset: preset);
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

  Future<void> setAccentPreset(AccentColorPreset preset) async {
    state = state.copyWith(accentPreset: preset);
    await _prefs.setString('key_accent_preset', preset.name);
  }

  Future<void> toggleTheme() async {
    if (state.themeMode == ThemeMode.dark) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }
}
