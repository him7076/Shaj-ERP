import 'package:flutter/material.dart';
import 'package:business_sahaj_erp/presentation/providers/theme_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ModernFormSection extends ConsumerWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final Widget child;
  final Widget? trailing;

  const ModernFormSection({
    Key? key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.iconColor,
    required this.child,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveColor = iconColor ?? theme.colorScheme.primary;
    final themeState = ref.watch(themeProvider);
    final isNeumorphic = themeState.themeType == ThemeType.neumorphism;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isNeumorphic 
            ? theme.scaffoldBackgroundColor 
            : (isDark ? const Color(0xFF131B2E) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: isNeumorphic 
            ? null 
            : Border.all(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                width: 1.0,
              ),
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
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: effectiveColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: effectiveColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          Divider(
            height: 1,
            thickness: 0.5,
            color: isNeumorphic 
                ? (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05))
                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
          ),
          const SizedBox(height: 18),

          // Body Content
          child,
        ],
      ),
    );
  }
}
