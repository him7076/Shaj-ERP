import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_sahaj_erp/presentation/providers/theme_provider.dart';

class NeuCard extends ConsumerWidget {
  final Widget child;
  final double? elevation;
  final Clip? clipBehavior;
  final ShapeBorder? shape;
  final Color? color;
  final BoxDecoration? decoration;

  const NeuCard({
    Key? key,
    required this.child,
    this.elevation,
    this.clipBehavior,
    this.shape,
    this.color,
    this.decoration,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeType = ref.watch(themeProvider);
    final isNeumorphic = themeType == ThemeType.neumorphism;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (!isNeumorphic) {
      return Card(
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

    // Neumorphic styling
    final borderRadius = _extractBorderRadius(shape) ?? BorderRadius.circular(16);
    final baseColor = theme.scaffoldBackgroundColor;
    
    // Calculate shadows based on dark/light mode
    final shadowLightColor = isDark ? Colors.white.withOpacity(0.05) : Colors.white;
    final shadowDarkColor = isDark ? Colors.black.withOpacity(0.5) : Colors.black.withOpacity(0.1);

    // If decoration has a border (like the left accent border), preserve it
    BoxBorder? accentBorder;
    if (decoration != null && decoration!.border != null) {
      accentBorder = decoration!.border;
    }

    return Container(
      margin: const EdgeInsets.all(4.0), // Need margin for shadows to be visible
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: shadowDarkColor,
            offset: const Offset(5, 5),
            blurRadius: 10,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: shadowLightColor,
            offset: const Offset(-5, -5),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        clipBehavior: clipBehavior ?? Clip.none,
        child: accentBorder != null 
            ? Container(
                decoration: BoxDecoration(
                  border: accentBorder,
                ),
                child: child,
              )
            : child,
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
