import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_sahaj_erp/presentation/providers/theme_provider.dart';

class LiquidGlassCard extends ConsumerWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final VoidCallback? onTap;
  final Color? accentGlowColor;
  final Border? customBorder;
  /// When true, skips BackdropFilter to avoid GPU overdraw in scrolling lists.
  /// Use lightweight: true inside ListView/GridView items for smooth 60fps scroll.
  final bool lightweight;

  const LiquidGlassCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.margin,
    this.borderRadius = 20.0,
    this.blur = 12.0,
    this.onTap,
    this.accentGlowColor,
    this.customBorder,
    this.lightweight = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeState = ref.watch(themeProvider);
    final isNeumorphic = themeState.themeType == ThemeType.neumorphism;
    final theme = Theme.of(context);

    final glowColor = accentGlowColor ?? (isDark ? const Color(0xFF6366F1) : const Color(0xFF4F46E5));

    final baseGradient = isNeumorphic 
        ? null
        : (isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1E293B).withOpacity(0.70),
                  const Color(0xFF0F172A).withOpacity(0.50),
                ],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.85),
                  Colors.white.withOpacity(0.55),
                ],
              ));

    final borderColor = isNeumorphic
        ? Border.all(color: Colors.transparent, width: 0)
        : (customBorder ??
            Border.all(
              color: isDark ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.60),
              width: 1.2,
            ));

    final innerDecoration = BoxDecoration(
      color: isNeumorphic ? theme.scaffoldBackgroundColor : null,
      gradient: baseGradient,
      borderRadius: BorderRadius.circular(borderRadius),
      border: borderColor,
    );

    Widget cardContent = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: isNeumorphic ? theme.scaffoldBackgroundColor : null,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: isNeumorphic 
            ? [
                BoxShadow(
                  color: isDark ? Colors.black.withOpacity(0.7) : const Color(0xFFA3B1C6).withOpacity(0.6),
                  offset: const Offset(6, 6),
                  blurRadius: 12,
                ),
                BoxShadow(
                  color: isDark ? const Color(0xFF2D2D36).withOpacity(0.5) : Colors.white.withOpacity(0.9),
                  offset: const Offset(-6, -6),
                  blurRadius: 12,
                ),
              ]
            : (lightweight ? [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ] : [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: glowColor.withOpacity(isDark ? 0.12 : 0.05),
                  blurRadius: 16,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ]),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: (lightweight || isNeumorphic)
            // Lightweight mode or Neumorphic mode: skip BackdropFilter
            ? Container(
                padding: padding,
                decoration: innerDecoration,
                child: child,
              )
            // Full mode: use BackdropFilter for premium static cards (dashboard, dialogs)
            : BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                child: Container(
                  padding: padding,
                  decoration: innerDecoration,
                  child: child,
                ),
              ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}

