import 'package:flutter/material.dart';
import 'package:business_sahaj_erp/core/widgets/neu_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_sahaj_erp/presentation/providers/theme_provider.dart';

class NeuCard extends ConsumerWidget {
  final Widget child;
  final double? elevation;
  final Clip? clipBehavior;
  final ShapeBorder? shape;
  final Color? color;
  final BoxDecoration? decoration;
  final EdgeInsetsGeometry? margin;

  const NeuCard({
    Key? key,
    required this.child,
    this.elevation,
    this.clipBehavior,
    this.shape,
    this.color,
    this.decoration,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final isNeumorphic = themeState.themeType == ThemeType.neumorphism;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (!isNeumorphic) {
      // Standard theme — render as normal Card, unchanged
      return Card(
        margin: margin,
        elevation: elevation,
        clipBehavior: clipBehavior,
        shape: shape,
        color: color,
        child: decoration != null
            ? Container(
                decoration: decoration,
                child: child,
              )
            : child,
      );
    }

    // ═══════════════════════════════════════════════════════
    // NEUMORPHISM MODE
    // ═══════════════════════════════════════════════════════
    final borderRadius = _extractBorderRadius(shape) ?? BorderRadius.circular(16);
    
    // Base color must match scaffold background for neumorphic illusion
    final baseColor = theme.scaffoldBackgroundColor;

    // Strong dual shadows for visible emboss effect
    final shadowLight = isDark 
        ? Colors.white.withOpacity(0.07) 
        : Colors.white.withOpacity(0.85);
    final shadowDark = isDark 
        ? Colors.black.withOpacity(0.6) 
        : const Color(0xFFB0BEC5).withOpacity(0.5);

    // Extract accent left-border from child's Container decoration (if present)
    // The forms have: NeuCard(child: Container(decoration: BoxDecoration(border: Border(left: ...)), child: ...))
    // We need to detect and style that inner container too

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      padding: const EdgeInsets.all(2), // tiny padding so shadows don't clip
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: borderRadius,
        boxShadow: [
          // Dark shadow (bottom-right) — gives depth
          BoxShadow(
            color: shadowDark,
            offset: const Offset(4, 4),
            blurRadius: 8,
            spreadRadius: 0,
          ),
          // Light shadow (top-left) — gives raised look
          BoxShadow(
            color: shadowLight,
            offset: const Offset(-4, -4),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: child,
      ),
    );
  }

  BorderRadiusGeometry? _extractBorderRadius(ShapeBorder? shape) {
    if (shape is RoundedRectangleBorder) {
      return shape.borderRadius;
    }
    return null;
  }
}
