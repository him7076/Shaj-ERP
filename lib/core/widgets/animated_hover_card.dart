import 'package:flutter/material.dart';
import 'package:business_sahaj_erp/core/theme/app_decorations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:business_sahaj_erp/presentation/providers/theme_provider.dart';

class AnimatedHoverCard extends ConsumerStatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final Color? hoverBorderColor;
  final Color? glowColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final bool enableScale;

  const AnimatedHoverCard({
    Key? key,
    required this.child,
    this.onTap,
    this.borderRadius,
    this.hoverBorderColor,
    this.glowColor,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.enableScale = true,
  }) : super(key: key);

  @override
  ConsumerState<AnimatedHoverCard> createState() => _AnimatedHoverCardState();
}

class _AnimatedHoverCardState extends ConsumerState<AnimatedHoverCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeState = ref.watch(themeProvider);
    final isNeumorphic = themeState.themeType == ThemeType.neumorphism;

    final effectiveRadius = widget.borderRadius ?? AppDecorations.borderRadiusMedium;
    final effectiveBg = isNeumorphic ? theme.scaffoldBackgroundColor : (widget.backgroundColor ?? theme.colorScheme.surface);

    final double scale = _isPressed
        ? 0.98
        : (_isHovered && widget.enableScale ? 1.02 : 1.0);

    final double translateY = _isHovered && !isNeumorphic ? -3.0 : 0.0;

    final Color borderColor = isNeumorphic 
        ? Colors.transparent
        : (_isHovered
            ? (widget.hoverBorderColor ?? theme.colorScheme.primary.withOpacity(0.5))
            : (isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0)));

    List<BoxShadow> shadows;
    
    if (isNeumorphic) {
      if (_isPressed) {
        shadows = []; // Pressed effect inside (handled via color in a real inner shadow, but flattening outer shadow works well enough for cards)
      } else if (_isHovered) {
        shadows = [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.8) : const Color(0xFFA3B1C6).withOpacity(0.8),
            offset: const Offset(8, 8),
            blurRadius: 16,
          ),
          BoxShadow(
            color: isDark ? const Color(0xFF2D2D36).withOpacity(0.7) : Colors.white.withOpacity(1.0),
            offset: const Offset(-8, -8),
            blurRadius: 16,
          ),
        ];
      } else {
        shadows = [
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
        ];
      }
    } else {
      shadows = _isHovered
          ? AppDecorations.hoverShadow(color: widget.glowColor ?? theme.colorScheme.primary)
          : AppDecorations.ambientShadow(color: widget.glowColor);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          margin: widget.margin,
          padding: widget.padding,
          transform: Matrix4.translationValues(0, translateY, 0)..scale(scale),
          decoration: BoxDecoration(
            color: effectiveBg,
            borderRadius: effectiveRadius,
            border: Border.all(color: borderColor, width: _isHovered ? 1.5 : 1.0),
            boxShadow: shadows,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
