import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:business_sahaj_erp/core/utils/responsive_layout.dart';
import 'package:business_sahaj_erp/core/widgets/custom_app_bar.dart';
import 'package:business_sahaj_erp/core/widgets/custom_drawer.dart';
import 'package:business_sahaj_erp/core/widgets/mobile_bottom_sheets.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  static final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  const MainLayout({
    Key? key,
    required this.child,
  }) : super(key: key);

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/transactions')) return 1;
    if (location.startsWith('/parties')) return 2;
    if (location.startsWith('/reports') || location.startsWith('/settings')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final theme = Theme.of(context);
    final selectedIndex = _calculateSelectedIndex(context);

    if (isDesktop) {
      // Desktop Layout: Permanent side drawer + Appbar + Main content body
      return Scaffold(
        appBar: const CustomAppBar(),
        backgroundColor: theme.colorScheme.background,
        body: Row(
          children: [
            // Permanent side drawer on desktop
            const SizedBox(
              width: 280,
              child: CustomDrawer(isPermanent: true),
            ),
            // Divider
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: theme.colorScheme.surfaceVariant,
            ),
            // Main content body
            Expanded(
              child: child,
            ),
          ],
        ),
      );
    } else {
      // Mobile / Tablet Layout: Clean top space + Liquid Glass Bottom Bar + FAB + Side Drawer
      final isDark = theme.brightness == Brightness.dark;
      final location = GoRouterState.of(context).matchedLocation;
      final isDetailScreen = location.contains('/detail') ||
          location.contains('/add') ||
          location.contains('/edit') ||
          location.contains('/item/') ||
          location.contains('/party/');

      return Scaffold(
        key: _scaffoldKey,
        appBar: isDetailScreen ? null : const CustomAppBar(),
        drawer: const CustomDrawer(isPermanent: false),
        backgroundColor: theme.colorScheme.background,
        body: SafeArea(
          child: child,
        ),
        floatingActionButtonLocation: isDetailScreen ? null : FloatingActionButtonLocation.centerDocked,
        floatingActionButton: isDetailScreen
            ? null
            : Container(
                height: 58,
                width: 58,
                margin: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6366F1), Color(0xFF3B82F6)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.45),
                      blurRadius: 16,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: FloatingActionButton(
                  elevation: 0,
                  highlightElevation: 0,
                  shape: const CircleBorder(),
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  onPressed: () => MobileBottomSheets.showQuickCreate(context),
                  child: const Icon(Icons.add_rounded, size: 34),
                  tooltip: 'Quick Action',
                ),
              ),
        bottomNavigationBar: isDetailScreen
            ? null
            : Container(
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.40 : 0.10),
                blurRadius: 24,
                spreadRadius: 1,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: isDark
                      ? LinearGradient(
                          colors: [
                            const Color(0xFF1E293B).withOpacity(0.85),
                            const Color(0xFF0F172A).withOpacity(0.70),
                          ],
                        )
                      : LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.90),
                            Colors.white.withOpacity(0.75),
                          ],
                        ),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.14) : Colors.white.withOpacity(0.65),
                    width: 1.2,
                  ),
                ),
                child: BottomAppBar(
                  height: 64,
                  elevation: 0,
                  color: Colors.transparent,
                  shape: const CircularNotchedRectangle(),
                  notchMargin: 8,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(
                        context,
                        icon: Icons.dashboard_outlined,
                        activeIcon: Icons.dashboard_rounded,
                        label: 'Home',
                        isSelected: selectedIndex == 0,
                        onTap: () => context.go('/dashboard'),
                      ),
                      _buildNavItem(
                        context,
                        icon: Icons.receipt_long_outlined,
                        activeIcon: Icons.receipt_long_rounded,
                        label: 'Transactions',
                        isSelected: selectedIndex == 1,
                        onTap: () => context.go('/transactions'),
                      ),
                      const SizedBox(width: 48), // Space for central FAB notch
                      _buildNavItem(
                        context,
                        icon: Icons.people_outline_rounded,
                        activeIcon: Icons.people_rounded,
                        label: 'Parties',
                        isSelected: selectedIndex == 2,
                        onTap: () => context.go('/parties'),
                      ),
                      _buildNavItem(
                        context,
                        icon: Icons.grid_view_outlined,
                        activeIcon: Icons.grid_view_rounded,
                        label: 'More',
                        isSelected: selectedIndex == 3,
                        onTap: () {
                          _scaffoldKey.currentState?.openDrawer();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: isSelected
            ? BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? Colors.white : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
