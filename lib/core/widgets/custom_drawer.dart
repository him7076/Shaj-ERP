import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomDrawer extends StatelessWidget {
  final bool isPermanent;

  const CustomDrawer({
    Key? key,
    required this.isPermanent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    final theme = Theme.of(context);

    return Drawer(
      elevation: isPermanent ? 0 : 6,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: Container(
        color: theme.colorScheme.surface,
        child: Column(
          children: [
            // Premium Header Visual with gradient background
            Container(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withOpacity(0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.business_center_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Sahaj ERP',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ENTERPRISE MANAGER',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Navigation List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 4),
                children: [
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                    routePath: '/dashboard',
                    currentPath: location,
                  ),
                  _buildDrawerHeader('ACCOUNTS'),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.monetization_on_rounded,
                    label: 'Sales (Invoices)',
                    routePath: '/sales',
                    currentPath: location,
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.shopping_bag_rounded,
                    label: 'Purchases (Bills)',
                    routePath: '/purchases',
                    currentPath: location,
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Expenses',
                    routePath: '/expenses',
                    currentPath: location,
                  ),
                  _buildDrawerHeader('MANAGEMENT'),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.people_alt_rounded,
                    label: 'Parties & Contacts',
                    routePath: '/parties',
                    currentPath: location,
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.inventory_2_rounded,
                    label: 'Items & Inventory',
                    routePath: '/items',
                    currentPath: location,
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.shopping_cart_rounded,
                    label: 'Sales Orders',
                    routePath: '/orders',
                    currentPath: location,
                  ),
                  _buildDrawerHeader('SYSTEM'),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.analytics_rounded,
                    label: 'Reports & Analytics',
                    routePath: '/reports',
                    currentPath: location,
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.cloud_sync_rounded,
                    label: 'Sync Center',
                    routePath: '/sync-center',
                    currentPath: location,
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.sd_storage_rounded,
                    label: 'Local Backup',
                    routePath: '/backup',
                    currentPath: location,
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.settings_rounded,
                    label: 'Settings',
                    routePath: '/settings',
                    currentPath: location,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 0.5),

            // Footer
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.offline_pin_rounded,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Offline Sync Core v1.0',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String routePath,
    required String currentPath,
  }) {
    final theme = Theme.of(context);
    final isActive = currentPath == routePath;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
          size: 22,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13.5,
            color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.9),
          ),
        ),
        selected: isActive,
        selectedTileColor: theme.colorScheme.primary.withOpacity(0.08),
        hoverColor: theme.colorScheme.primary.withOpacity(0.03),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        minLeadingWidth: 20,
        dense: true,
        onTap: () {
          if (!isPermanent) {
            Navigator.of(context).pop();
          }
          if (!isActive) {
            context.go(routePath);
          }
        },
      ),
    );
  }
}
