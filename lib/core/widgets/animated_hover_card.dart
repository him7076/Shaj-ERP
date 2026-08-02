import 'package:flutter/material.dart';
import 'package:business_sahaj_erp/core/theme/app_decorations.dart';

class AnimatedHoverCard extends StatefulWidget {
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
  State<AnimatedHoverCard> createState() => _AnimatedHoverCardState();
}

class _AnimatedHoverCardState extends State<AnimatedHoverCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final effectiveRadius = widget.borderRadius ?? AppDecorations.borderRadiusMedium;
    final effectiveBg = widget.backgroundColor ?? theme.colorScheme.surface;

    final double scale = _isPressed
        ? 0.98
        : (_isHovered && widget.enableScale ? 1.02 : 1.0);

    final double translateY = _isHovered ? -3.0 : 0.0;

    final Color borderColor = _isHovered
        ? (widget.hoverBorderColor ?? theme.colorScheme.primary.withOpacity(0.5))
        : (isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0));

    final List<BoxShadow> shadows = _isHovered
        ? AppDecorations.hoverShadow(color: widget.glowColor ?? theme.colorScheme.primary)
        : AppDecorations.ambientShadow(color: widget.glowColor);

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
