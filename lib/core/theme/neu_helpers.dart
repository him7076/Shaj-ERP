import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_sahaj_erp/presentation/providers/theme_provider.dart';

bool isNeuTheme(WidgetRef ref) {
  return ref.watch(themeProvider).themeType == ThemeType.neumorphism;
}

ButtonStyle neuElevatedStyle(WidgetRef ref, {Color? backgroundColor, Color? foregroundColor}) {
  final isNeu = isNeuTheme(ref);
  if (isNeu) {
    return ElevatedButton.styleFrom(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
    );
  }
  return ElevatedButton.styleFrom(
    backgroundColor: backgroundColor,
    foregroundColor: foregroundColor,
  );
}

InputDecoration neuInputDecoration({
  String? labelText,
  String? hintText,
  Widget? prefixIcon,
  Widget? suffixIcon,
  bool isDense = false,
}) {
  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    isDense: isDense,
  );
}
