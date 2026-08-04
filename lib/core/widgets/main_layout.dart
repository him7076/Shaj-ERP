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
    if (location.startsWith('/sales')) return 1;
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
      // Mobile / Tablet Layout: Modern Floating Bottom Bar + FAB + Slider Drawer
      return Scaffold(
        key: _scaffoldKey,
        appBar: const CustomAppBar(),
        drawer: const CustomDrawer(isPermanent: false),
        backgroundColor: theme.colorScheme.background,
        body: SafeArea(
          child: child,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: Container(
          height: 56,
          width: 56,
          margin: const EdgeInsets.only(top: 10),
          child: FloatingActionButton(
            elevation: 4,
            shape: const CircleBorder(),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            onPressed: () => MobileBottomSheets.showQuickCreate(context),
            child: const Icon(Icons.add_rounded, size: 32),
            tooltip: 'Quick Action',
          ),
        ),
        bottomNavigationBar: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.4),
              width: 1,
            ),
          ),
          child: BottomAppBar(
            height: 64,
            elevation: 0,
            color: Colors.transparent,
            shape: const CircularNotchedRectangle(),
            notchMargin: 8,
            padding: const EdgeInsets.symmetric(horizontal: 8),
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
                  label: 'Sales',
                  isSelected: selectedIndex == 1,
                  onTap: () => context.go('/sales'),
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
    final color = isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
