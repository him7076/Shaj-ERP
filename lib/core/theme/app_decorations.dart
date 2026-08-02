import 'package:flutter/material.dart';

class AppDecorations {
  // Border Radius Constants
  static const double radiusSmall = 10.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;
  static const double radiusPill = 99.0;

  static final BorderRadius borderRadiusSmall = BorderRadius.circular(radiusSmall);
  static final BorderRadius borderRadiusMedium = BorderRadius.circular(radiusMedium);
  static final BorderRadius borderRadiusLarge = BorderRadius.circular(radiusLarge);
  static final BorderRadius borderRadiusPill = BorderRadius.circular(radiusPill);

  // Soft Ambient Box Shadows for Glass Cards & Floating Elevation
  static List<BoxShadow> ambientShadow({Color? color, double blur = 20, double spread = 0, Offset offset = const Offset(0, 8)}) {
    return [
      BoxShadow(
        color: (color ?? const Color(0xFF6366F1)).withOpacity(0.08),
        blurRadius: blur,
        spreadRadius: spread,
        offset: offset,
      ),
      BoxShadow(
        color: Colors.black.withOpacity(0.03),
        blurRadius: 6,
        spreadRadius: 0,
        offset: const Offset(0, 2),
      ),
    ];
  }

  static List<BoxShadow> hoverShadow({Color? color}) {
    return [
      BoxShadow(
        color: (color ?? const Color(0xFF6366F1)).withOpacity(0.18),
        blurRadius: 28,
        spreadRadius: 2,
        offset: const Offset(0, 12),
      ),
    ];
  }

  // Premium Hero Gradients
  static const LinearGradient primaryIndigoGradient = LinearGradient(
    colors: [
      Color(0xFF4F46E5),
      Color(0xFF6366F1),
      Color(0xFF818CF8),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient drawerHeaderGradient = LinearGradient(
    colors: [
      Color(0xFF1E1B4B),
      Color(0xFF312E81),
      Color(0xFF4338CA),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient glassCardGradient(bool isDark) {
    return LinearGradient(
      colors: isDark
          ? [
              const Color(0xFF1E293B).withOpacity(0.7),
              const Color(0xFF0F172A).withOpacity(0.8),
            ]
          : [
              Colors.white.withOpacity(0.9),
              const Color(0xFFF8FAFC).withOpacity(0.85),
            ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  // Glass Card Border Styling
  static Border glassBorder(bool isDark, {Color? accentColor}) {
    return Border.all(
      color: accentColor?.withOpacity(0.3) ??
          (isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE2E8F0)),
      width: 1.0,
    );
  }
}
